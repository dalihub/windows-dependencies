[CmdletBinding()]
param(
  [ValidateSet("Inputs", "Contents")]
  [string]$Mode,
  [Parameter(Mandatory = $true)]
  [string]$OutputPath,
  [string]$SdkRoot = ""
)

$ErrorActionPreference = "Stop"
$ScriptRoot = $PSScriptRoot

if($Mode -eq "Inputs")
{
  $TrackedFiles = @(& git.exe -C $ScriptRoot ls-files -- `
    "build" "include" "resources" "src" "vcpkg-script" `
    "build_windows_dependencies.ps1" "package_windows_sdk.ps1")
  if($LASTEXITCODE -ne 0)
  {
    throw "Unable to enumerate SDK build inputs."
  }

  $Files = foreach($RelativePath in ($TrackedFiles | Sort-Object -Unique))
  {
    $FullPath = Join-Path $ScriptRoot $RelativePath
    if(Test-Path -LiteralPath $FullPath -PathType Leaf)
    {
      [ordered]@{
        path = $RelativePath.Replace('\', '/')
        sha256 = (Get-FileHash -LiteralPath $FullPath -Algorithm SHA256).Hash.ToLowerInvariant()
      }
    }
  }

  $VsVersion = "unknown"
  $VsWhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
  if(Test-Path -LiteralPath $VsWhere)
  {
    $DetectedVsVersion = & $VsWhere -latest -products * -property catalog_productDisplayVersion
    if($DetectedVsVersion) { $VsVersion = "$DetectedVsVersion".Trim() }
  }

  $Manifest = [ordered]@{
    schema = 1
    architecture = "x64"
    configuration = "Release"
    runner = "windows-2022"
    visualStudio = $VsVersion
    files = @($Files)
  }
}
else
{
  if(-not $SdkRoot) { throw "SdkRoot is required for a contents manifest." }
  $SdkRoot = [IO.Path]::GetFullPath($SdkRoot)
  $Files = foreach($File in (Get-ChildItem -LiteralPath $SdkRoot -File -Recurse | Sort-Object FullName))
  {
    $RelativePath = $File.FullName.Substring($SdkRoot.Length).TrimStart('\', '/')
    if($RelativePath -in @("build-inputs.json", "sdk-contents.json")) { continue }
    [ordered]@{
      path = $RelativePath.Replace('\', '/')
      size = $File.Length
      sha256 = (Get-FileHash -LiteralPath $File.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    }
  }
  $Manifest = [ordered]@{
    schema = 1
    files = @($Files)
  }
}

$OutputParent = Split-Path -Parent $OutputPath
if($OutputParent) { New-Item -ItemType Directory -Force -Path $OutputParent | Out-Null }
$Json = $Manifest | ConvertTo-Json -Depth 8
[IO.File]::WriteAllText([IO.Path]::GetFullPath($OutputPath), $Json + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
