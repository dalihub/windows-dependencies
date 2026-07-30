[CmdletBinding()]
param(
  # Configuration the DALi projects will be built with. The published SDK is
  # Release-only; for Debug the dali-windows-dependencies static library is
  # rebuilt in Debug so dali-core links without a CRT mismatch (LNK2038).
  [ValidateSet("Debug", "Release")]
  [string]$Configuration = "Release",
  [string]$Proxy = "",
  [string]$ReleaseRepository = "dalihub/windows-dependencies",
  [string]$ReleaseTag = "windows-sdk-latest",
  [switch]$BuildFromSource,
  # Skip the LWE (Starfish) web-engine SDK build; WebView will be unavailable.
  [switch]$SkipStarfish,
  [int]$Jobs = 8
)

$ErrorActionPreference = "Stop"
$ScriptRoot = $PSScriptRoot
$WorkspaceRoot = Split-Path -Parent $ScriptRoot
$SdkRoot = Join-Path $WorkspaceRoot "WindowsDependenciesSDK"
$DependencyRoot = Join-Path $ScriptRoot ".deps"
$DownloadRoot = Join-Path $DependencyRoot "windows-sdk-download"
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

function Move-DirectoryWithRetry
{
  param(
    [Parameter(Mandatory = $true)]
    [string]$LiteralPath,
    [Parameter(Mandatory = $true)]
    [string]$Destination,
    [int]$RetryCount = 10,
    [int]$RetryDelayMs = 500
  )

  $Attempt = 0
  while($Attempt -lt $RetryCount)
  {
    try
    {
      Move-Item -LiteralPath $LiteralPath -Destination $Destination -Force
      return
    }
    catch
    {
      $Attempt++
      if($Attempt -ge $RetryCount)
      {
        throw
      }
      Start-Sleep -Milliseconds $RetryDelayMs
    }
  }
}

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

  $ExtractRoot = Join-Path $DependencyRoot "windows-sdk-extract-$([Guid]::NewGuid().ToString('N'))"
  New-Item -ItemType Directory -Force -Path $ExtractRoot | Out-Null
  try
  {
    Expand-Archive -LiteralPath $ArchivePath -DestinationPath $ExtractRoot -Force
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
      Move-DirectoryWithRetry -LiteralPath $SdkRoot -Destination $BackupRoot
    }
    try
    {
      Move-DirectoryWithRetry -LiteralPath $ExtractRoot -Destination $SdkRoot
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
    Configuration = $Configuration
    SkipTizenVg = $true
    Clean = $true
    Jobs = $Jobs
  }
  if($Proxy)
  {
    $BuildArguments.Proxy = $Proxy
  }
  if($SkipStarfish)
  {
    $BuildArguments.SkipStarfish = $true
  }
  & (Join-Path $ScriptRoot "build_windows_dependencies.ps1") @BuildArguments
}

# The published SDK ships a Release-only dali-windows-dependencies.lib. It is
# a static library, so a Debug DALi build cannot link it (LNK2038 CRT
# mismatch); rebuild just that project in Debug into the SDK.
if($InstalledRelease -and $Configuration -eq "Debug")
{
  Write-Host "Rebuilding dali-windows-dependencies.lib as Debug (published SDK is Release-only)." -ForegroundColor Yellow
  $DebugContext = New-DaliBuildContext -WindowsDependenciesRoot $ScriptRoot `
    -VcpkgRoot (Join-Path $SdkRoot "vcpkg") -InstallPrefix $SdkRoot
  Initialize-DaliBuildEnvironment -Context $DebugContext
  $DebugArguments = Get-DaliCommonCMakeArguments -Context $DebugContext -Configuration $Configuration
  Invoke-DaliCMakeProject `
    -Name "windows-dependencies ($Configuration)" `
    -SourceDirectory (Join-Path $ScriptRoot "build") `
    -BuildDirectory (Join-Path $ScriptRoot "_build\windows") `
    -ConfigureArguments $DebugArguments `
    -Clean `
    -Jobs $Jobs
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

# LWE (Starfish) web engine SDK for the WebView plugin. A failure here only
# warns: WebView is optional, and setup-starfish.ps1 can be re-run standalone.
# Note: the LWE SDK is currently Release-only; with -Configuration Debug the
# WebView plugin cannot be used (LWE passes std::string across the DLL
# boundary, so all configurations must match).
if(-not $SkipStarfish)
{
  if($Configuration -eq "Debug")
  {
    Write-Warning "LWE (Starfish) is built Release-only for now; WebView is unavailable in Debug builds."
  }
  try
  {
    & (Join-Path $ScriptRoot "vcpkg-script\setup-starfish.ps1") -InstallPrefix $SdkRoot -Jobs $Jobs
  }
  catch
  {
    Write-Warning "LWE (Starfish) SDK setup failed: $($_.Exception.Message)"
    Write-Warning "WebView will be unavailable. Fix the issue and re-run vcpkg-script\setup-starfish.ps1,"
    Write-Warning "or skip building lwe-web-engine-plugin."
  }
}

$RuntimeContext = New-DaliBuildContext -WindowsDependenciesRoot $ScriptRoot
Install-DaliRuntimeScripts -Context $RuntimeContext
Write-Host "`nDALi Windows dependencies are ready in $SdkRoot" -ForegroundColor Green
Write-Host "Build DALi projects individually, then run: . $(Join-Path $RuntimeContext.InstallPrefix 'setenv.ps1')"
