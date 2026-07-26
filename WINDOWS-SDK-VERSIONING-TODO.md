# Windows Dependencies SDK versioning TODO

The initial distribution channel uses a single GitHub prerelease named
`windows-sdk-latest`. The scheduled Windows build replaces its SDK assets only
when the build inputs or produced SDK contents differ from the currently
published assets.

Before publishing stable SDK releases, decide and document the following:

- Define the SDK version format and its relationship to DALi core, adaptor, and
  UI versions.
- Decide whether the vcpkg revision, patch set, compiler toolset, Windows SDK,
  architecture, and build configuration are encoded in the version or only in
  a machine-readable manifest.
- Define compatibility rules between `WindowsDependenciesSDK` and DALi source
  revisions.
- Add a version and build-input manifest inside every SDK archive.
- Decide when `windows-sdk-latest` is promoted to an immutable release such as
  `windows-sdk-v1.0.0`.
- Define retention and rollback rules for immutable releases.
- Define how security fixes in third-party dependencies trigger a new SDK
  release.
- Decide whether the internal TizenVG extension has an independent version and
  compatibility manifest.
- Add checksum signing or release signing in addition to the SHA-256 file.
- Document the migration and deprecation policy for applications consuming an
  older SDK.
