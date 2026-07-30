[CmdletBinding()]
param(
  [string]$Proxy = "",
  [string]$VcpkgRoot = "",
  [ValidateSet("Debug", "Release")]
  [string]$Configuration = "Release",
  [string]$StarfishRepository = "",
  [string]$StarfishRevision = "",
  [switch]$SkipStarfish,
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
  $SourceVcpkgRoot = Join-Path $ScriptRoot ".deps\vcpkg"
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
    Configuration = $Configuration
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

# LWE (Starfish) web engine SDK. Optional: a failure only warns, WebView is
# simply unavailable and setup-starfish.ps1 can be re-run standalone.
if(-not $SkipStarfish)
{
  $StarfishArguments = @{
    InstallPrefix = $Context.InstallPrefix
    Jobs = $Jobs
  }
  if($StarfishRepository)
  {
    $StarfishArguments.Repository = $StarfishRepository
  }
  if($StarfishRevision)
  {
    $StarfishArguments.Revision = $StarfishRevision
  }
  try
  {
    & (Join-Path $ScriptRoot "vcpkg-script/setup-starfish.ps1") @StarfishArguments
  }
  catch
  {
    Write-Warning "LWE (Starfish) SDK setup failed: $($_.Exception.Message)"
    Write-Warning "WebView will be unavailable; re-run vcpkg-script/setup-starfish.ps1 after fixing."
  }
}

$Common = Get-DaliCommonCMakeArguments -Context $Context -Configuration $Configuration

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
