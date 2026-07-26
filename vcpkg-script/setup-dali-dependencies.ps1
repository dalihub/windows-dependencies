[CmdletBinding()]
param(
  [string]$DaliRoot = "C:\work\DALi",
  [string]$VcpkgRoot = "C:\Tools\DALI_VCPKG\vcpkg",
  [string]$VcpkgRepository = "https://github.com/dalihub/vcpkg.git",
  [string]$TizenVgRepository = "https://github.sec.samsung.net/tizen/tizenvg.git",
  [string]$TizenVgRevision = "ae039a6154a258a8fa19f23b25285acd73d2f6c1",
  [string]$InstallPrefix = "",
  [string]$Proxy = "",
  [switch]$SkipVcpkg,
  [switch]$SkipTizenVg
)

$ErrorActionPreference = "Stop"
$ScriptRoot = $PSScriptRoot
if(-not $InstallPrefix)
{
  $InstallPrefix = Join-Path $DaliRoot "WindowsDependenciesSDK"
}

. (Join-Path $ScriptRoot "dependency-network.ps1")
Set-DaliProxyEnvironment -Proxy $Proxy

if(-not $SkipVcpkg)
{
  $VcpkgArguments = @{
    VcpkgRoot = $VcpkgRoot
    VcpkgRepository = $VcpkgRepository
  }
  if($Proxy)
  {
    $VcpkgArguments.Proxy = $Proxy
  }

  & (Join-Path $ScriptRoot "setup-vcpkg-vs2022.ps1") @VcpkgArguments
}

if(-not $SkipTizenVg)
{
  $TizenVgSourceRoot = Join-Path $DaliRoot "tizenvg"
  $TizenVgBuildRoot = Join-Path $DaliRoot ".deps\tizenvg-build"
  $RevisionAvailable = $false
  if(Test-Path -LiteralPath (Join-Path $TizenVgSourceRoot ".git"))
  {
    $RevisionCheck = Invoke-DaliGit -Arguments @(
      "-C", $TizenVgSourceRoot, "cat-file", "-e", "${TizenVgRevision}^{commit}"
    ) -AllowFailure
    $RevisionAvailable = ($RevisionCheck.ExitCode -eq 0)
  }

  if(-not $RevisionAvailable)
  {
    Write-Host "Checking whether the optional TizenVG repository is available."
    $RepositoryCheck = Invoke-DaliGitNetwork -Arguments @(
      "ls-remote", "--exit-code", $TizenVgRepository, "refs/heads/tizen"
    ) -AllowFailure
    if($RepositoryCheck.ExitCode -ne 0)
    {
      Write-Warning "TizenVG is unavailable from this network. Continuing without the optional TizenVG backend."
      $SkipTizenVg = $true
    }
  }
}

if(-not $SkipTizenVg)
{
  $TizenVgArguments = @{
    InstallPrefix = $InstallPrefix
    SourceRoot = $TizenVgSourceRoot
    BuildRoot = $TizenVgBuildRoot
    Repository = $TizenVgRepository
    Revision = $TizenVgRevision
  }
  $VcpkgPython = Join-Path $VcpkgRoot "downloads\tools\python\python-3.7.3-amd64\python.exe"
  if(Test-Path -LiteralPath $VcpkgPython)
  {
    $TizenVgArguments.PythonCommand = $VcpkgPython
  }

  & (Join-Path $ScriptRoot "setup-tizenvg.ps1") @TizenVgArguments
}

Write-Host "DALi third-party dependency setup completed."
