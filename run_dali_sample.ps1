[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [string]$Name = "hello-world.example",
  [string]$VcpkgRoot = "",
  [int]$Width = 1280,
  [int]$Height = 720
)

$ErrorActionPreference = "Stop"
$ScriptRoot = $PSScriptRoot
. (Join-Path $ScriptRoot "vcpkg-script\dali-build-common.ps1")

if((Split-Path -Leaf $Name) -ne $Name)
{
  throw "Name must be an executable name, not a path."
}
if(-not $Name.EndsWith(".exe", [StringComparison]::OrdinalIgnoreCase))
{
  $Name += ".exe"
}

$Context = New-DaliBuildContext -WindowsDependenciesRoot $ScriptRoot -VcpkgRoot $VcpkgRoot
$RuntimeEnvironment = Join-Path $Context.InstallPrefix "set-dali-runtime-env.ps1"
$Executable = Join-Path (Join-Path $Context.InstallPrefix "bin") $Name
Assert-DaliPaths -Paths @($RuntimeEnvironment, $Executable) -Description "runtime file"

. $RuntimeEnvironment
$env:PATH = "$(Join-Path $Context.VcpkgRoot "installed\x64-windows\bin");$env:PATH"
$env:DALI_WINDOW_WIDTH = "$Width"
$env:DALI_WINDOW_HEIGHT = "$Height"

Write-Host "Running $Executable" -ForegroundColor Cyan
& $Executable
if($LASTEXITCODE -ne 0)
{
  throw "$Name exited with code $LASTEXITCODE"
}
