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
$CorePackage = Join-Path $Context.InstallPrefix "share\dali2-core"
Assert-DaliPaths -Paths @(
  (Join-Path $WindowsDependenciesPackage "dali-windows-dependencies-config.cmake"),
  (Join-Path $CorePackage "dali2-core-config.cmake")
) -Description "prerequisite package; run the preceding build scripts first"

$TizenVgOutputs = @(
  (Join-Path $Context.InstallPrefix "include\thorvg.h"),
  (Join-Path $Context.InstallPrefix "include\thorvg_lottie.h"),
  (Join-Path $Context.InstallPrefix "bin\thorvg.dll")
)
$TizenVgOutputCount = @($TizenVgOutputs | Where-Object { Test-Path -LiteralPath $_ }).Count
if($TizenVgOutputCount -eq 0)
{
  $ThorVgSupport = "OFF"
  Write-Host "TizenVG is not installed. Building with NanoSVG fallback and without CanvasRenderer/Lottie."
}
elseif($TizenVgOutputCount -eq $TizenVgOutputs.Count)
{
  $ThorVgSupport = "ON"
  Write-Host "TizenVG installation detected. Building with CanvasRenderer/Lottie support."
}
else
{
  throw "The TizenVG installation is incomplete. Re-run build_windows_dependencies.ps1 or clean dali-env."
}

$Arguments = (Get-DaliCommonCMakeArguments -Context $Context) + @(
  "-DENABLE_PKG_CONFIGURE=OFF",
  "-DENABLE_LINK_TEST=OFF",
  "-DINSTALL_CMAKE_MODULES=ON",
  "-DPROFILE_LCASE=windows",
  "-DENABLE_PROFILE=WINDOWS",
  "-DENABLE_GRAPHICS_BACKEND=GLES",
  "-DENABLE_VECTOR_BASED_TEXT_RENDERING=OFF",
  "-Dthorvg_support=$ThorVgSupport",
  "-Ddali-windows-dependencies_DIR=$WindowsDependenciesPackage",
  "-Ddali2-core_DIR=$CorePackage"
)

Invoke-DaliCMakeProject `
  -Name "dali-adaptor" `
  -SourceDirectory (Join-Path $Context.DaliRoot "dali-adaptor\build\tizen") `
  -BuildDirectory (Join-Path $Context.BuildRoot "dali-adaptor") `
  -ConfigureArguments $Arguments `
  -Jobs $Jobs

Assert-DaliPaths -Paths @(
  (Join-Path $Context.InstallPrefix "bin\dali2-adaptor.dll"),
  (Join-Path $Context.InstallPrefix "share\dali2-adaptor\dali2-adaptor-config.cmake")
) -Description "dali-adaptor installation output"

Write-Host "`ndali-adaptor build completed." -ForegroundColor Green
