# Third-party dependency setup

Normal users should run `windows-dependencies\install.ps1`. The scripts in this
directory are the lower-level implementation used when a published SDK is not
available and by the scheduled SDK build.

## Dependency sources

The vcpkg source revision is pinned by the scripts and cloned from
`https://github.com/dalihub/vcpkg.git`.

The vcpkg setup builds the x64 Windows libraries required by the DALi backend,
including ANGLE, Cairo, Fontconfig, FreeType, HarfBuzz, gettext, image codecs,
and their transitive dependencies. It also installs native `libintl` and
`msgfmt.exe`.

Debug and Release are built separately. The selected configuration is the only
one installed in the staged SDK and its runtime DLLs are exposed below the
explicit `debug\bin` or `release\bin` directory.

## Direct maintainer use

Build the public dependency set:

```powershell
cd <workspace>\windows-dependencies\vcpkg-script
.\setup-dali-dependencies.ps1 `
  -Configuration Debug `
  -VcpkgRoot <workspace>\windows-dependencies\.deps\vcpkg `
  -Proxy host:port
```

Omit `-Proxy` when the proxy is already supplied through the environment. Use
`-Configuration Release` to replace the source vcpkg package set with Release-only
packages.

```powershell
## Network and retry behavior

GitHub clone, fetch, and download operations retry up to ten times. Git uses a
low-speed threshold instead of a total operation timeout, so a healthy large
transfer is not cancelled merely because it lasts longer than ten seconds.
Partial downloads and completed vcpkg packages are reused; a failed clone target
is removed only before a clone retry.

On Windows, source downloads use system curl with certificate and hostname
validation enabled. CRL checks that commonly fail behind a corporate TLS proxy
are skipped, but TLS verification itself remains enabled. Do not disable TLS
verification; install the approved corporate root certificate when HTTPS
inspection is used.
