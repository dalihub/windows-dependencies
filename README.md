<img src="https://dalihub.github.io/images/DaliLogo320x200.png">

# DALi Windows dependencies

This repository provides the third-party SDK, CMake integration, and runtime
environment used by the DALi Windows backend. The current workflow targets
Visual Studio 2022, MSVC v143, x64 Windows, CMake, and Ninja.

The repositories may live below any common workspace directory. The drive and
workspace directory name are not fixed.

```text
<workspace>\
  dali-core\
  dali-adaptor\
  dali-ui\
  windows-dependencies\
  WindowsDependenciesSDK\  # installed third-party SDK
  dali-env\                 # installed DALi libraries and samples
```

For a shorter Korean guide, see
[WINDOWS-DEVELOPMENT-QUICKSTART-ko.md](WINDOWS-DEVELOPMENT-QUICKSTART-ko.md).

## Prerequisites

Install the following tools on Windows:

- Visual Studio 2022 with **Desktop development with C++** and the MSVC v143
  x64 toolset
- A Windows SDK supplied by Visual Studio
- CMake 3.15 or newer
- Ninja
- Git
- PowerShell 7 or Windows PowerShell 5.1

The build scripts locate the Visual Studio environment automatically. They do
not require a Visual Studio solution or a Developer Command Prompt.

## Install WindowsDependenciesSDK

From the `windows-dependencies` repository, run:

```powershell
cd <workspace>\windows-dependencies
.\install.ps1
```

`install.ps1` first downloads the `windows-sdk-latest` prerelease, verifies its
SHA-256 file, and installs the archive matching `-Configuration` as
`<workspace>\WindowsDependenciesSDK`. Debug is the default. Each archive contains
only its requested configuration. A partial
archive is kept below `<workspace>\windows-dependencies\.deps\windows-sdk-download` and is reused
when a download resumes.

If the release is missing, cannot be downloaded, or fails validation, the same
SDK layout is built from source. Downloads and completed vcpkg packages are
reused across retries and later runs.

To test another release repository or force a source build:

```powershell
.\install.ps1 -ReleaseRepository "owner/windows-dependencies"
.\install.ps1 -Configuration Release
.\install.ps1 -BuildFromSource -Jobs 4
```

Pass `-Proxy host:port` only when the proxy is not already provided through
`HTTPS_PROXY` or `HTTP_PROXY`.

TizenVG is not fetched or built by this repository. Internal extensions are
managed independently from the public Windows dependency SDK.

The vcpkg runtime layout is explicit in both archives:

```text
vcpkg\installed\x64-windows\debug\bin\    # Debug archive only
vcpkg\installed\x64-windows\release\bin\  # Release archive only
```

## Build DALi repositories

Build each repository from its own directory. Every command configures, builds,
and installs its project; the build tree remains in `_build\windows` and the
installed files are collected in `<workspace>\dali-env`.

```powershell
cd <workspace>\dali-core
.\build\windows\build.ps1

cd <workspace>\dali-adaptor
.\build\windows\build.ps1

cd <workspace>\dali-ui
.\build\windows\build.ps1
```

Build in dependency order: core, adaptor, then UI. Common options are:

```powershell
.\build\windows\build.ps1 -Clean
.\build\windows\build.ps1 -Configuration Debug
.\build\windows\build.ps1 -Jobs 4
```

`-Clean` removes only that repository's `_build\windows` directory before the
new configure. It does not remove `WindowsDependenciesSDK` or `dali-env`.

## Run dali-ui samples

The sample script also configures, builds, and installs its targets into
`dali-env\bin`.

```powershell
cd <workspace>\dali-ui\samples
.\build.ps1
```

Build selected samples or start with a clean sample build tree:

```powershell
.\build.ps1 -Samples hello-world,text
.\build.ps1 -Clean -Samples hello-world
```

To run samples, apply the runtime environment to your PowerShell session:

```powershell
cd <workspace>
. .\dali-env\setenv.ps1
& "$env:DALI_PREFIX\bin\hello-world.example.exe"
```

This environment setup is required every time you open a new PowerShell terminal.

To set a custom window resolution before running an application:

```powershell
cd <workspace>
. .\dali-env\setenv.ps1
$env:DALI_WINDOW_WIDTH = "1920"
$env:DALI_WINDOW_HEIGHT = "1080"
& "$env:DALI_PREFIX\bin\hello-world.example.exe"
```

`setenv.ps1` is generated for the installed SDK configuration, so switching
configuration requires installing and rebuilding that configuration first.

