[CmdletBinding()]
param(
  [string]$VcpkgRoot = "C:\Tools\DALI_VCPKG\vcpkg",
  [string]$VcpkgRepository = "https://github.com/dalihub/vcpkg.git",
  [string]$Proxy = "",
  [switch]$Fresh,
  [switch]$SkipInstall
)

$ErrorActionPreference = "Stop"
$VcpkgCommit = "a58936506"
$ScriptRoot = $PSScriptRoot

function ConvertTo-CommandLineArgument
{
  param([string]$Argument)

  if($Argument -notmatch '[\s"]')
  {
    return $Argument
  }

  return '"' + ($Argument -replace '\\', '\\' -replace '"', '\"') + '"'
}

function Invoke-GitTimed
{
  param(
    [string[]]$Arguments,
    [switch]$AllowFailure,
    [int]$TimeoutSeconds = 10
  )

  $StartInfo = [Diagnostics.ProcessStartInfo]::new()
  $StartInfo.FileName = "git"
  $StartInfo.Arguments = (($Arguments | ForEach-Object { ConvertTo-CommandLineArgument $_ }) -join " ")
  $StartInfo.UseShellExecute = $false
  $StartInfo.RedirectStandardOutput = $true
  $StartInfo.RedirectStandardError = $true
  $Process = [Diagnostics.Process]::Start($StartInfo)

  if(-not $Process.WaitForExit($TimeoutSeconds * 1000))
  {
    try { $Process.Kill() } catch { }
    throw "git $($StartInfo.Arguments) timed out after $TimeoutSeconds seconds"
  }

  $StdOut = $Process.StandardOutput.ReadToEnd()
  $StdErr = $Process.StandardError.ReadToEnd()
  if($Process.ExitCode -ne 0 -and -not $AllowFailure)
  {
    if($StdErr) { Write-Error $StdErr }
    throw "git $($StartInfo.Arguments) failed with exit code $($Process.ExitCode)"
  }

  return [pscustomobject]@{
    ExitCode = $Process.ExitCode
    StdOut = $StdOut
    StdErr = $StdErr
  }
}
function Invoke-Native
{
  param(
    [string]$Command,
    [string[]]$Arguments
  )

  & $Command @Arguments
  if($LASTEXITCODE -ne 0)
  {
    throw "$Command failed with exit code $LASTEXITCODE"
  }
}

function Test-RequiredFile
{
  param([string]$Path)
  if(-not (Test-Path -LiteralPath $Path))
  {
    throw "Required file was not installed: $Path"
  }
}

function Test-PatchApplied
{
  param([string]$PatchPath)

  $PreviousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try
  {
    $Result = Invoke-GitTimed @("-C", $VcpkgRoot, "apply", "--reverse", "--check", "--ignore-whitespace", $PatchPath) -AllowFailure
    return ($Result.ExitCode -eq 0)
  }
  finally
  {
    $ErrorActionPreference = $PreviousErrorActionPreference
  }
}

function Test-VcpkgFileContains
{
  param(
    [string]$RelativePath,
    [string]$Pattern
  )

  $FullPath = Join-Path $VcpkgRoot $RelativePath
  if(-not (Test-Path -LiteralPath $FullPath))
  {
    return $false
  }

  $Content = [IO.File]::ReadAllText($FullPath, [Text.UTF8Encoding]::new($false))
  return ($Content -match [regex]::Escape($Pattern))
}

