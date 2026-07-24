[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$InstallPrefix,
  [Parameter(Mandatory = $true)]
  [string]$SourceRoot,
  [Parameter(Mandatory = $true)]
  [string]$BuildRoot,
  [string]$Repository = "git://git.tizen.org/platform/core/graphics/tizenvg.git",
  [string]$Revision = "ae039a6154a258a8fa19f23b25285acd73d2f6c1",
  [string]$PythonCommand = "",
  [string]$VsDevCmd = ""
)

$ErrorActionPreference = "Stop"

$ScriptRoot = $PSScriptRoot

. (Join-Path $ScriptRoot "dependency-network.ps1")

function Invoke-Native
{
  param(
    [string]$Command,
    [string[]]$Arguments
  )

  & $Command @Arguments | Out-Host
  if($LASTEXITCODE -ne 0)
  {
    throw "$Command failed with exit code $LASTEXITCODE"
  }
}

function Get-MesonVersionText
{
  param([string]$MesonPath)

  $PreviousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try
  {
    return (& $MesonPath --version | Select-Object -First 1)
  }
  finally
  {
    $ErrorActionPreference = $PreviousErrorActionPreference
  }
}

function Test-MesonVersionSupported
{
  param(
    [string]$MesonPath,
    [ref]$VersionText
  )

  $Text = Get-MesonVersionText $MesonPath
  $VersionText.Value = $Text
  if($Text -notmatch '^(\d+\.\d+\.\d+)')
  {
    return $false
  }
  return ([version]$Matches[1] -ge [version]"0.63.0")
}

function Test-Python3Command
{
  param([string]$Candidate)

  if(-not $Candidate -or -not (Test-Path -LiteralPath $Candidate))
  {
    return $false
  }

  $PreviousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try
  {
    $VersionText = (& $Candidate --version 2>&1 | Select-Object -First 1)
    return ($LASTEXITCODE -eq 0 -and $VersionText -match '^Python 3\.')
  }
  finally
  {
    $ErrorActionPreference = $PreviousErrorActionPreference
  }
}

function Resolve-PythonCommand
{
  if($script:PythonCommand)
  {
    if(Test-Python3Command $script:PythonCommand)
    {
      return $script:PythonCommand
    }
    throw "The requested Python command is not a working Python 3 executable: $script:PythonCommand"
  }

  $Python = Get-Command python.exe -ErrorAction SilentlyContinue
  if($Python -and (Test-Python3Command $Python.Source))
  {
    return $Python.Source
  }

  throw "Python 3 was not found. Install Python 3 or run the combined setup so it can reuse vcpkg's Python tool."
}

