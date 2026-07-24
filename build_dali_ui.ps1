[CmdletBinding()]
param(
  [string]$VcpkgRoot = "",
  [int]$Jobs = 8
)

$ErrorActionPreference = "Stop"
$ScriptRoot = $PSScriptRoot
. (Join-Path $ScriptRoot "vcpkg-script\dali-build-common.ps1")

$Context = New-DaliBuildContext -WindowsDependenciesRoot $ScriptRoot -VcpkgRoot $VcpkgRoot
Initialize-DaliBuildEnvironment -Context $Context

$CorePackage = Join-Path $Context.InstallPrefix "share\dali2-core"
$AdaptorPackage = Join-Path $Context.InstallPrefix "share\dali2-adaptor"
Assert-DaliPaths -Paths @(
  (Join-Path $CorePackage "dali2-core-config.cmake"),
  (Join-Path $AdaptorPackage "dali2-adaptor-config.cmake")
) -Description "prerequisite package; run the preceding build scripts first"

$Arguments = (Get-DaliCommonCMakeArguments -Context $Context) + @(
  "-DENABLE_PKG_CONFIGURE=OFF",
  "-DINSTALL_CMAKE_MODULES=ON",
  "-DENABLE_VECTOR_BASED_TEXT_RENDERING=OFF",
  "-Ddali2-core_DIR=$CorePackage",
  "-Ddali2-adaptor_DIR=$AdaptorPackage"
)

Invoke-DaliCMakeProject `
  -Name "dali-ui" `
  -SourceDirectory (Join-Path $Context.DaliRoot "dali-ui\build\tizen") `
  -BuildDirectory (Join-Path $Context.BuildRoot "dali-ui") `
  -ConfigureArguments $Arguments `
  -Jobs $Jobs

Assert-DaliPaths -Paths @(
  (Join-Path $Context.InstallPrefix "bin\dali2-ui-foundation.dll"),
  (Join-Path $Context.InstallPrefix "bin\dali2-ui-components.dll"),
  (Join-Path $Context.InstallPrefix "share\dali2-ui-foundation\dali2-ui-foundation-config.cmake"),
  (Join-Path $Context.InstallPrefix "share\dali2-ui-components\dali2-ui-components-config.cmake")
) -Description "dali-ui installation output"

Write-Host "`ndali-ui build completed." -ForegroundColor Green
