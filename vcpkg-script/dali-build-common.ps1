$ErrorActionPreference = "Stop"

function New-DaliBuildContext
{
  param(
    [Parameter(Mandatory = $true)]
    [string]$WindowsDependenciesRoot,
    [string]$VcpkgRoot = "",
    [string]$InstallPrefix = ""
  )

  $WindowsDependenciesRoot = (Resolve-Path -LiteralPath $WindowsDependenciesRoot).Path
  $DaliRoot = Split-Path -Parent $WindowsDependenciesRoot

  if(-not $VcpkgRoot)
  {
    $VcpkgRoot = $env:DALI_VCPKG_ROOT
  }
  if(-not $VcpkgRoot)
  {
    $InstalledSdkVcpkg = Join-Path $DaliRoot "WindowsDependenciesSDK\vcpkg"
    if(Test-Path -LiteralPath (Join-Path $InstalledSdkVcpkg "scripts\buildsystems\vcpkg.cmake"))
    {
      $VcpkgRoot = $InstalledSdkVcpkg
    }
    else
    {
      $VcpkgRoot = Join-Path $DaliRoot ".deps\vcpkg"
    }
  }
  if(-not $InstallPrefix)
  {
    $InstallPrefix = Join-Path $DaliRoot "dali-env"
  }

  return [pscustomobject]@{
    DaliRoot = $DaliRoot
    WindowsDependenciesRoot = $WindowsDependenciesRoot
    VcpkgRoot = [IO.Path]::GetFullPath($VcpkgRoot)
    SdkRoot = Join-Path $DaliRoot "WindowsDependenciesSDK"
    InstallPrefix = [IO.Path]::GetFullPath($InstallPrefix)
    BuildRoot = Join-Path $DaliRoot "out"
  }
}

function Assert-DaliPaths
{
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Paths,
    [string]$Description = "Required path"
  )

  foreach($Path in $Paths)
  {
    if(-not (Test-Path -LiteralPath $Path))
    {
      throw "${Description} is missing: $Path"
    }
  }
}

function Import-DaliMsvcEnvironment
{
  $Compiler = Get-Command cl.exe -ErrorAction SilentlyContinue
  $CMake = Get-Command cmake.exe -ErrorAction SilentlyContinue
  $Ninja = Get-Command ninja.exe -ErrorAction SilentlyContinue
  if($Compiler -and $CMake -and $Ninja -and $env:VSCMD_ARG_TGT_ARCH -eq "x64")
  {
    return
  }

  $VsWhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
  if(-not (Test-Path -LiteralPath $VsWhere))
  {
    throw "vswhere.exe was not found. Install Visual Studio 2022 with Desktop development with C++."
  }

  $VsInstall = & $VsWhere -latest -products * `
    -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    -property installationPath | Select-Object -First 1
  if(-not $VsInstall)
  {
    throw "Visual Studio 2022 MSVC x64 build tools were not found."
  }

  $VsDevCmd = Join-Path $VsInstall "Common7\Tools\VsDevCmd.bat"
  cmd.exe /d /c "call `"$VsDevCmd`" -arch=x64 -host_arch=x64 >nul && set" |
    ForEach-Object {
      if($_ -match '^([^=]+)=(.*)$')
      {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
      }
    }
  if($LASTEXITCODE -ne 0)
  {
    throw "Failed to load the Visual Studio x64 developer environment."
  }

  Assert-DaliPaths -Paths @(
    (Get-Command cl.exe -ErrorAction Stop).Source,
    (Get-Command cmake.exe -ErrorAction Stop).Source,
    (Get-Command ninja.exe -ErrorAction Stop).Source
  ) -Description "Build tool"
}

