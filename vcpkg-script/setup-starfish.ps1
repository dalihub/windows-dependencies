[CmdletBinding()]
param(
  # WindowsDependenciesSDK root. Defaults to <workspace>\WindowsDependenciesSDK.
  [string]$InstallPrefix = "",
  [string]$Repository = "https://github.sec.samsung.net/lws/starfish.git",
  [string]$Branch = "master",
  # Optional exact revision to pin. Empty = tip of $Branch at clone time.
  [string]$Revision = "",
  # Rebuild and reinstall even if the SDK already contains LWE.
  [switch]$Force,
  [int]$Jobs = 8
)

# Builds the LWE (Lightweight Web Engine / Starfish) SDK for Windows x64
# Release and installs it into the WindowsDependenciesSDK:
#   include\LWEWebView.h (+LWEWorker.h, PlatformIntegrationData.h)
#   lib\Starfish.lib
#   bin\Starfish.dll (+ Starfish.pdb)
#
# The official Starfish Windows build is x86-only; this script builds x64 by
# taking third-party dependencies from the SDK's vcpkg instead of the vendored
# Win32 binaries. It automates, in order:
#   A) vcpkg ports: openssl / libwebsockets / glew (with the port fixes the
#      old vcpkg snapshot needs), installed release-only
#   B) sources: clone + submodules + the x64 patches shipped in
#      lwe-web-engine-plugin\patches + python3/jinja2/ply for the binding
#      generator
#   C) CMake (VS 2022, x64, Release) build of starfish.shared_library and
#      installation into the SDK
#
# Vendoring the LWE sources or binaries in this repository is not allowed;
# the engine is always cloned and built from $Repository.
#
# Prerequisites: VS2022 (C++ desktop), git, Python 3 + pip, and access to
# github.sec.samsung.net. Safe to re-run: every step is skipped when its
# output already exists.

$ErrorActionPreference = "Stop"
$ScriptRoot = $PSScriptRoot
$WindowsDependenciesRoot = Split-Path -Parent $ScriptRoot
$WorkspaceRoot = Split-Path -Parent $WindowsDependenciesRoot
if(-not $InstallPrefix)
{
  $InstallPrefix = Join-Path $WorkspaceRoot "WindowsDependenciesSDK"
}
$VcpkgRoot = Join-Path $InstallPrefix "vcpkg"
$VcpkgExe = Join-Path $VcpkgRoot "vcpkg.exe"
$VcpkgInstalled = Join-Path $VcpkgRoot "installed\x64-windows"
$DepsRoot = Join-Path $WindowsDependenciesRoot ".deps"
$SourceRoot = Join-Path $DepsRoot "starfish"
$PatchDir = Join-Path $WindowsDependenciesRoot "lwe-web-engine-plugin\patches"

function Write-Step([string]$Message)
{
  Write-Host "`n=== LWE: $Message ===" -ForegroundColor Cyan
}

function Invoke-Git([string[]]$Arguments)
{
  & git @Arguments
  if($LASTEXITCODE -ne 0)
  {
    throw "git $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
  }
}

# Applies a git patch once: skipped when already applied (reverse-check).
function Invoke-GitPatch([string]$RepoDir, [string]$PatchPath)
{
  if(-not (Test-Path -LiteralPath $PatchPath))
  {
    throw "Patch not found: $PatchPath"
  }
  & git -C $RepoDir apply --reverse --check $PatchPath 2>$null
  if($LASTEXITCODE -eq 0)
  {
    Write-Host "  already applied: $(Split-Path -Leaf $PatchPath)"
    return
  }
  Invoke-Git @("-C", $RepoDir, "apply", "-3", $PatchPath)
  Write-Host "  applied: $(Split-Path -Leaf $PatchPath)"
}

# ---------------------------------------------------------------------------
# 0) Skip everything if the SDK already has LWE.
# ---------------------------------------------------------------------------
$LweHeader = Join-Path $InstallPrefix "include\LWEWebView.h"
$LweLib    = Join-Path $InstallPrefix "lib\Starfish.lib"
$LweDll    = Join-Path $InstallPrefix "bin\Starfish.dll"
if(-not $Force -and (Test-Path $LweHeader) -and (Test-Path $LweLib) -and (Test-Path $LweDll))
{
  Write-Host "LWE SDK already present in $InstallPrefix (use -Force to rebuild)." -ForegroundColor Green
  exit 0
}

if(-not (Test-Path -LiteralPath $VcpkgExe))
{
  throw "vcpkg not found: $VcpkgExe. Run install.ps1 (SDK setup) first."
}

# ---------------------------------------------------------------------------
# A) vcpkg ports LWE needs beyond dali's own set.
# ---------------------------------------------------------------------------
Write-Step "vcpkg ports (openssl / libwebsockets / glew)"
$VcpkgLibDir = Join-Path $VcpkgInstalled "lib"
$PortsReady = (Test-Path (Join-Path $VcpkgLibDir "libeay32.lib")) -and
              (Test-Path (Join-Path $VcpkgLibDir "websockets.lib")) -and
              (Test-Path (Join-Path $VcpkgLibDir "glew32.lib"))
