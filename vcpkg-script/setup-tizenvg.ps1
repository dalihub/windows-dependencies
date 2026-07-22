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

Get-Command git -ErrorAction Stop | Out-Null
Get-Command meson -ErrorAction Stop | Out-Null

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

  $SourceStatus = & git -C $SourceRoot status --porcelain
  if($LASTEXITCODE -ne 0) { throw "Unable to inspect TizenVG checkout" }
  if($SourceStatus)
  {
    throw "TizenVG checkout has local changes: $SourceRoot"
  }

  Invoke-Native "git" @("-C", $SourceRoot, "fetch", "origin", "tizen")
}
else
{
  $SourceParent = Split-Path -Parent $SourceRoot
  New-Item -ItemType Directory -Force -Path $SourceParent | Out-Null
  Invoke-Native "git" @("clone", "--branch", "tizen", $Repository, $SourceRoot)
}

Invoke-Native "git" @("-C", $SourceRoot, "checkout", "--detach", $Revision)

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
)

if(Test-Path -LiteralPath (Join-Path $BuildRoot "meson-private\coredata.dat"))
{
  $MesonArguments += "--reconfigure"
}

Invoke-Native "meson" $MesonArguments
Invoke-Native "meson" @("compile", "-C", $BuildRoot)
Invoke-Native "meson" @("install", "-C", $BuildRoot)

$Header = Join-Path $InstallPrefix "include\thorvg.h"
$DllCandidates = @(
  (Join-Path $InstallPrefix "bin\thorvg.dll"),
  (Join-Path $InstallPrefix "lib\thorvg.dll")
)

if(-not (Test-Path -LiteralPath $Header))
{
  throw "TizenVG header was not installed: $Header"
}
if(-not ($DllCandidates | Where-Object { Test-Path -LiteralPath $_ }))
{
  throw "TizenVG DLL was not installed below $InstallPrefix"
}

Write-Host "TizenVG $Revision installed in $InstallPrefix"
