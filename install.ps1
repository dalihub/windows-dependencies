[CmdletBinding()]
param(
  [string]$Proxy = "",
  [string]$ReleaseRepository = "dalihub/windows-dependencies",
  [string]$ReleaseTag = "windows-sdk-latest",
  [switch]$BuildFromSource,
  [int]$Jobs = 8
)

$ErrorActionPreference = "Stop"
$ScriptRoot = $PSScriptRoot
$WorkspaceRoot = Split-Path -Parent $ScriptRoot
$SdkRoot = Join-Path $WorkspaceRoot "WindowsDependenciesSDK"
$DownloadRoot = Join-Path $WorkspaceRoot ".deps\windows-sdk-download"
$ArchiveName = "DALi-WindowsDependenciesSDK-x64.zip"
$ChecksumName = "$ArchiveName.sha256"
$ArchivePath = Join-Path $DownloadRoot $ArchiveName
$ChecksumPath = Join-Path $DownloadRoot $ChecksumName

if($ReleaseRepository -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$')
{
  throw "ReleaseRepository must use the owner/repository form."
}

. (Join-Path $ScriptRoot "vcpkg-script\dependency-network.ps1")
. (Join-Path $ScriptRoot "vcpkg-script\dali-build-common.ps1")
Set-DaliProxyEnvironment -Proxy $Proxy

function Install-DownloadedSdk
{
  $BaseUri = "https://github.com/$ReleaseRepository/releases/download/$ReleaseTag"
  New-Item -ItemType Directory -Force -Path $DownloadRoot | Out-Null
  Write-Host "Trying the published Windows dependencies SDK: $ReleaseRepository/$ReleaseTag"

  $ArchiveDownloaded = Invoke-DaliCurlNetwork `
    -Uri "$BaseUri/$ArchiveName" -OutputPath $ArchivePath -Resume -AllowFailure
  if(-not $ArchiveDownloaded)
  {
    return $false
  }

  if(Test-Path -LiteralPath $ChecksumPath)
  {
    Remove-Item -LiteralPath $ChecksumPath -Force
  }
  $ChecksumDownloaded = Invoke-DaliCurlNetwork `
    -Uri "$BaseUri/$ChecksumName" -OutputPath $ChecksumPath -AllowFailure
  if(-not $ChecksumDownloaded)
  {
    return $false
  }

  $ExpectedHash = ((Get-Content -LiteralPath $ChecksumPath -Raw).Trim() -split '\s+')[0]
  $ActualHash = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash
  if(-not $ExpectedHash -or $ExpectedHash -ne $ActualHash)
  {
    Write-Warning "The downloaded SDK checksum is invalid; falling back to a source build."
    Remove-Item -LiteralPath $ArchivePath -Force
    return $false
  }

  $ExtractRoot = Join-Path $WorkspaceRoot ".deps\windows-sdk-extract-$([Guid]::NewGuid().ToString('N'))"
  New-Item -ItemType Directory -Force -Path $ExtractRoot | Out-Null
  try
  {
    & tar.exe -xf $ArchivePath -C $ExtractRoot
    if($LASTEXITCODE -ne 0)
    {
      throw "Failed to extract $ArchivePath"
    }
    $ExpectedToolchain = Join-Path $ExtractRoot "vcpkg\scripts\buildsystems\vcpkg.cmake"
    if(-not (Test-Path -LiteralPath $ExpectedToolchain))
    {
      throw "The SDK archive does not contain its vcpkg toolchain."
    }

    $BackupRoot = "$SdkRoot.previous"
    if(Test-Path -LiteralPath $BackupRoot)
    {
      Remove-Item -LiteralPath $BackupRoot -Recurse -Force
    }
    if(Test-Path -LiteralPath $SdkRoot)
    {
      Move-Item -LiteralPath $SdkRoot -Destination $BackupRoot
    }
    try
    {
      Move-Item -LiteralPath $ExtractRoot -Destination $SdkRoot
    }
    catch
    {
      if(Test-Path -LiteralPath $BackupRoot)
      {
        Move-Item -LiteralPath $BackupRoot -Destination $SdkRoot
      }
      throw
    }
    if(Test-Path -LiteralPath $BackupRoot)
    {
      Remove-Item -LiteralPath $BackupRoot -Recurse -Force
    }
  }
  finally
  {
    if(Test-Path -LiteralPath $ExtractRoot)
    {
      Remove-Item -LiteralPath $ExtractRoot -Recurse -Force
    }
  }

  Write-Host "Installed the published SDK in $SdkRoot" -ForegroundColor Green
  return $true
}

$InstalledRelease = $false
if(-not $BuildFromSource)
{
  $InstalledRelease = Install-DownloadedSdk
}

if(-not $InstalledRelease)
{
  Write-Host "No usable published SDK was found. Building the same SDK layout from source." -ForegroundColor Yellow
  $BuildArguments = @{
    SkipTizenVg = $true
    Clean = $true
    Jobs = $Jobs
  }
  if($Proxy)
  {
    $BuildArguments.Proxy = $Proxy
  }
  & (Join-Path $ScriptRoot "build_windows_dependencies.ps1") @BuildArguments
}

$TizenVgArguments = @{
  DaliRoot = $WorkspaceRoot
  VcpkgRoot = (Join-Path $SdkRoot "vcpkg")
  InstallPrefix = $SdkRoot
  SkipVcpkg = $true
}
if($Proxy)
{
  $TizenVgArguments.Proxy = $Proxy
}
& (Join-Path $ScriptRoot "vcpkg-script\setup-dali-dependencies.ps1") @TizenVgArguments

$RuntimeContext = New-DaliBuildContext -WindowsDependenciesRoot $ScriptRoot
Install-DaliRuntimeScripts -Context $RuntimeContext
Write-Host "`nDALi Windows dependencies are ready in $SdkRoot" -ForegroundColor Green
Write-Host "Build DALi projects individually, then run: . $(Join-Path $RuntimeContext.InstallPrefix 'setenv.ps1')"