function Initialize-DaliBuildEnvironment
{
  param(
    [Parameter(Mandatory = $true)]
    $Context
  )

  Assert-DaliPaths -Paths @(
    (Join-Path $Context.VcpkgRoot "scripts\buildsystems\vcpkg.cmake")
  ) -Description "vcpkg toolchain"

  Import-DaliMsvcEnvironment
  $env:VSLANG = "1033"

  New-Item -ItemType Directory -Force $Context.InstallPrefix | Out-Null

  $env:DESKTOP_PREFIX = $Context.InstallPrefix
  $env:DALI_DATA_RO_DIR = Join-Path $Context.InstallPrefix "share\dali"
  $env:DALI_DATA_RW_DIR = Join-Path $Context.InstallPrefix "share\dali"
  $env:DALI_DATA_RO_INSTALL_DIR = Join-Path $Context.InstallPrefix "share\dali"
  $env:FONTCONFIG_FILE = Join-Path $Context.InstallPrefix "share\dali\fonts.conf"
  $env:DALI_WINDOWS_SDK_ROOT = $Context.SdkRoot
  $env:DALI_PREFIX = $Context.InstallPrefix
  $env:PATH = "$(Join-Path $Context.InstallPrefix "bin");$(Join-Path $Context.InstallPrefix "lib");$(Join-Path $Context.SdkRoot "bin");$(Join-Path $Context.SdkRoot "lib");$(Join-Path $Context.VcpkgRoot "installed\x64-windows\bin");$env:PATH"
}

function Get-DaliCommonCMakeArguments
{
  param(
    [Parameter(Mandatory = $true)]
    $Context,
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release"
  )

  $Python = Join-Path $Context.VcpkgRoot "downloads\tools\python\python-3.7.3-amd64\python.exe"
  Assert-DaliPaths -Paths @($Python) -Description "vcpkg Python; run build_windows_dependencies.ps1 first"

  return @(
    "-G", "Ninja",
    "-DCMAKE_BUILD_TYPE=$Configuration",
    "-DCMAKE_TOOLCHAIN_FILE=$(Join-Path $Context.VcpkgRoot "scripts\buildsystems\vcpkg.cmake")",
    "-DVCPKG_TARGET_TRIPLET=x64-windows",
    "-DCMAKE_INSTALL_PREFIX=$($Context.InstallPrefix)",
    "-DCMAKE_PREFIX_PATH=$($Context.InstallPrefix);$($Context.SdkRoot);$(Join-Path $Context.VcpkgRoot "installed\x64-windows")",
    "-DPython3_EXECUTABLE=$Python"
  )
}

function Invoke-DaliNative
{
  param(
    [Parameter(Mandatory = $true)]
    [string]$Step,
    [Parameter(Mandatory = $true)]
    [string]$Command,
    [string[]]$Arguments = @()
  )

  Write-Host "`n=== $Step ===" -ForegroundColor Cyan
  & $Command @Arguments | Out-Host
  if($LASTEXITCODE -ne 0)
  {
    throw "$Step failed with exit code $LASTEXITCODE"
  }
}

function Invoke-DaliCMakeProject
{
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [Parameter(Mandatory = $true)]
    [string]$SourceDirectory,
    [Parameter(Mandatory = $true)]
    [string]$BuildDirectory,
    [Parameter(Mandatory = $true)]
    [string[]]$ConfigureArguments,
    [switch]$Clean,
    [int]$Jobs = 8
  )

  if($Jobs -lt 1)
  {
    throw "Jobs must be at least 1."
  }

  Assert-DaliPaths -Paths @($SourceDirectory) -Description "$Name source directory"

  if($Clean -and (Test-Path -LiteralPath $BuildDirectory))
  {
    $ResolvedSource = [IO.Path]::GetFullPath($SourceDirectory)
    $ResolvedBuild = [IO.Path]::GetFullPath($BuildDirectory)
    if($ResolvedBuild -eq $ResolvedSource -or $ResolvedBuild.Length -lt 10)
    {
      throw "Refusing to clean unsafe build directory: $ResolvedBuild"
    }
    Remove-Item -LiteralPath $ResolvedBuild -Recurse -Force
  }

  Invoke-DaliNative -Step "Configure $Name" -Command "cmake.exe" `
    -Arguments (@("-S", $SourceDirectory, "-B", $BuildDirectory) + $ConfigureArguments)
  Invoke-DaliNative -Step "Build/install $Name" -Command "cmake.exe" `
    -Arguments @("--build", $BuildDirectory, "--target", "install", "--parallel", "$Jobs")
}

function Install-DaliRuntimeScripts
{
  param(
    [Parameter(Mandatory = $true)]
    $Context
  )

  $RuntimeScript = Join-Path $Context.WindowsDependenciesRoot "resources\set-dali-runtime-env.ps1"
  Assert-DaliPaths -Paths @($RuntimeScript) -Description "DALi runtime environment script"
  New-Item -ItemType Directory -Force -Path $Context.InstallPrefix | Out-Null
  Copy-Item -LiteralPath $RuntimeScript -Destination (Join-Path $Context.InstallPrefix "setenv.ps1") -Force
}
