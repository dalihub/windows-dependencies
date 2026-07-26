[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$VcpkgRoot,
  [Parameter(Mandatory = $true)]
  [string]$SdkRoot,
  [switch]$Clean
)

$ErrorActionPreference = "Stop"
$VcpkgRoot = [IO.Path]::GetFullPath($VcpkgRoot)
$SdkRoot = [IO.Path]::GetFullPath($SdkRoot)
$SdkVcpkgRoot = Join-Path $SdkRoot "vcpkg"

if($Clean -and (Test-Path -LiteralPath $SdkRoot))
{
  if((Split-Path -Leaf $SdkRoot) -ne "WindowsDependenciesSDK")
  {
    throw "Refusing to clean an unexpected SDK directory: $SdkRoot"
  }
  Remove-Item -LiteralPath $SdkRoot -Recurse -Force
}

$RequiredPaths = @(
  (Join-Path $VcpkgRoot "scripts\buildsystems\vcpkg.cmake"),
  (Join-Path $VcpkgRoot "installed\x64-windows")
)
foreach($RequiredPath in $RequiredPaths)
{
  if(-not (Test-Path -LiteralPath $RequiredPath))
  {
    throw "Required vcpkg SDK input is missing: $RequiredPath"
  }
}

New-Item -ItemType Directory -Force -Path $SdkVcpkgRoot | Out-Null

foreach($DirectoryName in @("scripts", "triplets", "ports", "installed"))
{
  $Source = Join-Path $VcpkgRoot $DirectoryName
  if(Test-Path -LiteralPath $Source)
  {
    $Destination = Join-Path $SdkVcpkgRoot $DirectoryName
    if(Test-Path -LiteralPath $Destination)
    {
      Remove-Item -LiteralPath $Destination -Recurse -Force
    }
    Copy-Item -LiteralPath $Source -Destination $SdkVcpkgRoot -Recurse -Force
  }
}

foreach($FileName in @(".vcpkg-root", "vcpkg.exe"))
{
  $Source = Join-Path $VcpkgRoot $FileName
  if(Test-Path -LiteralPath $Source)
  {
    Copy-Item -LiteralPath $Source -Destination $SdkVcpkgRoot -Force
  }
}

$PythonTools = Join-Path $VcpkgRoot "downloads\tools\python"
if(Test-Path -LiteralPath $PythonTools)
{
  $SdkDownloadsTools = Join-Path $SdkVcpkgRoot "downloads\tools"
  New-Item -ItemType Directory -Force -Path $SdkDownloadsTools | Out-Null
  $SdkPythonTools = Join-Path $SdkDownloadsTools "python"
  if(Test-Path -LiteralPath $SdkPythonTools)
  {
    Remove-Item -LiteralPath $SdkPythonTools -Recurse -Force
  }
  Copy-Item -LiteralPath $PythonTools -Destination $SdkDownloadsTools -Recurse -Force
}

Write-Host "Staged relocatable vcpkg SDK in $SdkVcpkgRoot"
