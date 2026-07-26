# Third-party dependency setup

Normal users should run `windows-dependencies\install.ps1`. The scripts in this
directory are the lower-level implementation used when a published SDK is not
available and by the scheduled SDK build.

## Dependency sources

The source revisions are pinned by the scripts:

- vcpkg: `https://github.com/dalihub/vcpkg.git`
- TizenVG: `https://github.sec.samsung.net/tizen/tizenvg.git` (Samsung network
  only)

The vcpkg setup builds the x64 Windows libraries required by the DALi backend,
including ANGLE, Cairo, Fontconfig, FreeType, HarfBuzz, gettext, image codecs,
and their transitive dependencies. It also installs native `libintl` and
`msgfmt.exe`.

TizenVG is optional only when its repository cannot be reached. If it is
reachable, failures while checking out, configuring, building, or installing
the pinned revision are reported as errors.

## Direct maintainer use

Build both public dependencies and the optional internal extension:

```powershell
cd <workspace>\windows-dependencies\vcpkg-script
.\setup-dali-dependencies.ps1 `
  -DaliRoot <workspace> `
  -VcpkgRoot <workspace>\.deps\vcpkg `
  -InstallPrefix <workspace>\WindowsDependenciesSDK
```

Build only the public dependency set:

```powershell
.\setup-dali-dependencies.ps1 `
  -DaliRoot <workspace> `
  -VcpkgRoot <workspace>\.deps\vcpkg `
  -InstallPrefix <workspace>\WindowsDependenciesSDK `
  -SkipTizenVg
```

`-SkipVcpkg` reuses an already staged vcpkg SDK when only the TizenVG extension
is required. `-Proxy host:port` overrides proxy environment variables.

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

TizenVG uses the x64 Python distributed by vcpkg when possible. Its Meson/Ninja
tool environment and the pinned source checkout are reused by later runs.
