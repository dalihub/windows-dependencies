[CmdletBinding()]
param(
  [string]$DaliRoot = "C:\work\DALi",
  [string]$VcpkgRoot = "C:\Tools\DALI_VCPKG\vcpkg",
  [string]$VcpkgRepository = "https://github.com/dalihub/vcpkg.git",
  [string]$TizenVgRepository = "git://git.tizen.org/platform/core/graphics/tizenvg.git",
  [string]$TizenVgRevision = "ae039a6154a258a8fa19f23b25285acd73d2f6c1",
  [string]$Proxy = "",
  [switch]$SkipVcpkg,
  [switch]$SkipTizenVg
)

$ErrorActionPreference = "Stop"
$ScriptRoot = $PSScriptRoot
$InstallPrefix = Join-Path $DaliRoot "dali-env"

if(-not $SkipVcpkg)
{
  $VcpkgArguments = @{
    VcpkgRoot = $VcpkgRoot
    VcpkgRepository = $VcpkgRepository
  }
  if($Proxy)
  {
    $VcpkgArguments.Proxy = $Proxy
  }

  & (Join-Path $ScriptRoot "setup-vcpkg-vs2022.ps1") @VcpkgArguments
}

if(-not $SkipTizenVg)
{
  & (Join-Path $ScriptRoot "setup-tizenvg.ps1") `
    -InstallPrefix $InstallPrefix `
    -SourceRoot (Join-Path $DaliRoot "tizenvg") `
    -BuildRoot (Join-Path $DaliRoot "out\tizenvg") `
    -Repository $TizenVgRepository `
    -Revision $TizenVgRevision
}

Write-Host "DALi third-party dependency setup completed."