function Test-PatchMarkerApplied
{
  param([string]$PatchName)

  switch -Exact ($PatchName)
  {
    "[VCPKG]_0001_Fix_proxy_access.patch" {
      return (Test-VcpkgFileContains "toolsrc\src\vcpkg\base\downloads.cpp" "VCPKG_PROXY")
    }
    "[VCPKG-angle]_0001_Apply_Fix_glInvalidateFramebuffer_crash.patch" {
      return ((Test-VcpkgFileContains "ports\angle\portfile.cmake" "002_Fix_glInvalidateFramebuffer_crash.patch") -and
              (Test-Path -LiteralPath (Join-Path $VcpkgRoot "ports\angle\002_Fix_glInvalidateFramebuffer_crash.patch")))
    }
    "[VCPKG-getopt]_0001_Apply_Fix_extern_c.patch" {
      return ((Test-VcpkgFileContains "ports\getopt-win32\portfile.cmake" "0001_fix_get_opt_extern_c.patch") -and
              (Test-Path -LiteralPath (Join-Path $VcpkgRoot "ports\getopt-win32\0001_fix_get_opt_extern_c.patch")))
    }
    "[VCPKG-libjpeg-turbo]_0001_Apply_Fix_fill_jpeg_buffer_cb.patch" {
      return ((Test-VcpkgFileContains "ports\libjpeg-turbo\portfile.cmake" "0001_fill_jpeg_buffer_cb.patch") -and
              (Test-Path -LiteralPath (Join-Path $VcpkgRoot "ports\libjpeg-turbo\0001_fill_jpeg_buffer_cb.patch")))
    }
    "[VCPKG-pthreads]_0001_Apply_Fix_define_timespec.patch" {
      return ((Test-VcpkgFileContains "ports\pthreads\portfile.cmake" "0001_fix_define_timespec.patch") -and
              (Test-Path -LiteralPath (Join-Path $VcpkgRoot "ports\pthreads\0001_fix_define_timespec.patch")))
    }
    "[VCPKG-gettext]_0001_Install_msgfmt_tool.patch" {
      return (Test-VcpkgFileContains "ports\gettext\portfile.cmake" "MSGFMT_ARCHIVE")
    }
    "[VCPKG]_0002_VS2022_and_modern_downloads.patch" {
      return ((Test-VcpkgFileContains "scripts\bootstrap.ps1" "v143") -and
              (Test-VcpkgFileContains "scripts\cmake\vcpkg_configure_meson.cmake" "vcpkg-x64-native.ini") -and
              (Test-VcpkgFileContains "toolsrc\src\vcpkg\visualstudio.cpp" "V_143") -and
              (Test-VcpkgFileContains "ports\giflib\portfile.cmake" 'giflib-${GIFLIB_VERSION}.tar.gz'))
    }
  }

  return $false
}
function Apply-MissingPatch
{
  param([string]$PatchName)

  $PatchPath = Join-Path $ScriptRoot $PatchName
  if(Test-PatchApplied $PatchPath)
  {
    Write-Host "Patch already applied: $PatchName"
    return
  }
  if(Test-PatchMarkerApplied $PatchName)
  {
    Write-Host "Patch markers already present: $PatchName"
    return
  }

  Invoke-GitTimed @("-C", $VcpkgRoot, "apply", "--check", "--ignore-whitespace", $PatchPath) | Out-Null
  Invoke-GitTimed @("-C", $VcpkgRoot, "apply", "--ignore-whitespace", "--whitespace=nowarn", $PatchPath) | Out-Null
  Write-Host "Patch applied: $PatchName"
}

function Get-RequiredVcpkgFiles
{
  return @(
    (Join-Path $VcpkgRoot "installed\x64-windows\include\libintl.h"),
    (Join-Path $VcpkgRoot "installed\x64-windows\lib\libintl.lib"),
    (Join-Path $VcpkgRoot "installed\x64-windows\bin\libintl.dll"),
    (Join-Path $VcpkgRoot "installed\x64-windows\tools\gettext\msgfmt.exe")
  )
}

function Test-RequiredVcpkgFiles
{
  $Missing = @(Get-RequiredVcpkgFiles | Where-Object { -not (Test-Path -LiteralPath $_) })
  if($Missing.Count -gt 0)
  {
    return $false
  }
  return $true
}

function Assert-RequiredVcpkgFiles
{
  foreach($RequiredPath in (Get-RequiredVcpkgFiles))
  {
    Test-RequiredFile $RequiredPath
  }
}

function Invoke-VcpkgInstall
{
  param([string[]]$PackageList)

  & "$VcpkgRoot\vcpkg.exe" install @PackageList
  if($LASTEXITCODE -ne 0)
  {
    throw "vcpkg package installation failed. If this happened on the corporate network with an SSL connect error, rerun with -Proxy host:port or use a corporate mirror."
  }
}

