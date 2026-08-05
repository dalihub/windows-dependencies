[CmdletBinding()]
param(
  [ValidateSet("Debug", "Release")]
  [string]$Configuration = "Debug",
  [string]$VcpkgRoot = "C:\Tools\DALI_VCPKG\vcpkg",
  [string]$VcpkgRepository = "https://github.com/dalihub/vcpkg.git",
  [string]$Proxy = ""
)

$ErrorActionPreference = "Stop"
$ScriptRoot = $PSScriptRoot

. (Join-Path $ScriptRoot "dependency-network.ps1")
Set-DaliProxyEnvironment -Proxy $Proxy

$VcpkgArguments = @{
  Configuration = $Configuration
  VcpkgRoot = $VcpkgRoot
  VcpkgRepository = $VcpkgRepository
}
if($Proxy)
{
  $VcpkgArguments.Proxy = $Proxy
}

& (Join-Path $ScriptRoot "setup-vcpkg-vs2022.ps1") @VcpkgArguments

Write-Host "DALi third-party dependency setup completed."
