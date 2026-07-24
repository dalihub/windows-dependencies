# Instructions to build the third-party dependencies

## VS 2022 / MSVC v143 (recommended)

For the current DALi Windows backend, use `setup-dali-dependencies.ps1`. It
installs the pinned vcpkg dependencies and, inside the Samsung network, the
verified TizenVG revision used by DALi canvas and vector-animation backends.

The source repositories are fixed:

- vcpkg: `https://github.com/dalihub/vcpkg.git`
- TizenVG: `https://github.sec.samsung.net/tizen/tizenvg.git` (Samsung network only)

The vcpkg setup installs native `libintl` and `msgfmt.exe`. The latter and its
private runtime DLLs are installed below:

```text
<VcpkgRoot>\installed\x64-windows\tools\gettext
```

CMake 3.15 or newer is required because the catalog compiler package uses
Zstandard compression.

Outside the Samsung network, skip TizenVG:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\setup-dali-dependencies.ps1 `
  -DaliRoot C:\work\DALi `
  -VcpkgRoot C:\Tools\DALI_VCPKG\vcpkg `
  -SkipTizenVg
```

Inside the Samsung network, the script installs both vcpkg and TizenVG. If the
proxy is not already defined by `HTTPS_PROXY` or `HTTP_PROXY`, enter the actual
proxy address at runtime:

```powershell
$Proxy = Read-Host "Proxy address (host:port)"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\setup-dali-dependencies.ps1 `
  -DaliRoot C:\work\DALi `
  -VcpkgRoot C:\Tools\DALI_VCPKG\vcpkg `
  -Proxy $Proxy
```

If `-Proxy` is omitted, the script recognizes `HTTPS_PROXY` or `HTTP_PROXY` and
forwards it to vcpkg. Git HTTP transfers below 1 KiB/s for 10 seconds retry up
to five times. Failed partial clones are removed before retrying. vcpkg package
installation also retries up to five times and reuses its download/package
cache.

On Windows, source archives use system curl with certificate and hostname
validation enabled. Only the CRL check that fails behind the company TLS proxy
is skipped. The retry threshold is based on low transfer speed, not total
download time, so healthy large downloads are not cancelled after ten seconds.

When TizenVG needs Meson and Ninja, the script reuses vcpkg's x64 Python or a
portable local copy. It exports the Windows trusted root stores to a local PEM
bundle so pip can validate a company TLS-inspection certificate without
disabling TLS verification. Once the pinned TizenVG revision exists locally,
later runs skip the network fetch.

Use `-SkipVcpkg` to reuse an existing vcpkg installation. Use `-SkipTizenVg`
outside the Samsung network or when an existing TizenVG installation should be
reused.

Do not disable TLS verification. Install the company root certificate through
the approved IT process if HTTPS inspection is used.
The older `build-deps.sh` workflow below is retained for historical VC2017
builds. It installs legacy DALi packages and x86 dependencies, so it should not
be used for the current x64 smoke test.

## 0. Notes and troubleshootings
- Due to different architectures, platforms, configurations, etc the script might need to be modified in order to be able to install the third-party dependencies.
- It might happen that the script gets stuck downloading or building a package, usually it can be detected if in the Performance tab of the Windows Task Manager
  the CPU or the ETHERNET graphics show no activity.
  In that case restart the script again. It's safe just press ENTER when the script asks to reapply the patches.
- On the debug configuration the pthreadVC3.dll file fails to be copied into the executable folder. It can be copied manually from the vcpkg/installed folder of the
  executable folder of the release configuration. This issue needs to be investigated.

## 1. Prerequisites

- Install Visual Studio
Current instructions are for VC2017 although some users are using VC2019
  - Install Windows 10.0 SDK
  - Install MFC and ATL support(x86, x64)
  - Install 2017 v141 for Desktop
  - After installing VS please check that the license has been properly updated:
  Help →Register Product.  If this shows a trial version then click "Check for an updated license".  You should see this:
    License: MSDN Subscription
    This product is licensed to: USER.NAME@samsung.com

- Install the 'English language pack' for Visual Studio. Otherwise vcpkg is unable to find some needed tools to build the libraries.

- Install git.
The git version control can be downloaded from https://git-scm.com/download/win
Follow the instructions on the link to install it.

The git bash app will be used to run the script.

- Set a proxy ip might be needed.
The default http proxy ip is set to the one in SRUK
Use the following options as a parameter for the script to set a different proxy ip:
-p | -httpProxy | --httpProxy To set the http proxy ip. It sets as well the https one
[-s | -httpsProxy | --httpsProxy] Optional. To set the https proxy ip if it's different than the http one.
[-n] Optional. Doesn't set any proxy.

## 2. Install VCPKG
- Create a folder where to install VCPKG. Better if this forder is outside of any DALi folder. i.e C:\Tools\VCPKG
- Copy the build-deps.sh file and all the patch files to the newly created folder.
- Open a Git bash shell and run the script.

The script will clone vcpkg from github apply all the patches, build all the dependencies and integrate with Visual Studio.
