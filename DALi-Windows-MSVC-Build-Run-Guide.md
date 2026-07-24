# DALi Windows MSVC Build & Run Guide

This document is for users who have cloned the following four repositories into the same folder.

```text
<workspace>\
  windows-dependencies\
  dali-core\
  dali-adaptor\
  dali-ui\
```

Users do not need to configure CMake options, Visual Studio paths, or install paths themselves.
The scripts included in `windows-dependencies` automatically locate the sibling repositories and
build tools, and check the required order and artifacts.

Verified configuration:

- Windows x64
- Visual Studio 2022, MSVC v143
- CMake + Ninja
- Release
- GLES/ANGLE
- vcpkg `x64-windows`

Debug, x86, MinGW, and Vulkan are currently out of scope for the scripts.

## 1. Prerequisites

Install the following from the Visual Studio Installer.

- Visual Studio 2022 or Build Tools 2022
- `Desktop development with C++`
- MSVC v143 x64/x86 build tools
- Windows 10 or Windows 11 SDK
- CMake tools for Windows

Git for Windows is also required. Python, Meson, and Ninja do not need to be installed separately.

In PowerShell, move to `windows-dependencies` and allow local script execution for the current
PowerShell session.

```powershell
Set-Location .\windows-dependencies
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

## 2. Environment information users can provide

Most users do not need to set anything.

### proxy

An existing `HTTPS_PROXY` or `HTTP_PROXY` is used automatically. If you need to set one manually,
run the following two lines before building.

```powershell
$env:HTTPS_PROXY = Read-Host "Enter the proxy address in http://host:port format"
$env:HTTP_PROXY = $env:HTTPS_PROXY
```

### vcpkg location

The default location is `.deps\vcpkg` inside the folder containing the four repositories. Set this
only if you need to use a different location.

```powershell
$env:DALI_VCPKG_ROOT = Read-Host "Enter the full path where vcpkg should be installed"
```

## 3. Building DALi

Run the scripts in the order below. Each command performs path discovery, MSVC x64 environment
setup, configure, build, install, and result verification, and stops immediately on failure.

### Samsung internal network

```powershell
.\build_windows_dependencies.ps1
.\build_dali_core.ps1
.\build_dali_adaptor.ps1
.\build_dali_ui.ps1
```

The first command performs two tasks at once.

1. Installs vcpkg third-party packages and the internal TizenVG
2. Builds and installs `windows-dependencies`, the DALi Windows compatibility package

Repositories used:

- vcpkg: `https://github.com/dalihub/vcpkg.git`
- TizenVG: `https://github.sec.samsung.net/tizen/tizenvg.git`

The TizenVG repository is only accessible from the Samsung internal network.

### External network

Outside the internal network, simply add `-SkipTizenVg` to the first command.

```powershell
.\build_windows_dependencies.ps1 -SkipTizenVg
.\build_dali_core.ps1
.\build_dali_adaptor.ps1
.\build_dali_ui.ps1
```

Without TizenVG, `build_dali_adaptor.ps1` automatically selects `thorvg_support=OFF`.
Regular DALi and static SVG still build, and SVG falls back to the NanoSVG renderer. CanvasRenderer
and the built-in Lottie renderer are unavailable.

### Optional options

To control CPU usage, pass `-Jobs` to each script.

```powershell
.\build_dali_core.ps1 -Jobs 4
```

If third-party installation is already done and you only need to rebuild `windows-dependencies`,
run:

```powershell
.\build_windows_dependencies.ps1 -SkipThirdParty
```

## 4. Building and running dali-ui samples

The default is the `hello-world` sample.

```powershell
.\build_dali_samples.ps1
.\run_dali_sample.ps1 hello-world.example
```

You can also select multiple sample directories.

```powershell
.\build_dali_samples.ps1 -Samples hello-world,chart-view
.\run_dali_sample.ps1 chart-view.example
```

Example of building the Lottie sample after installing the internal TizenVG:

```powershell
.\build_dali_samples.ps1 `
  -Samples image-view `
  -ImageViewTargets lottie-animation-view.example

.\run_dali_sample.ps1 lottie-animation-view.example
```

Window size can be specified as a run argument.

```powershell
.\run_dali_sample.ps1 hello-world.example -Width 1920 -Height 1080
```

The run script automatically sets up `PATH`, the DALi data path, and the Fontconfig path.

## 5. Rebuilding and resetting

After modifying code, only re-run the scripts starting from the affected project onward.

- core changes: core → adaptor → ui
- adaptor changes: adaptor → ui
- ui changes: ui
- sample changes: sample

Re-running the scripts reuses the existing CMake/Ninja build tree and dependency cache.
Re-running the same command after a download failure is the fastest way to recover.

Only when reinstalling completely from scratch, close all running DALi apps first and then delete
the following artifacts. This command does not delete the four repositories themselves.

```powershell
$Workspace = Split-Path -Parent (Get-Location).Path
Remove-Item -LiteralPath `
  "$Workspace\out", `
  "$Workspace\dali-env", `
  "$Workspace\tizenvg", `
  "$Workspace\.deps" `
  -Recurse -Force -ErrorAction SilentlyContinue
```

`windows-dependencies\build` is a CMake source directory despite its name, so do not delete it.

## 6. Troubleshooting

### GitHub or package download is slow

Re-run the same command. The install scripts abort a connection if the transfer speed stays below
1 KiB/s for 10 seconds, and retry up to 10 times. Existing downloads and the package cache are
preserved.

### proxy or certificate errors

- Check `HTTPS_PROXY` and `HTTP_PROXY`.
- Do not disable TLS verification.
- Install your company's TLS inspection certificate into Windows' trusted root certification
  authorities.

### `cl.exe`, CMake, or Ninja not found

Check that v143 C++ build tools, the Windows SDK, and CMake tools are installed via the Visual
Studio Installer. The scripts use `vswhere.exe` to locate Visual Studio automatically.

### Error saying a prerequisite package is missing

Run the scripts in section 3 in order from top to bottom. Each script stops with the name of the
script you need to run first if a required prior step is missing.

### `Access denied` during install

Close all running DALi samples and any processes using DALi DLLs, then re-run the same build
command.

### DLL not found or `0xc000007b`

Do not run the EXE directly — use `run_dali_sample.ps1`. This script automatically adds the x64 DLL
paths for DALi and vcpkg.

### Fontconfig errors

Run `build_windows_dependencies.ps1` first, and run samples with `run_dali_sample.ps1`. Both
scripts handle `fonts.conf` installation and the `FONTCONFIG_FILE` setting.

### Error saying the TizenVG install is incomplete

On the internal network, re-run `build_windows_dependencies.ps1`. In a clean external environment,
start with `build_windows_dependencies.ps1 -SkipTizenVg`.

## 7. Generated directories

```text
<workspace>\
  .deps\vcpkg\       # vcpkg checkout and packages
  tizenvg\            # created only on the internal network
  out\                # CMake/Meson build tree
  dali-env\           # final DLLs, LIBs, headers, resources, samples
```
