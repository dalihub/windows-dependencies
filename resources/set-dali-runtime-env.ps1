$Configuration = "Debug"

$DaliPrefix = [IO.Path]::GetFullPath($PSScriptRoot)
$WorkspaceRoot = Split-Path -Parent $DaliPrefix
$SdkRoot = Join-Path $WorkspaceRoot "WindowsDependenciesSDK"
$VcpkgRoot = Join-Path $SdkRoot "vcpkg"

if(-not (Test-Path -LiteralPath $SdkRoot))
{
  throw "WindowsDependenciesSDK was not found beside dali-env: $SdkRoot"
}

$VcpkgInstalledRoot = Join-Path $VcpkgRoot "installed\x64-windows"
$RuntimePaths = @(
  (Join-Path $DaliPrefix "bin"),
  (Join-Path $VcpkgInstalledRoot "$($Configuration.ToLowerInvariant())\bin")
) | Where-Object { Test-Path -LiteralPath $_ }
$ManagedPaths = @(
  (Join-Path $DaliPrefix "bin"),
  (Join-Path $DaliPrefix "lib"),
  (Join-Path $SdkRoot "bin"),
  (Join-Path $SdkRoot "lib"),
  (Join-Path $VcpkgInstalledRoot "bin"),
  (Join-Path $VcpkgInstalledRoot "debug\bin"),
  (Join-Path $VcpkgInstalledRoot "release\bin")
) | ForEach-Object { [IO.Path]::GetFullPath($_).TrimEnd('\') }
$ExistingPaths = @(
  $env:PATH -split ';' |
    Where-Object { $_ } |
    Where-Object { [IO.Path]::GetFullPath($_).TrimEnd('\') -notin $ManagedPaths }
)
$env:PATH = (@($RuntimePaths) + $ExistingPaths | Select-Object -Unique) -join ';'
$env:DALI_WINDOWS_SDK_ROOT = $SdkRoot
$env:DALI_PREFIX = $DaliPrefix
$env:VCPKG_ROOT = $VcpkgRoot
$env:DALI_CONFIGURATION = $Configuration
$env:DESKTOP_PREFIX = $DaliPrefix
$env:DALI_DATA_RO_DIR = "$DaliPrefix\share\dali"
$env:DALI_DATA_RW_DIR = "$DaliPrefix\share\dali"
$env:DALI_DATA_RO_INSTALL_DIR = "$DaliPrefix\share\dali"
$FontConfigRoot = Join-Path $SdkRoot "share\dali"
$env:FONTCONFIG_PATH = $FontConfigRoot
$env:FONTCONFIG_FILE = Join-Path $FontConfigRoot "fonts.conf"

Write-Host "DALi runtime environment configured."
Write-Host "  SDK:    $SdkRoot"
Write-Host "  Prefix: $DaliPrefix"
Write-Host "  Config: $Configuration"