if($PortsReady)
{
  Write-Host "  already installed."
}
else
{
  # Fix 1: this vcpkg snapshot's OpenSSL (1.0.2) generates asm that modern
  # nasm rejects; build it without asm on x64.
  $OpensslPort = Join-Path $VcpkgRoot "ports\openssl-windows\portfile.cmake"
  $Content = Get-Content -LiteralPath $OpensslPort -Raw
  if($Content -notmatch "no-asm")
  {
    $Anchor = 'set(OPENSSL_DO "ms\\do_win64a.bat")'
    if(-not $Content.Contains($Anchor))
    {
      throw "openssl portfile anchor not found; port layout changed?"
    }
    $Insert = $Anchor + "`r`n" +
      "    # Modern nasm rejects the asm this old OpenSSL generates; build without asm." + "`r`n" +
      "    set(CONFIGURE_COMMAND `${CONFIGURE_COMMAND}" + "`r`n" +
      "        no-asm" + "`r`n" +
      "    )"
    Set-Content -LiteralPath $OpensslPort -Value ($Content.Replace($Anchor, $Insert)) -NoNewline
    Write-Host "  patched openssl portfile (no-asm)."
  }

  # Fix 2: the libwebsockets portfile reads the debug targets file
  # unconditionally, which does not exist in a release-only install.
  $LwsPort = Join-Path $VcpkgRoot "ports\libwebsockets\portfile.cmake"
  $Content = Get-Content -LiteralPath $LwsPort -Raw
  if($Content -notmatch [regex]::Escape("if(EXISTS `${CURRENT_PACKAGES_DIR}/share/libwebsockets/LibwebsocketsTargets-debug.cmake)"))
  {
    $DebugRead = 'file(READ ${CURRENT_PACKAGES_DIR}/share/libwebsockets/LibwebsocketsTargets-debug.cmake LIBWEBSOCKETSTARGETSDEBUG_CMAKE)'
    $DebugWrite = 'file(WRITE ${CURRENT_PACKAGES_DIR}/share/libwebsockets/LibwebsocketsTargets-debug.cmake "${LIBWEBSOCKETSTARGETSDEBUG_CMAKE}")'
    if($Content.Contains($DebugRead) -and $Content.Contains($DebugWrite))
    {
      $Content = $Content.Replace($DebugRead,
        'if(EXISTS ${CURRENT_PACKAGES_DIR}/share/libwebsockets/LibwebsocketsTargets-debug.cmake)' + "`r`n" + $DebugRead)
      $Content = $Content.Replace($DebugWrite, $DebugWrite + "`r`n" + 'endif()')
      Set-Content -LiteralPath $LwsPort -Value $Content -NoNewline
      Write-Host "  patched libwebsockets portfile (release-only guard)."
    }
  }

  # Fix 3: install release-only (the OpenSSL debug build cannot be produced at
  # all), by temporarily marking the triplet. Reverted afterwards.
  $Triplet = Join-Path $VcpkgRoot "triplets\x64-windows.cmake"
  $TripletOriginal = Get-Content -LiteralPath $Triplet -Raw
  if($TripletOriginal -notmatch "VCPKG_BUILD_TYPE")
  {
    Set-Content -LiteralPath $Triplet -Value ($TripletOriginal.TrimEnd() + "`r`n" + "set(VCPKG_BUILD_TYPE release)" + "`r`n") -NoNewline
  }
  try
  {
    Write-Host "  installing (openssl takes 10-20 minutes)..."
    & $VcpkgExe install openssl:x64-windows libwebsockets:x64-windows glew:x64-windows
    if($LASTEXITCODE -ne 0)
    {
      throw "vcpkg install failed with exit code $LASTEXITCODE"
    }
  }
  finally
  {
    Set-Content -LiteralPath $Triplet -Value $TripletOriginal -NoNewline
  }
}

# ---------------------------------------------------------------------------
# B) Starfish sources: clone + submodules + x64 patches + python tooling.
# ---------------------------------------------------------------------------
Write-Step "Starfish sources"
New-Item -ItemType Directory -Force -Path $DepsRoot | Out-Null
if(-not (Test-Path (Join-Path $SourceRoot ".git")))
{
  Invoke-Git @("clone", "--branch", $Branch, $Repository, $SourceRoot)
}
if($Revision)
{
  Invoke-Git @("-C", $SourceRoot, "fetch", "origin", $Revision)
  Invoke-Git @("-C", $SourceRoot, "checkout", $Revision)
}

Invoke-Git @("-C", $SourceRoot, "submodule", "update", "--init", "--depth", "1",
  "third_party/escargot", "binding_generator", "third_party/clipper",
  "third_party/skia_matrix", "third_party/earcut.hpp", "third_party/robin_map",
  "third_party/rapidxml", "third_party/MP4Parse", "third_party/webm")
$EscargotRoot = Join-Path $SourceRoot "third_party\escargot"
Invoke-Git @("-C", $EscargotRoot, "submodule", "update", "--init", "--depth", "1", "third_party/GCutil")
$GCutilRoot = Join-Path $EscargotRoot "third_party\GCutil"
if(-not (Test-Path (Join-Path $GCutilRoot "CMakeLists.txt")))
{
  # Shallow submodule checkouts occasionally leave the tree unpopulated.
  Invoke-Git @("-C", $GCutilRoot, "checkout", "-f", "HEAD")
}

