param(
  [ValidateSet("Debug", "Release")]
  [string]$Configuration = "Release"
)

$DaliPrefix = [IO.Path]::GetFullPath($PSScriptRoot)
$WorkspaceRoot = Split-Path -Parent $DaliPrefix
$SdkRoot = Join-Path $WorkspaceRoot "WindowsDependenciesSDK"
$VcpkgRoot = Join-Path $SdkRoot "vcpkg"

if(-not (Test-Path -LiteralPath $SdkRoot))
{
  throw "WindowsDependenciesSDK was not found beside dali-env: $SdkRoot"
}

$RuntimePaths = @(
  (Join-Path $DaliPrefix "bin"),
  (Join-Path $DaliPrefix "lib"),
  (Join-Path $SdkRoot "bin"),
  (Join-Path $SdkRoot "lib"),
  $(if($Configuration -eq "Debug") { Join-Path $VcpkgRoot "installed\x64-windows\debug\bin" }),
  (Join-Path $VcpkgRoot "installed\x64-windows\bin")
) | Where-Object { Test-Path -LiteralPath $_ }
$ExistingPaths = @($env:PATH -split ';' | Where-Object { $_ })
$env:PATH = (@($RuntimePaths) + $ExistingPaths | Select-Object -Unique) -join ';'
$env:DALI_WINDOWS_SDK_ROOT = $SdkRoot
$env:DALI_PREFIX = $DaliPrefix
$env:VCPKG_ROOT = $VcpkgRoot
$env:DALI_CONFIGURATION = $Configuration
$env:DESKTOP_PREFIX = $DaliPrefix
$env:DALI_DATA_RO_DIR = "$DaliPrefix\share\dali"
$env:DALI_DATA_RW_DIR = "$DaliPrefix\share\dali"
$env:DALI_DATA_RO_INSTALL_DIR = "$DaliPrefix\share\dali"
$env:FONTCONFIG_FILE = "$DaliPrefix\share\dali\fonts.conf"

Write-Host "DALi runtime environment configured."
Write-Host "  SDK:    $SdkRoot"
Write-Host "  Prefix: $DaliPrefix"
Write-Host "  Config: $Configuration"
