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

$WindowsDependenciesPackage = Join-Path $Context.InstallPrefix "share\dali-windows-dependencies"
Assert-DaliPaths -Paths @(
  (Join-Path $WindowsDependenciesPackage "dali-windows-dependencies-config.cmake")
) -Description "windows-dependencies package; run build_windows_dependencies.ps1 first"

$Arguments = (Get-DaliCommonCMakeArguments -Context $Context) + @(
  "-DENABLE_PKG_CONFIGURE=OFF",
  "-DENABLE_LINK_TEST=OFF",
  "-DINSTALL_CMAKE_MODULES=ON",
  "-Ddali-windows-dependencies_DIR=$WindowsDependenciesPackage"
)

Invoke-DaliCMakeProject `
  -Name "dali-core" `
  -SourceDirectory (Join-Path $Context.DaliRoot "dali-core\build\tizen") `
  -BuildDirectory (Join-Path $Context.BuildRoot "dali-core") `
  -ConfigureArguments $Arguments `
  -Jobs $Jobs

Assert-DaliPaths -Paths @(
  (Join-Path $Context.InstallPrefix "bin\dali2-core.dll"),
  (Join-Path $Context.InstallPrefix "share\dali2-core\dali2-core-config.cmake")
) -Description "dali-core installation output"

Write-Host "`ndali-core build completed." -ForegroundColor Green