Write-Host "applying x64 patches from lwe-web-engine-plugin\patches"
Invoke-GitPatch $SourceRoot   (Join-Path $PatchDir "starfish-0001-x64-vcpkg-build-and-windows-thread-mode.patch")
Invoke-GitPatch $EscargotRoot (Join-Path $PatchDir "escargot-0001-skip-unumrf-on-windows-system-icu.patch")

# Python for the binding generator: needs `python3` on PATH with jinja2 + ply.
$Python = Get-Command python -ErrorAction SilentlyContinue
if(-not $Python)
{
  throw "python was not found on PATH. Install Python 3 and pip."
}
& python -c "import jinja2, ply" 2>$null
if($LASTEXITCODE -ne 0)
{
  Write-Host "  installing python modules jinja2 + ply..."
  & python -m pip install jinja2 ply 2>$null
  if($LASTEXITCODE -ne 0)
  {
    # Corporate proxies commonly break pip's TLS verification.
    & python -m pip install jinja2 ply --trusted-host=pypi.org --trusted-host=files.pythonhosted.org
    if($LASTEXITCODE -ne 0)
    {
      throw "pip install jinja2 ply failed."
    }
  }
}
if(-not (Get-Command python3 -ErrorAction SilentlyContinue))
{
  $ShimDir = Join-Path $DepsRoot "py3shim"
  New-Item -ItemType Directory -Force -Path $ShimDir | Out-Null
  Copy-Item -LiteralPath $Python.Source -Destination (Join-Path $ShimDir "python3.exe") -Force
  $env:PATH = "$ShimDir;$env:PATH"
  Write-Host "  python3 shim: $ShimDir\python3.exe"
}

# ---------------------------------------------------------------------------
# C) Build (VS 2022 generator, x64 Release) and install into the SDK.
# ---------------------------------------------------------------------------
Write-Step "build (first build takes 20-40 minutes)"

# The SDK vcpkg's cmake 3.14 predates the VS2022 generator; require >= 3.21.
$Cmake = $null
$CmakeCmd = Get-Command cmake -ErrorAction SilentlyContinue
if($CmakeCmd)
{
  $VersionText = (& $CmakeCmd.Source --version | Select-Object -First 1) -replace "[^0-9.]", ""
  if([Version]$VersionText -ge [Version]"3.21")
  {
    $Cmake = $CmakeCmd.Source
  }
}
if(-not $Cmake)
{
  $VsWhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
  if(Test-Path -LiteralPath $VsWhere)
  {
    $VsInstall = & $VsWhere -latest -products * `
      -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
      -property installationPath | Select-Object -First 1
    if($VsInstall)
    {
      $Candidate = Join-Path $VsInstall "Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
      if(Test-Path -LiteralPath $Candidate)
      {
        $Cmake = $Candidate
      }
    }
  }
}
if(-not $Cmake)
{
  throw "CMake >= 3.21 was not found (PATH or the VS2022-bundled CMake)."
}
Write-Host "  cmake: $Cmake"

$BuildDir = Join-Path $SourceRoot "out_win64"
Push-Location $SourceRoot
try
{
  & $Cmake -G "Visual Studio 17 2022" -A x64 `
    -DHOST=windows -DARCH=x64 -DMODE=release `
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 `
    -DVCPKG_INSTALLED_DIR="$($VcpkgInstalled -replace '\\', '/')" `
    -B out_win64
  if($LASTEXITCODE -ne 0) { throw "Starfish CMake configure failed." }

  & $Cmake --build out_win64 --config Release --target starfish.shared_library -- /m
  if($LASTEXITCODE -ne 0) { throw "Starfish build failed." }
}
finally
{
  Pop-Location
}

Write-Step "install into $InstallPrefix"
$BuiltDll = Join-Path $BuildDir "Release\Starfish.dll"
$BuiltLib = Join-Path $BuildDir "Release\Release\Starfish.lib"
$BuiltPdb = Join-Path $BuildDir "Release\Release\Starfish.pdb"
foreach($Required in @($BuiltDll, $BuiltLib))
{
  if(-not (Test-Path -LiteralPath $Required))
  {
    throw "Expected build output missing: $Required"
  }
}
Copy-Item (Join-Path $SourceRoot "inc\*.h") (Join-Path $InstallPrefix "include\") -Force
Copy-Item $BuiltLib (Join-Path $InstallPrefix "lib\") -Force
Copy-Item $BuiltDll (Join-Path $InstallPrefix "bin\") -Force
if(Test-Path -LiteralPath $BuiltPdb)
{
  Copy-Item $BuiltPdb (Join-Path $InstallPrefix "bin\") -Force
}

Write-Host "`nLWE (Starfish) SDK installed in $InstallPrefix." -ForegroundColor Green
Write-Host "Known limitation: the JS WebSocket API is disabled (vcpkg libwebsockets 3.2 < required 4.x)."