## Clean builds

For a clean rebuild of one DALi repository, use its `-Clean` option. For a full
workspace rebuild, remove the per-repository build trees, the shared `out`
directory if it exists, `dali-env`, and `WindowsDependenciesSDK`, then run
`install.ps1` again. The source-build cache below `<workspace>\windows-dependencies\.deps` is
independent and may be retained to avoid downloading and rebuilding unchanged
third-party inputs.

## Building with AddressSanitizer (ASAN)

AddressSanitizer detects memory errors such as buffer overflows, use-after-free,
and heap corruption. The `-EnableASAN` switch instruments all native libraries
with `/fsanitize=address`.

### Prerequisites

- Visual Studio 2022 with MSVC v143 (ASAN is built into MSVC; no separate
  runtime installation is needed)
- Debug configuration is recommended for ASAN builds

### Build order

ASAN requires every library in the link chain to be compiled with the same
sanitizer flags. `-EnableASAN` on `install.ps1` automatically forces a source
build because the pre-built published SDK is not ASAN-instrumented.

```powershell
# 1. Build windows-dependencies with ASAN (forces source build)
cd <workspace>\windows-dependencies
.\install.ps1 -EnableASAN -Configuration Debug

# 2. Build dali-core with ASAN
cd <workspace>\dali-core
.\build\windows\build.ps1 -Configuration Debug -EnableASAN -Clean

# 3. Build dali-adaptor with ASAN
cd <workspace>\dali-adaptor
.\build\windows\build.ps1 -Configuration Debug -EnableASAN -Clean

# 4. Build dali-ui with ASAN
cd <workspace>\dali-ui
.\build\windows\build.ps1 -Configuration Debug -EnableASAN -Clean
```

### Build and run automated tests (UTC) with ASAN

```powershell
# Build and run dali-core UTCs
cd <workspace>\dali-core\automated-tests
.\build.ps1 -Configuration Debug -EnableASAN -Clean
.\execute.ps1 -Configuration Debug

# Build and run dali-adaptor UTCs
cd <workspace>\dali-adaptor\automated-tests
.\build.ps1 -Configuration Debug -EnableASAN -Clean
.\execute.ps1 -Configuration Debug

# Build and run dali-ui UTCs
cd <workspace>\dali-ui\automated-tests
.\build.ps1 -Configuration Debug -EnableASAN -Clean
.\execute.ps1 -Configuration Debug
```

The `execute.ps1` script automatically copies `clang_rt.asan_dynamic-x86_64.dll`
to the test executable directory so that ASAN can report source locations.

When ASAN detects a memory error, the test process prints a diagnostic report
to stderr and exits with a non-zero code. Test results and logs are written to
`automated-tests\results\windows\<timestamp>\`.

## Build the dependency SDK from source

Normal users should use `install.ps1`. SDK maintainers can build the public SDK
layout directly:

```powershell
cd <workspace>\windows-dependencies
.\build_windows_dependencies.ps1 -Configuration Debug -Clean -Jobs 4
```

The command installs the relocatable dependency SDK in
`<workspace>\WindowsDependenciesSDK`. Low-level vcpkg details are in
[vcpkg-script/Readme.md](vcpkg-script/Readme.md).

## Automated SDK publication

`.github/workflows/windows-sdk-latest.yml` runs on a GitHub-hosted Windows 2022
runner when a push to `master` changes an SDK build input. A merged pull request
normally produces that push; documentation-only changes are ignored. Manual runs
remain available. The workflow builds separate configuration-only x64 Debug
and Release SDKs and maintains the `windows-sdk-latest` prerelease.

The release contains:

```text
DALi-WindowsDependenciesSDK-x64-Debug.zip
DALi-WindowsDependenciesSDK-x64-Debug.zip.sha256
DALi-WindowsDependenciesSDK-x64-Release.zip
DALi-WindowsDependenciesSDK-x64-Release.zip.sha256
build-inputs-Debug.json / build-inputs-Release.json
sdk-contents-Debug.json / sdk-contents-Release.json
```

When the current build inputs match the published manifest, the workflow build
and upload are skipped. When inputs differ but the produced SDK contents remain
the same, only the input manifest is refreshed. The workflow uses the
repository-scoped `GITHUB_TOKEN` with `contents: write`; it does not require a
personal access token or a custom secret.

The workflow publishes only `WindowsDependenciesSDK`. DALi core, adaptor, UI,
and sample binaries remain source builds performed in their own repositories.