function Repair-GettextToolsIfNeeded
{
  if(Test-RequiredVcpkgFiles)
  {
    return
  }

  Write-Warning "gettext/libintl/msgfmt outputs are incomplete. Reinstalling gettext-dependent vcpkg packages."
  & "$VcpkgRoot\vcpkg.exe" remove "gettext:x64-windows" --recurse
  if($LASTEXITCODE -ne 0)
  {
    Write-Warning "gettext removal failed or gettext was not installed. Continuing with install."
  }

  Invoke-VcpkgInstall @("gettext:x64-windows", "cairo:x64-windows")
}
function Resolve-CMakeCommand
{
  $Existing = Get-Command cmake.exe -ErrorAction SilentlyContinue
  if($Existing)
  {
    return $Existing.Source
  }

  $CandidatePaths = @()
  $VsWhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
  if(Test-Path -LiteralPath $VsWhere)
  {
    $VisualStudioRoot = & $VsWhere -latest -products * `
      -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
      -property installationPath
    if($LASTEXITCODE -eq 0 -and $VisualStudioRoot)
    {
      $CandidatePaths += (Join-Path $VisualStudioRoot "Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe")
    }
  }

  $CandidatePaths += @(
    "C:\Program Files\CMake\bin\cmake.exe",
    "C:\Program Files (x86)\CMake\bin\cmake.exe"
  )

  foreach($CandidatePath in $CandidatePaths)
  {
    if(Test-Path -LiteralPath $CandidatePath)
    {
      $env:PATH = "$(Split-Path -Parent $CandidatePath);$env:PATH"
      return $CandidatePath
    }
  }

  throw "CMake was not found. Install CMake 3.15 or newer, or install the Visual Studio CMake component."
}

$CmakeCommand = Resolve-CMakeCommand
$CmakeVersionLine = (& $CmakeCommand --version | Select-Object -First 1)
if($CmakeVersionLine -notmatch '(\d+\.\d+\.\d+)')
{
  throw "CMake was not found or its version could not be determined"
}
if([version]$Matches[1] -lt [version]"3.15.0")
{
  throw "CMake 3.15 or newer is required to extract the msgfmt package"
}

$Packages = @(
  "winsock2:x64-windows",
  "pthreads:x64-windows",
  "curl:x64-windows",
  "getopt-win32:x64-windows",
  "libexif:x64-windows",
  "libjpeg-turbo:x64-windows",
  "libpng:x64-windows",
  "giflib:x64-windows",
  "angle:x64-windows",
  "cairo:x64-windows",
  "fontconfig:x64-windows",
  "freetype:x64-windows",
  "harfbuzz:x64-windows",
  "fribidi:x64-windows",
  "libwebp:x64-windows",
  "gettext:x64-windows"
)

$Patches = @(
  "[VCPKG]_0001_Fix_proxy_access.patch",
  "[VCPKG-angle]_0001_Apply_Fix_glInvalidateFramebuffer_crash.patch",
  "[VCPKG-getopt]_0001_Apply_Fix_extern_c.patch",
  "[VCPKG-libjpeg-turbo]_0001_Apply_Fix_fill_jpeg_buffer_cb.patch",
  "[VCPKG-pthreads]_0001_Apply_Fix_define_timespec.patch",
  "[VCPKG-gettext]_0001_Install_msgfmt_tool.patch",
  "[VCPKG]_0002_VS2022_and_modern_downloads.patch"
)

if($Proxy)
{
  $ProxyAddress = $Proxy -replace '^https?://', ''
  $env:VCPKG_PROXY = $ProxyAddress
  $env:HTTP_PROXY = "http://$ProxyAddress"
  $env:HTTPS_PROXY = "http://$ProxyAddress"
}

if(Test-Path -LiteralPath $VcpkgRoot)
{
  if($Fresh)
  {
    throw "VcpkgRoot already exists. Remove it manually or choose a new path: $VcpkgRoot"
  }
  if(-not (Test-Path -LiteralPath (Join-Path $VcpkgRoot ".git")))
  {
    throw "VcpkgRoot exists but is not a Git checkout: $VcpkgRoot"
  }  $CurrentCommit = (Invoke-GitTimed @("-C", $VcpkgRoot, "rev-parse", "--short", "HEAD")).StdOut.Trim()
  if($CurrentCommit -ne $VcpkgCommit)
  {
    throw "Unexpected vcpkg revision $CurrentCommit. Expected $VcpkgCommit. Use a fresh VcpkgRoot."
  }

  Write-Host "Reusing existing pinned vcpkg checkout: $VcpkgRoot"
}
else
{
  $VcpkgParent = Split-Path -Parent $VcpkgRoot
  New-Item -ItemType Directory -Force -Path $VcpkgParent | Out-Null
  Invoke-GitTimed @("clone", $VcpkgRepository, $VcpkgRoot) | Out-Null
  Invoke-GitTimed @("-C", $VcpkgRoot, "checkout", $VcpkgCommit) | Out-Null
}

foreach($PatchName in $Patches)
{
  Apply-MissingPatch $PatchName
}

cmd.exe /d /c "`"$VcpkgRoot\bootstrap-vcpkg.bat`" -disableMetrics"
if($LASTEXITCODE -ne 0) { throw "vcpkg bootstrap failed" }

if(-not $SkipInstall)
{
  Invoke-VcpkgInstall $Packages
  Repair-GettextToolsIfNeeded
  Assert-RequiredVcpkgFiles

  $Msgfmt = Join-Path $VcpkgRoot "installed\x64-windows\tools\gettext\msgfmt.exe"
  & $Msgfmt --version | Select-Object -First 1
  if($LASTEXITCODE -ne 0) { throw "msgfmt validation failed" }
}

Write-Host "vcpkg setup completed: $VcpkgRoot"
