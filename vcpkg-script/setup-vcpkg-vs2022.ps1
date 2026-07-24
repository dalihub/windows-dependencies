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

. (Join-Path $ScriptRoot "dependency-network.ps1")

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
    $Result = Invoke-DaliGit -Arguments @("-C", $VcpkgRoot, "apply", "--reverse", "--check", "--ignore-whitespace", $PatchPath) -AllowFailure
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
    "[VCPKG]_0003_Use_system_curl_on_windows.patch" {
      return (Test-VcpkgFileContains "scripts\cmake\vcpkg_download_distfile.cmake" "--ssl-no-revoke")
    }
    "[VCPKG]_0002_VS2022_and_modern_downloads.patch" {
      return ((Test-VcpkgFileContains "scripts\bootstrap.ps1" "v143") -and
              (Test-VcpkgFileContains "scripts\cmake\vcpkg_configure_meson.cmake" 'VCPKG_TARGET_ARCHITECTURE STREQUAL "x64"') -and
              (Test-VcpkgFileContains "toolsrc\src\vcpkg\visualstudio.cpp" "V_143") -and
              (Test-VcpkgFileContains "ports\giflib\portfile.cmake" 'giflib-${GIFLIB_VERSION}.tar.gz'))
    }
    "[VCPKG]_0004_Fix_x64_meson_cross_file.patch" {
      return (Test-VcpkgFileContains "scripts\cmake\vcpkg_configure_meson.cmake" "vcpkg-x64-cross.ini")
    }
    "[VCPKG]_0005_Use_x64_python_tool.patch" {
      return (Test-VcpkgFileContains "scripts\cmake\vcpkg_find_acquire_program.cmake" "python-3.7.3-embed-amd64.zip")
    }
    "[VCPKG]_0006_Use_x64_meson_native_build.patch" {
      return ((Test-VcpkgFileContains "scripts\cmake\vcpkg_configure_meson.cmake" "--native-file `${_VCPKG_MESON_CROSS_FILE}") -and (Test-VcpkgFileContains "scripts\cmake\vcpkg_configure_meson.cmake" "/MACHINE:X64"))
    }
  }

  return $false
}
function Apply-MissingPatch
{
  param([string]$PatchName)

  if($PatchName -eq "[VCPKG]_0006_Use_x64_meson_native_build.patch")
  {
    $MesonHelperPath = Join-Path $VcpkgRoot "scripts\cmake\vcpkg_configure_meson.cmake"
    $MesonContent = [IO.File]::ReadAllText($MesonHelperPath, [Text.UTF8Encoding]::new($false))
    $CrossLine = '        list(APPEND _vcm_OPTIONS --cross-file ${_VCPKG_MESON_CROSS_FILE})'
    $NativeLine = '        list(APPEND _vcm_OPTIONS --native-file ${_VCPKG_MESON_CROSS_FILE})'
    $MachineLine = '        set(MESON_COMMON_LDFLAGS "${MESON_COMMON_LDFLAGS} /MACHINE:X64")'

    if($MesonContent.Contains($NativeLine) -and $MesonContent.Contains($MachineLine))
    {
      Write-Host "Patch markers already present: $PatchName"
      return
    }
    if($MesonContent.Contains($CrossLine))
    {
      $MesonContent = $MesonContent.Replace($CrossLine, $NativeLine)
    }
    if(-not $MesonContent.Contains($NativeLine))
    {
      throw "Unable to find the patched Meson machine-file option in $MesonHelperPath"
    }
    if(-not $MesonContent.Contains($MachineLine))
    {
      $NewLine = if($MesonContent.Contains("`r`n")) { "`r`n" } else { "`n" }
      $MesonContent = $MesonContent.Replace($NativeLine, "$NativeLine$NewLine$MachineLine")
    }

    [IO.File]::WriteAllText($MesonHelperPath, $MesonContent, [Text.UTF8Encoding]::new($false))
    Write-Host "Patch applied: $PatchName"
    return
  }

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

  Invoke-DaliGit -Arguments @("-C", $VcpkgRoot, "apply", "--check", "--ignore-whitespace", $PatchPath) | Out-Null
  Invoke-DaliGit -Arguments @("-C", $VcpkgRoot, "apply", "--ignore-whitespace", "--whitespace=nowarn", $PatchPath) | Out-Null
  Write-Host "Patch applied: $PatchName"
  $script:VcpkgNeedsBootstrap = $true
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

  for($Attempt = 1; $Attempt -le $DaliNetworkRetryCount; ++$Attempt)
  {
    & "$VcpkgRoot\vcpkg.exe" install @PackageList
    if($LASTEXITCODE -eq 0)
    {
      return
    }
    if($Attempt -lt $DaliNetworkRetryCount)
    {
      Write-Warning "vcpkg install failed (attempt $Attempt/$DaliNetworkRetryCount); retrying so cached downloads and completed packages are reused."
      Start-Sleep -Seconds 1
    }
  }
  throw "vcpkg package installation failed after $DaliNetworkRetryCount attempts. If this happened on the corporate network with an SSL connect error, rerun with -Proxy host:port or use a corporate mirror."
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
  "[VCPKG]_0002_VS2022_and_modern_downloads.patch",
  "[VCPKG]_0003_Use_system_curl_on_windows.patch",
  "[VCPKG]_0004_Fix_x64_meson_cross_file.patch",
  "[VCPKG]_0005_Use_x64_python_tool.patch",
  "[VCPKG]_0006_Use_x64_meson_native_build.patch"
)

Set-DaliProxyEnvironment -Proxy $Proxy

if(Test-Path -LiteralPath $VcpkgRoot)
{
  if($Fresh)
  {
    throw "VcpkgRoot already exists. Remove it manually or choose a new path: $VcpkgRoot"
  }
  if(-not (Test-Path -LiteralPath (Join-Path $VcpkgRoot ".git")))
  {
    throw "VcpkgRoot exists but is not a Git checkout: $VcpkgRoot"
  }
  $CurrentCommit = (Invoke-DaliGit -Arguments @("-C", $VcpkgRoot, "rev-parse", "--short", "HEAD")).StdOut.Trim()
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
  Invoke-DaliGitNetwork -Arguments @("clone", "--progress", $VcpkgRepository, $VcpkgRoot) -CleanupPathOnRetry $VcpkgRoot | Out-Null
  Invoke-DaliGit -Arguments @("-C", $VcpkgRoot, "checkout", $VcpkgCommit) | Out-Null
}

$script:VcpkgNeedsBootstrap = -not (Test-Path -LiteralPath (Join-Path $VcpkgRoot "vcpkg.exe"))

foreach($PatchName in $Patches)
{
  Apply-MissingPatch $PatchName
}

if($script:VcpkgNeedsBootstrap)
{
  cmd.exe /d /c "`"$VcpkgRoot\bootstrap-vcpkg.bat`" -disableMetrics"
  if($LASTEXITCODE -ne 0) { throw "vcpkg bootstrap failed" }
}
else
{
  Write-Host "Reusing existing vcpkg executable: $VcpkgRoot\vcpkg.exe"
}

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
