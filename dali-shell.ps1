[CmdletBinding()]
param(
  [ValidateSet("Debug", "Release")]
  [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"
$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$SetEnvScript = Join-Path $WorkspaceRoot "dali-env\setenv.ps1"
if(-not (Test-Path -LiteralPath $SetEnvScript))
{
  throw "DALi environment script was not found. Run .\install.ps1 first: $SetEnvScript"
}

$Shell = Get-Command pwsh.exe -ErrorAction SilentlyContinue
if(-not $Shell)
{
  $Shell = Get-Command powershell.exe -ErrorAction Stop
}

$EscapedSetEnv = $SetEnvScript.Replace("'", "''")
& $Shell.Source -NoExit -NoLogo -Command ". '$EscapedSetEnv' -Configuration $Configuration"
