[CmdletBinding()]
param(
  [string]$SdkRoot = "",
  [string]$OutputDirectory = "",
  [string]$InputManifest = ""
)

$ErrorActionPreference = "Stop"
$ScriptRoot = $PSScriptRoot
$WorkspaceRoot = Split-Path -Parent $ScriptRoot
if(-not $SdkRoot) { $SdkRoot = Join-Path $WorkspaceRoot "WindowsDependenciesSDK" }
if(-not $OutputDirectory) { $OutputDirectory = Join-Path $ScriptRoot "artifacts" }
$SdkRoot = [IO.Path]::GetFullPath($SdkRoot)
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)

$Toolchain = Join-Path $SdkRoot "vcpkg\scripts\buildsystems\vcpkg.cmake"
if(-not (Test-Path -LiteralPath $Toolchain))
{
  throw "WindowsDependenciesSDK is incomplete: $Toolchain"
}
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

$SdkInputManifest = Join-Path $SdkRoot "build-inputs.json"
if($InputManifest)
{
  Copy-Item -LiteralPath $InputManifest -Destination $SdkInputManifest -Force
}
else
{
  & (Join-Path $ScriptRoot "new-windows-sdk-manifest.ps1") -Mode Inputs -OutputPath $SdkInputManifest
}

$ContentsManifest = Join-Path $OutputDirectory "sdk-contents.json"
& (Join-Path $ScriptRoot "new-windows-sdk-manifest.ps1") `
  -Mode Contents -SdkRoot $SdkRoot -OutputPath $ContentsManifest
Copy-Item -LiteralPath $ContentsManifest -Destination (Join-Path $SdkRoot "sdk-contents.json") -Force
Copy-Item -LiteralPath $SdkInputManifest -Destination (Join-Path $OutputDirectory "build-inputs.json") -Force

$ArchiveName = "DALi-WindowsDependenciesSDK-x64.zip"
$ArchivePath = Join-Path $OutputDirectory $ArchiveName
if(Test-Path -LiteralPath $ArchivePath) { Remove-Item -LiteralPath $ArchivePath -Force }
& tar.exe -a -c -f $ArchivePath -C $SdkRoot .
if($LASTEXITCODE -ne 0) { throw "Failed to create $ArchivePath" }

$Hash = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()
$ChecksumPath = "$ArchivePath.sha256"
[IO.File]::WriteAllText($ChecksumPath, "$Hash  $ArchiveName`n", [Text.UTF8Encoding]::new($false))
Write-Host "Created $ArchivePath"
Write-Host "Created $ChecksumPath"