function Install-LocalMesonTools
{
  $ToolRoot = Join-Path $BuildRoot "meson-tools"
  $VenvPython = Join-Path $ToolRoot "Scripts\python.exe"
  $PortablePython = Join-Path $ToolRoot "python.exe"
  $ScriptsDirectory = Join-Path $ToolRoot "Scripts"
  $MesonPath = Join-Path $ScriptsDirectory "meson.exe"

  if(-not (Test-Path -LiteralPath $VenvPython) -and -not (Test-Path -LiteralPath $PortablePython))
  {
    New-Item -ItemType Directory -Force -Path $ToolRoot | Out-Null
    $Python = Resolve-PythonCommand
    Write-Host "Creating local Meson tool environment: $ToolRoot"

    $PreviousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try
    {
      & $Python -c "import venv" 2>$null
      $HasVenv = ($LASTEXITCODE -eq 0)
    }
    finally
    {
      $ErrorActionPreference = $PreviousErrorActionPreference
    }

    if($HasVenv)
    {
      Invoke-Native $Python @("-m", "venv", $ToolRoot)
    }
    else
    {
      Write-Host "Python has no venv module; creating an isolated portable tool copy"
      $PythonHome = Split-Path -Parent $Python
      Copy-Item -Path (Join-Path $PythonHome "*") -Destination $ToolRoot -Recurse -Force
    }
  }

  $LocalPython = if(Test-Path -LiteralPath $VenvPython) { $VenvPython } else { $PortablePython }
  if(-not (Test-Python3Command $LocalPython))
  {
    throw "Local Python tool environment is invalid: $LocalPython"
  }

  $CertificateBundle = Join-Path $ToolRoot "windows-root-certificates.pem"
  $PemBuilder = [Text.StringBuilder]::new()
  $SeenCertificates = @{}
  foreach($StoreLocation in @(
    [Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser,
    [Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine
  ))
  {
    $Store = [Security.Cryptography.X509Certificates.X509Store]::new(
      [Security.Cryptography.X509Certificates.StoreName]::Root,
      $StoreLocation)
    try
    {
      $Store.Open([Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly)
      foreach($Certificate in $Store.Certificates)
      {
        if(-not $SeenCertificates.ContainsKey($Certificate.Thumbprint))
        {
          $SeenCertificates[$Certificate.Thumbprint] = $true
          $null = $PemBuilder.AppendLine("-----BEGIN CERTIFICATE-----")
          $null = $PemBuilder.AppendLine([Convert]::ToBase64String($Certificate.RawData, [Base64FormattingOptions]::InsertLineBreaks))
          $null = $PemBuilder.AppendLine("-----END CERTIFICATE-----")
        }
      }
    }
    finally
    {
      $Store.Close()
    }
  }
  [IO.File]::WriteAllText($CertificateBundle, $PemBuilder.ToString(), [Text.Encoding]::ASCII)
  $env:PIP_CERT = $CertificateBundle
  $env:SSL_CERT_FILE = $CertificateBundle
  $PreviousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try
  {
    & $LocalPython -m pip --version 2>$null | Out-Null
    $HasPip = ($LASTEXITCODE -eq 0)
  }
  finally
  {
    $ErrorActionPreference = $PreviousErrorActionPreference
  }

  if(-not $HasPip)
  {
    $GetPip = Join-Path $ToolRoot "get-pip.py"
    Write-Host "Bootstrapping pip for the portable Python tool environment"
    Invoke-Native "curl.exe" @("--fail", "--location", "--ssl-no-revoke", "--connect-timeout", "$DaliNetworkTimeoutSeconds", "--speed-limit", "$DaliNetworkLowSpeedBytesPerSecond", "--speed-time", "$DaliNetworkTimeoutSeconds", "--retry", "$DaliNetworkRetryCount", "--retry-delay", "1", "--output", $GetPip, "https://bootstrap.pypa.io/pip/3.7/get-pip.py")
    Invoke-Native $LocalPython @($GetPip)
  }

  Write-Host "Installing Meson/Ninja into local tool environment"
  Invoke-Native $LocalPython @("-m", "pip", "install", "--retries", "$DaliNetworkRetryCount", "--timeout", "$DaliNetworkTimeoutSeconds", "--upgrade", "pip")
  Invoke-Native $LocalPython @("-m", "pip", "install", "--retries", "$DaliNetworkRetryCount", "--timeout", "$DaliNetworkTimeoutSeconds", "meson==0.63.3", "ninja==1.11.1.1")

  if(-not (Test-Path -LiteralPath $MesonPath))
  {
    throw "Local Meson was not installed: $MesonPath"
  }

  $env:PATH = "$ScriptsDirectory;$env:PATH"
  return $MesonPath
}

function Resolve-MesonCommand
{
  $Existing = Get-Command meson.exe -ErrorAction SilentlyContinue
  if($Existing)
  {
    $ExistingVersionText = ""
    if(Test-MesonVersionSupported $Existing.Source ([ref]$ExistingVersionText))
    {
      Write-Host "Using Meson ${ExistingVersionText}: $($Existing.Source)"
      return $Existing.Source
    }

    Write-Warning "Ignoring unsupported Meson ${ExistingVersionText}: $($Existing.Source)"
  }

  $LocalMeson = Install-LocalMesonTools
  $LocalVersionText = ""
  if(-not (Test-MesonVersionSupported $LocalMeson ([ref]$LocalVersionText)))
  {
    throw "Meson 0.63.0 or newer is required for TizenVG. Local Meson validation failed: $LocalMeson"
  }

  Write-Host "Using Meson ${LocalVersionText}: $LocalMeson"
  return $LocalMeson
}

Get-Command git -ErrorAction Stop | Out-Null
$MesonCommand = Resolve-MesonCommand

if(-not (Get-Command cl.exe -ErrorAction SilentlyContinue))
{
  if(-not $VsDevCmd)
  {
    $VsWhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
    if(-not (Test-Path -LiteralPath $VsWhere))
    {
      throw "vswhere.exe was not found; run from an x64 MSVC Developer PowerShell or pass -VsDevCmd"
    }

    $VisualStudioRoot = & $VsWhere -latest -products * `
      -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
      -property installationPath
    if($LASTEXITCODE -ne 0 -or -not $VisualStudioRoot)
    {
      throw "Visual Studio with the x64 C++ tools was not found"
    }
    $VsDevCmd = Join-Path $VisualStudioRoot "Common7\Tools\VsDevCmd.bat"
  }

  if(-not (Test-Path -LiteralPath $VsDevCmd))
  {
    throw "VsDevCmd.bat was not found: $VsDevCmd"
  }

  cmd.exe /d /c "call `"$VsDevCmd`" -arch=x64 -host_arch=x64 >nul && set" |
    ForEach-Object {
      if($_ -match '^([^=]+)=(.*)$')
      {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
      }
    }
}

Get-Command cl.exe -ErrorAction Stop | Out-Null
Get-Command ninja.exe -ErrorAction Stop | Out-Null

if(Test-Path -LiteralPath $SourceRoot)
{
  if(-not (Test-Path -LiteralPath (Join-Path $SourceRoot ".git")))
  {
    throw "SourceRoot exists but is not a Git checkout: $SourceRoot"
  }

  $SourceStatus = (Invoke-DaliGit -Arguments @("-C", $SourceRoot, "status", "--porcelain")).StdOut
  if($SourceStatus)
  {
    throw "TizenVG checkout has local changes: $SourceRoot"
  }

  $RevisionCheck = Invoke-DaliGit -Arguments @("-C", $SourceRoot, "cat-file", "-e", "${Revision}^{commit}") -AllowFailure
  if($RevisionCheck.ExitCode -ne 0)
  {
    Invoke-DaliGitNetwork -Arguments @("-C", $SourceRoot, "fetch", "--progress", "origin", "tizen") | Out-Null
  }
  else
  {
    Write-Host "TizenVG revision $Revision is already available; skipping network fetch."
  }
}
else
{
  $SourceParent = Split-Path -Parent $SourceRoot
  New-Item -ItemType Directory -Force -Path $SourceParent | Out-Null
  Invoke-DaliGitNetwork -Arguments @("clone", "--progress", "--branch", "tizen", $Repository, $SourceRoot) -CleanupPathOnRetry $SourceRoot | Out-Null
}

Invoke-DaliGit -Arguments @("-C", $SourceRoot, "checkout", "--detach", $Revision) | Out-Null

New-Item -ItemType Directory -Force -Path $InstallPrefix | Out-Null

$MesonArguments = @(
  "setup"
  $BuildRoot
  $SourceRoot
  "--backend", "ninja"
  "--buildtype", "release"
  "--default-library", "shared"
  "--prefix", $InstallPrefix
  "--libdir", "lib"
  "-Dtools=svg2png"
  "-Dloaders=svg,lottie"
  "-Dcpp_args=/D_USE_MATH_DEFINES"
  "-Dstrip=false"
)

if(Test-Path -LiteralPath (Join-Path $BuildRoot "meson-private\coredata.dat"))
{
  $MesonArguments += "--reconfigure"
}

Invoke-Native $MesonCommand $MesonArguments
Invoke-Native $MesonCommand @("compile", "-C", $BuildRoot)
Invoke-Native $MesonCommand @("install", "-C", $BuildRoot)

$Header = Join-Path $InstallPrefix "include\thorvg.h"
$LottieHeader = Join-Path $InstallPrefix "include\thorvg_lottie.h"
$DllCandidates = @(
  (Join-Path $InstallPrefix "bin\thorvg.dll"),
  (Join-Path $InstallPrefix "lib\thorvg.dll")
)

if(-not (Test-Path -LiteralPath $Header))
{
  throw "TizenVG header was not installed: $Header"
}
if(-not (Test-Path -LiteralPath $LottieHeader))
{
  throw "TizenVG lottie header was not installed: $LottieHeader"
}
if(-not ($DllCandidates | Where-Object { Test-Path -LiteralPath $_ }))
{
  throw "TizenVG DLL was not installed below $InstallPrefix"
}

Write-Host "TizenVG $Revision installed in $InstallPrefix"
