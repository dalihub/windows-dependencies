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
SHA-256 file, and installs it as `<workspace>\WindowsDependenciesSDK`. A partial
archive is kept below `<workspace>\windows-dependencies\.deps\windows-sdk-download` and is reused
when a download resumes.

If the release is missing, cannot be downloaded, or fails validation, the same
SDK layout is built from source. Downloads and completed vcpkg packages are
reused across retries and later runs.

To test another release repository or force a source build:

```powershell
.\install.ps1 -ReleaseRepository "owner/windows-dependencies"
.\install.ps1 -BuildFromSource -Jobs 4
```

Pass `-Proxy host:port` only when the proxy is not already provided through
`HTTPS_PROXY` or `HTTP_PROXY`.

### Optional TizenVG support

The published SDK intentionally excludes TizenVG because its repository is
available only on the Samsung network. After installing the public SDK,
`install.ps1` probes the TizenVG repository automatically:

- when the repository is reachable, the pinned TizenVG revision is added to
  `WindowsDependenciesSDK`;
- when the repository is unavailable, installation continues without it;
- after the repository is reached, a TizenVG configure, build, or installation
  failure is treated as an error.

Without TizenVG, dali-adaptor builds without CanvasRenderer and Lottie support.
No separate internal/external option is required.

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

## Build and run dali-ui samples

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

Use either of the following runtime environment methods.

Apply the environment to the current PowerShell:

```powershell
cd <workspace>
. .\dali-env\setenv.ps1
& "$env:DALI_PREFIX\bin\hello-world.example.exe"
```

To set a custom window resolution:

```powershell
cd <workspace>
. .\dali-env\setenv.ps1; $env:DALI_WINDOW_WIDTH = "1920"; $env:DALI_WINDOW_HEIGHT = "1080"
& "$env:DALI_PREFIX\bin\hello-world.example.exe"
```

Or open a dedicated DALi development shell:

```powershell
cd <workspace>
.\windows-dependencies\dali-shell.ps1
```

Inside that shell, installed applications can be launched by name:

```powershell
hello-world.example.exe
```

Use `-Configuration Debug` with `setenv.ps1` or `dali-shell.ps1` when running a
Debug build. Window dimensions can be set before launch:

```powershell
$env:DALI_WINDOW_WIDTH = "1920"
$env:DALI_WINDOW_HEIGHT = "1080"
hello-world.example.exe
```

## Clean builds

For a clean rebuild of one DALi repository, use its `-Clean` option. For a full
workspace rebuild, remove the per-repository build trees, the shared `out`
directory if it exists, `dali-env`, and `WindowsDependenciesSDK`, then run
`install.ps1` again. The source-build cache below `<workspace>\windows-dependencies\.deps` is
independent and may be retained to avoid downloading and rebuilding unchanged
third-party inputs.

## Build the dependency SDK from source

Normal users should use `install.ps1`. SDK maintainers can build the public SDK
layout directly:

```powershell
cd <workspace>\windows-dependencies
.\build_windows_dependencies.ps1 -SkipTizenVg -Clean -Jobs 4
```

The command installs the relocatable dependency SDK in
`<workspace>\WindowsDependenciesSDK`. Low-level vcpkg and TizenVG details are in
[vcpkg-script/Readme.md](vcpkg-script/Readme.md).

## Automated SDK publication

`.github/workflows/windows-sdk-latest.yml` runs on a GitHub-hosted Windows 2022
runner when a push to `master` changes an SDK build input. A merged pull request
normally produces that push; documentation-only changes are ignored. Manual runs
remain available. The workflow builds the x64 Release SDK without TizenVG and
maintains the `windows-sdk-latest` prerelease.

The release contains:

```text
DALi-WindowsDependenciesSDK-x64.zip
DALi-WindowsDependenciesSDK-x64.zip.sha256
build-inputs.json
sdk-contents.json
```

When the current build inputs match the published manifest, the scheduled build
and upload are skipped. When inputs differ but the produced SDK contents remain
the same, only the input manifest is refreshed. The workflow uses the
repository-scoped `GITHUB_TOKEN` with `contents: write`; it does not require a
personal access token or a custom secret.

The workflow publishes only `WindowsDependenciesSDK`. DALi core, adaptor, UI,
and sample binaries remain source builds performed in their own repositories.
Future immutable SDK versioning is tracked in
[WINDOWS-SDK-VERSIONING-TODO.md](WINDOWS-SDK-VERSIONING-TODO.md).
