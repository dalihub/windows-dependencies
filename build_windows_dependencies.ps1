[CmdletBinding()]
param(
  [string]$Proxy = "",
  [string]$VcpkgRoot = "",
  [switch]$SkipTizenVg,
  [switch]$SkipThirdParty,
  [switch]$Clean,
  [int]$Jobs = 8
)

$ErrorActionPreference = "Stop"
$ScriptRoot = $PSScriptRoot
. (Join-Path $ScriptRoot "vcpkg-script\dali-build-common.ps1")

$WorkspaceContext = New-DaliBuildContext -WindowsDependenciesRoot $ScriptRoot -VcpkgRoot $VcpkgRoot
$SourceVcpkgRoot = $WorkspaceContext.VcpkgRoot
if($SourceVcpkgRoot -eq (Join-Path $WorkspaceContext.SdkRoot "vcpkg"))
{
  $SourceVcpkgRoot = Join-Path $WorkspaceContext.DaliRoot ".deps\vcpkg"
}

if(-not $SkipThirdParty)
{
  $DependencyArguments = @{
    DaliRoot = $WorkspaceContext.DaliRoot
    VcpkgRoot = $SourceVcpkgRoot
    InstallPrefix = $WorkspaceContext.SdkRoot
    SkipTizenVg = $true
  }
  if($Proxy)
  {
    $DependencyArguments.Proxy = $Proxy
  }
  & (Join-Path $ScriptRoot "vcpkg-script\setup-dali-dependencies.ps1") @DependencyArguments
}

$StageArguments = @{
  VcpkgRoot = $SourceVcpkgRoot
  SdkRoot = $WorkspaceContext.SdkRoot
  Clean = $Clean
}
& (Join-Path $ScriptRoot "vcpkg-script\stage-windows-sdk.ps1") @StageArguments

if(-not $SkipThirdParty -and -not $SkipTizenVg)
{
  $TizenVgArguments = @{
    DaliRoot = $WorkspaceContext.DaliRoot
    VcpkgRoot = (Join-Path $WorkspaceContext.SdkRoot "vcpkg")
    InstallPrefix = $WorkspaceContext.SdkRoot
    SkipVcpkg = $true
  }
  if($Proxy)
  {
    $TizenVgArguments.Proxy = $Proxy
  }
  & (Join-Path $ScriptRoot "vcpkg-script\setup-dali-dependencies.ps1") @TizenVgArguments
}

$Context = New-DaliBuildContext `
  -WindowsDependenciesRoot $ScriptRoot `
  -VcpkgRoot (Join-Path $WorkspaceContext.SdkRoot "vcpkg") `
  -InstallPrefix $WorkspaceContext.SdkRoot
Initialize-DaliBuildEnvironment -Context $Context
$Common = Get-DaliCommonCMakeArguments -Context $Context

Invoke-DaliCMakeProject `
  -Name "windows-dependencies" `
  -SourceDirectory (Join-Path $ScriptRoot "build") `
  -BuildDirectory (Join-Path $ScriptRoot "_build\windows") `
  -ConfigureArguments $Common `
  -Clean:$Clean `
  -Jobs $Jobs

Assert-DaliPaths -Paths @(
  (Join-Path $Context.InstallPrefix "share\dali-windows-dependencies\dali-windows-dependencies-config.cmake"),
  (Join-Path $Context.InstallPrefix "share\dali\fonts.conf"),
  (Join-Path $Context.VcpkgRoot "installed\x64-windows\include")
) -Description "windows-dependencies installation output"

Install-DaliRuntimeScripts -Context (New-DaliBuildContext -WindowsDependenciesRoot $ScriptRoot)
Write-Host "`nWindowsDependenciesSDK setup completed in $($Context.SdkRoot)." -ForegroundColor Green
