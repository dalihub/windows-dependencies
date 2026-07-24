$DaliPrefix = $PSScriptRoot

$env:PATH = "$DaliPrefix\bin;$DaliPrefix\lib;$env:PATH"
$env:DESKTOP_PREFIX = $DaliPrefix
$env:DALI_DATA_RO_DIR = "$DaliPrefix\share\dali"
$env:DALI_DATA_RW_DIR = "$DaliPrefix\share\dali"
$env:DALI_DATA_RO_INSTALL_DIR = "$DaliPrefix\share\dali"
$env:FONTCONFIG_PATH = "$DaliPrefix\share\dali"
$env:FONTCONFIG_FILE = "$DaliPrefix\share\dali\fonts.conf"

Write-Host "DALi runtime environment configured for $DaliPrefix"
