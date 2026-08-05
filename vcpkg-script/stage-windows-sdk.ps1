[CmdletBinding()]
param(
  [ValidateSet("Debug", "Release")]
  [string]$Configuration = "Debug",
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
$SourceInstalledRoot = Join-Path $VcpkgRoot "installed"
$SourceTripletRoot = Join-Path $SourceInstalledRoot "x64-windows"
$SourceConfigurationMarker = Join-Path $SourceTripletRoot ".dali-configuration"
$SdkInstalledRoot = Join-Path $SdkVcpkgRoot "installed"
$SdkTripletRoot = Join-Path $SdkInstalledRoot "x64-windows"

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
  $SourceTripletRoot,
  $SourceConfigurationMarker
)
foreach($RequiredPath in $RequiredPaths)
{
  if(-not (Test-Path -LiteralPath $RequiredPath))
  {
    throw "Required vcpkg SDK input is missing: $RequiredPath"
  }
}

$BuiltConfiguration = (Get-Content -LiteralPath $SourceConfigurationMarker -Raw).Trim()
if($BuiltConfiguration -ne $Configuration)
{
  throw "The source vcpkg tree contains $BuiltConfiguration packages, not $Configuration packages."
}

$SourceDebugBin = Join-Path $SourceTripletRoot "debug\bin"
$SourceReleaseBin = Join-Path $SourceTripletRoot "bin"
if($Configuration -eq "Debug")
{
  if(-not (Test-Path -LiteralPath $SourceDebugBin) -or (Test-Path -LiteralPath $SourceReleaseBin))
  {
    throw "The source vcpkg tree is not Debug-only: $SourceTripletRoot"
  }
}
elseif(-not (Test-Path -LiteralPath $SourceReleaseBin) -or (Test-Path -LiteralPath $SourceDebugBin))
{
  throw "The source vcpkg tree is not Release-only: $SourceTripletRoot"
}

New-Item -ItemType Directory -Force -Path $SdkVcpkgRoot | Out-Null

foreach($DirectoryName in @("scripts", "triplets", "ports"))
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

if(Test-Path -LiteralPath $SdkInstalledRoot)
{
  Remove-Item -LiteralPath $SdkInstalledRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $SdkInstalledRoot | Out-Null
Copy-Item -LiteralPath $SourceTripletRoot -Destination $SdkTripletRoot -Recurse -Force

$SourceVcpkgMetadata = Join-Path $SourceInstalledRoot "vcpkg"
if(Test-Path -LiteralPath $SourceVcpkgMetadata)
{
  Copy-Item -LiteralPath $SourceVcpkgMetadata -Destination (Join-Path $SdkInstalledRoot "vcpkg") -Recurse -Force
}

if($Configuration -eq "Release")
{
  $ReleaseRoot = Join-Path $SdkTripletRoot "release"
  New-Item -ItemType Directory -Force -Path $ReleaseRoot | Out-Null
  Move-Item -LiteralPath (Join-Path $SdkTripletRoot "bin") -Destination (Join-Path $ReleaseRoot "bin")

  $CMakeFiles = Get-ChildItem -LiteralPath (Join-Path $SdkTripletRoot "share") -File -Recurse -Filter "*.cmake"
  foreach($CMakeFile in $CMakeFiles)
  {
    $Content = [IO.File]::ReadAllText($CMakeFile.FullName)
    $Updated = $Content.Replace('${_IMPORT_PREFIX}/bin/', '${_IMPORT_PREFIX}/release/bin/')
    $Updated = $Updated.Replace('${PACKAGE_PREFIX_DIR}/bin/', '${PACKAGE_PREFIX_DIR}/release/bin/')
    $Updated = $Updated.Replace('${CMAKE_CURRENT_LIST_DIR}/../../bin/', '${CMAKE_CURRENT_LIST_DIR}/../../release/bin/')
    if($Updated -ne $Content)
    {
      [IO.File]::WriteAllText($CMakeFile.FullName, $Updated, [Text.UTF8Encoding]::new($false))
    }
  }

  $InfoRoot = Join-Path $SdkInstalledRoot "vcpkg\info"
  if(Test-Path -LiteralPath $InfoRoot)
  {
    foreach($ListFile in (Get-ChildItem -LiteralPath $InfoRoot -File -Filter "*.list"))
    {
      $Content = [IO.File]::ReadAllText($ListFile.FullName)
      $Updated = $Content.Replace('x64-windows/bin/', 'x64-windows/release/bin/')
      if($Updated -ne $Content)
      {
        [IO.File]::WriteAllText($ListFile.FullName, $Updated, [Text.UTF8Encoding]::new($false))
      }
    }
  }
}

$SelectedBin = Join-Path $SdkTripletRoot "$($Configuration.ToLowerInvariant())\bin"
$OtherConfiguration = if($Configuration -eq "Debug") { "release" } else { "debug" }
if(-not (Test-Path -LiteralPath $SelectedBin) -or
   (Test-Path -LiteralPath (Join-Path $SdkTripletRoot "bin")) -or
   (Test-Path -LiteralPath (Join-Path $SdkTripletRoot "$OtherConfiguration\bin")))
{
  throw "The staged vcpkg SDK is not $Configuration-only: $SdkTripletRoot"
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

Write-Host "Staged relocatable $Configuration-only vcpkg SDK in $SdkVcpkgRoot"
