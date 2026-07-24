[CmdletBinding()]
param(
  [string]$Proxy = "",
  [string]$VcpkgRoot = "",
  [switch]$SkipTizenVg,
  [switch]$SkipThirdParty,
  [int]$Jobs = 8
)

$ErrorActionPreference = "Stop"
$ScriptRoot = $PSScriptRoot
. (Join-Path $ScriptRoot "vcpkg-script\dali-build-common.ps1")

$Context = New-DaliBuildContext -WindowsDependenciesRoot $ScriptRoot -VcpkgRoot $VcpkgRoot

if(-not $SkipThirdParty)
{
  $DependencyArguments = @{
    DaliRoot = $Context.DaliRoot
    VcpkgRoot = $Context.VcpkgRoot
  }
  if($Proxy)
  {
    $DependencyArguments.Proxy = $Proxy
  }
  if($SkipTizenVg)
  {
    $DependencyArguments.SkipTizenVg = $true
  }

  & (Join-Path $ScriptRoot "vcpkg-script\setup-dali-dependencies.ps1") @DependencyArguments
}

Initialize-DaliBuildEnvironment -Context $Context
$Common = Get-DaliCommonCMakeArguments -Context $Context

Invoke-DaliCMakeProject `
  -Name "windows-dependencies" `
  -SourceDirectory (Join-Path $ScriptRoot "build") `
  -BuildDirectory (Join-Path $Context.BuildRoot "windows-dependencies") `
  -ConfigureArguments $Common `
  -Jobs $Jobs

Assert-DaliPaths -Paths @(
  (Join-Path $Context.InstallPrefix "share\dali-windows-dependencies\dali-windows-dependencies-config.cmake"),
  (Join-Path $Context.InstallPrefix "share\dali\fonts.conf"),
  (Join-Path $Context.InstallPrefix "set-dali-runtime-env.ps1")
) -Description "windows-dependencies installation output"

Write-Host "`nwindows-dependencies and third-party setup completed." -ForegroundColor Green
