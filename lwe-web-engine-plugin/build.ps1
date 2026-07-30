[CmdletBinding()]
param(
  [ValidateSet("Debug", "Release")]
  [string]$Configuration = "Release",
  [string]$VcpkgRoot = "",
  [switch]$Clean,
  [int]$Jobs = 8
)

# Builds the DALi LWE web-engine plugin (dali2-web-engine-lwe-plugin.dll) and
# installs it into dali-env\bin next to dali2-adaptor.dll.
#
# Prerequisites (in order):
#   1. windows-dependencies\install.ps1        (WindowsDependenciesSDK + Starfish/LWE)
#   2. dali-core\build\windows\build.ps1
#   3. dali-adaptor\build\windows\build.ps1
# Then run this script. dali-ui does not need to be built first.

$ErrorActionPreference = "Stop"

# LWE's public API passes std::string across the DLL boundary, so the plugin,
# DALi and Starfish must share one configuration. The Starfish SDK is
# currently built Release-only; a Debug plugin would crash at runtime.
if($Configuration -eq "Debug")
{
  throw "The LWE plugin currently supports Release only (the Starfish SDK is a Release build)."
}

$PluginRoot = $PSScriptRoot
$WindowsDependenciesRoot = Split-Path -Parent $PluginRoot
$CommonScript = Join-Path $WindowsDependenciesRoot "vcpkg-script\dali-build-common.ps1"
if(-not (Test-Path -LiteralPath $CommonScript))
{
  throw "dali-build-common.ps1 not found: $CommonScript"
}
. $CommonScript

$Context = New-DaliBuildContext -WindowsDependenciesRoot $WindowsDependenciesRoot -VcpkgRoot $VcpkgRoot
Initialize-DaliBuildEnvironment -Context $Context

$CorePackage = Join-Path $Context.InstallPrefix "share\dali2-core"
$AdaptorPackage = Join-Path $Context.InstallPrefix "share\dali2-adaptor"
Assert-DaliPaths -Paths @(
  (Join-Path $CorePackage "dali2-core-config.cmake"),
  (Join-Path $AdaptorPackage "dali2-adaptor-config.cmake")
) -Description "DALi package; build dali-core and dali-adaptor first"

Assert-DaliPaths -Paths @(
  (Join-Path $Context.SdkRoot "include\LWEWebView.h"),
  (Join-Path $Context.SdkRoot "lib\Starfish.lib")
) -Description "LWE (Starfish) SDK; install it into WindowsDependenciesSDK first"

$Arguments = (Get-DaliCommonCMakeArguments -Context $Context -Configuration $Configuration) + @(
  "-Ddali2-core_DIR=$CorePackage",
  "-Ddali2-adaptor_DIR=$AdaptorPackage"
)

Invoke-DaliCMakeProject `
  -Name "lwe-web-engine-plugin" `
  -SourceDirectory $PluginRoot `
  -BuildDirectory (Join-Path $PluginRoot "_build\windows") `
  -ConfigureArguments $Arguments `
  -Clean:$Clean `
  -Jobs $Jobs

Write-Host "`ndali2-web-engine-lwe-plugin.dll installed in $($Context.InstallPrefix)\bin." -ForegroundColor Green
