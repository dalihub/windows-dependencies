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
  [string]$VsDevCmd = ""
)

$ErrorActionPreference = "Stop"

function ConvertTo-CommandLineArgument
{
  param([string]$Argument)

  if($Argument -notmatch '[\s"]')
  {
    return $Argument
  }

  return '"' + ($Argument -replace '\\', '\\' -replace '"', '\"') + '"'
}

function Invoke-GitTimed
{
  param(
    [string[]]$Arguments,
    [int]$TimeoutSeconds = 10
  )

  $StartInfo = [Diagnostics.ProcessStartInfo]::new()
  $StartInfo.FileName = "git"
  $StartInfo.Arguments = (($Arguments | ForEach-Object { ConvertTo-CommandLineArgument $_ }) -join " ")
  $StartInfo.UseShellExecute = $false
  $StartInfo.RedirectStandardOutput = $true
  $StartInfo.RedirectStandardError = $true
  $Process = [Diagnostics.Process]::Start($StartInfo)

  if(-not $Process.WaitForExit($TimeoutSeconds * 1000))
  {
    try { $Process.Kill() } catch { }
    throw "git $($StartInfo.Arguments) timed out after $TimeoutSeconds seconds"
  }

  $StdOut = $Process.StandardOutput.ReadToEnd()
  $StdErr = $Process.StandardError.ReadToEnd()
  if($Process.ExitCode -ne 0)
  {
    if($StdErr) { Write-Error $StdErr }
    throw "git $($StartInfo.Arguments) failed with exit code $($Process.ExitCode)"
  }

  return [pscustomobject]@{
    ExitCode = $Process.ExitCode
    StdOut = $StdOut
    StdErr = $StdErr
  }
}
function Invoke-Native
{
  param(
    [string]$Command,
    [string[]]$Arguments
  )

  & $Command @Arguments
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

function Resolve-PythonCommand
{
  $PythonCommand = Get-Command python.exe -ErrorAction SilentlyContinue
  if($PythonCommand)
  {
    return $PythonCommand.Source
  }

  throw "Python was not found. Install Python 3, or put python.exe in PATH so the script can install local Meson tools."
}

function Install-LocalMesonTools
{
  $ToolRoot = Join-Path $BuildRoot "meson-tools"
  $VenvPython = Join-Path $ToolRoot "Scripts\python.exe"
  $MesonPath = Join-Path $ToolRoot "Scripts\meson.exe"

  if(-not (Test-Path -LiteralPath $VenvPython))
  {
    New-Item -ItemType Directory -Force -Path $ToolRoot | Out-Null
    $Python = Resolve-PythonCommand
    Write-Host "Creating local Meson tool environment: $ToolRoot"
    Invoke-Native $Python @("-m", "venv", $ToolRoot)
  }

  Write-Host "Installing Meson/Ninja into local tool environment"
  Invoke-Native $VenvPython @("-m", "pip", "install", "--upgrade", "pip")
  Invoke-Native $VenvPython @("-m", "pip", "install", "meson==0.63.3", "ninja==1.11.1.1")

  if(-not (Test-Path -LiteralPath $MesonPath))
  {
    throw "Local Meson was not installed: $MesonPath"
  }

  $env:PATH = "$(Join-Path $ToolRoot "Scripts");$env:PATH"
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

  $SourceStatus = (Invoke-GitTimed @("-C", $SourceRoot, "status", "--porcelain")).StdOut
  if($SourceStatus)
  {
    throw "TizenVG checkout has local changes: $SourceRoot"
  }

  Invoke-GitTimed @("-C", $SourceRoot, "fetch", "origin", "tizen") | Out-Null
}
else
{
  $SourceParent = Split-Path -Parent $SourceRoot
  New-Item -ItemType Directory -Force -Path $SourceParent | Out-Null
  Invoke-GitTimed @("clone", "--branch", "tizen", $Repository, $SourceRoot) | Out-Null
}

Invoke-GitTimed @("-C", $SourceRoot, "checkout", "--detach", $Revision) | Out-Null

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
