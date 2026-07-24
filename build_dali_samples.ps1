[CmdletBinding()]
param(
  [string[]]$Samples = @("hello-world"),
  [string[]]$ImageViewTargets = @(),
  [string]$VcpkgRoot = "",
  [int]$Jobs = 8
)

$ErrorActionPreference = "Stop"
$ScriptRoot = $PSScriptRoot
. (Join-Path $ScriptRoot "vcpkg-script\dali-build-common.ps1")

if($Samples.Count -eq 0)
{
  throw "Specify at least one sample directory."
}

$Context = New-DaliBuildContext -WindowsDependenciesRoot $ScriptRoot -VcpkgRoot $VcpkgRoot
Initialize-DaliBuildEnvironment -Context $Context

$CorePackage = Join-Path $Context.InstallPrefix "share\dali2-core"
$AdaptorPackage = Join-Path $Context.InstallPrefix "share\dali2-adaptor"
$FoundationPackage = Join-Path $Context.InstallPrefix "share\dali2-ui-foundation"
$ComponentsPackage = Join-Path $Context.InstallPrefix "share\dali2-ui-components"
Assert-DaliPaths -Paths @(
  (Join-Path $CorePackage "dali2-core-config.cmake"),
  (Join-Path $AdaptorPackage "dali2-adaptor-config.cmake"),
  (Join-Path $FoundationPackage "dali2-ui-foundation-config.cmake"),
  (Join-Path $ComponentsPackage "dali2-ui-components-config.cmake")
) -Description "DALi package; run all four build scripts first"

$Arguments = (Get-DaliCommonCMakeArguments -Context $Context) + @(
  "-DDALI_UI_SAMPLE_LIST=$($Samples -join ';')",
  "-Ddali2-core_DIR=$CorePackage",
  "-Ddali2-adaptor_DIR=$AdaptorPackage",
  "-Ddali2-ui-foundation_DIR=$FoundationPackage",
  "-Ddali2-ui-components_DIR=$ComponentsPackage"
)
if($ImageViewTargets.Count -gt 0)
{
  $Arguments += "-DIMAGE_VIEW_SAMPLE_LIST=$($ImageViewTargets -join ';')"
}

Invoke-DaliCMakeProject `
  -Name "dali-ui samples" `
  -SourceDirectory (Join-Path $Context.DaliRoot "dali-ui\samples") `
  -BuildDirectory (Join-Path $Context.BuildRoot "dali-ui-samples") `
  -ConfigureArguments $Arguments `
  -Jobs $Jobs

Write-Host "`nSample build completed. Executables are in $($Context.InstallPrefix)\bin." -ForegroundColor Green
