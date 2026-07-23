[CmdletBinding()]
param(
  [string]$VcpkgRoot = "C:\Tools\DALI_VCPKG\vcpkg",
  [string]$VcpkgRepository = "https://github.com/dalihub/vcpkg.git",
  [string]$Proxy = "",
  [switch]$SkipInstall
)

$ErrorActionPreference = "Stop"
$VcpkgCommit = "a58936506"
$ScriptRoot = $PSScriptRoot

$CmakeVersionLine = (& cmake --version | Select-Object -First 1)
if($LASTEXITCODE -ne 0 -or $CmakeVersionLine -notmatch '(\d+\.\d+\.\d+)')
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
  throw "VcpkgRoot already exists. To protect existing work, choose a new path or inspect it manually: $VcpkgRoot"
}

$VcpkgParent = Split-Path -Parent $VcpkgRoot
New-Item -ItemType Directory -Force -Path $VcpkgParent | Out-Null

git clone $VcpkgRepository $VcpkgRoot
if($LASTEXITCODE -ne 0) { throw "git clone failed" }

git -C $VcpkgRoot checkout $VcpkgCommit
if($LASTEXITCODE -ne 0) { throw "git checkout $VcpkgCommit failed" }

foreach($PatchName in $Patches)
{
  $PatchPath = Join-Path $ScriptRoot $PatchName
  git -C $VcpkgRoot apply --check --ignore-whitespace $PatchPath
  if($LASTEXITCODE -ne 0) { throw "Patch check failed: $PatchName" }

  git -C $VcpkgRoot apply --ignore-whitespace --whitespace=nowarn $PatchPath
  if($LASTEXITCODE -ne 0) { throw "Patch apply failed: $PatchName" }
}

cmd.exe /d /c "`"$VcpkgRoot\bootstrap-vcpkg.bat`" -disableMetrics"
if($LASTEXITCODE -ne 0) { throw "vcpkg bootstrap failed" }

if(-not $SkipInstall)
{
  & "$VcpkgRoot\vcpkg.exe" install @Packages
  if($LASTEXITCODE -ne 0) { throw "vcpkg package installation failed" }
}

Write-Host "vcpkg setup completed: $VcpkgRoot"
