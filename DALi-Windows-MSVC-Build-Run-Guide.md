# DALi Windows MSVC 빌드 및 sample 실행 가이드

이 문서는 Windows에서 `windows-dependencies`, `dali-core`, `dali-adaptor`, `dali-ui`를
MSVC로 순서대로 빌드하고 선택한 `dali-ui/samples` 앱을 실행하는 검증된 절차다.
사외 직접 인터넷 환경과 사내 proxy/mirror 환경을 구분하며, 다른 개발자나 자동화 도구도
위에서 아래로 그대로 실행할 수 있도록 필요한 revision, 명령, 성공 기준을 함께 기록한다.

## 1. 검증된 구성

2026-07-22에 다음 구성으로 end-to-end smoke test를 완료했다.

| 항목 | 검증값 |
|---|---|
| OS/architecture | Windows x64 |
| Visual Studio | Build Tools 2022 17.14.36 |
| compiler/toolset | MSVC 19.44, v143 14.44.35207 |
| Windows SDK | 10.0.26100 |
| generator | Ninja 1.12.1 |
| CMake | 3.31.6 |
| Python | 3.14.3 |
| build type | Release |
| graphics backend | GLES/ANGLE, OpenGL ES 3.0 |
| vcpkg triplet | `x64-windows` |

검증에 사용한 주요 revision은 다음과 같다.

```text
dali-core           aa7e686ee  Improve Windows compiler compatibility
dali-adaptor        25b498266  Improve Windows backend support
dali-ui             de82cd00   Windows Backend
windows-dependencies 4377dc1   Update for 2022 MSVC
dalihub/vcpkg       a58936506  (반드시 이 revision으로 고정)
```

Debug, x86, MinGW, Vulkan 또는 최신 upstream vcpkg를 섞지 않는다. 첫 검증은 위 조합을
그대로 사용한다.

### 1.1 패치가 아직 merge되지 않았을 때

2026-07-22 기준 patch 위치는 다음과 같다. 각 변경이 대상 branch에 merge된 뒤에는 이
절차를 생략하고 최신 대상 branch를 사용한다.

| 저장소 | patch 위치 |
|---|---|
| `dali-core` | Gerrit change [348534](https://review.tizen.org/gerrit/c/platform/core/uifw/dali-core/+/348534), patchset 2 |
| `dali-adaptor` | Gerrit change [348535](https://review.tizen.org/gerrit/c/platform/core/uifw/dali-adaptor/+/348535), patchset 2 |
| `dali-ui` | `bshsqa/dali-ui`의 `WindowsBackend` branch |
| `windows-dependencies` | draft PR [#51](https://github.com/dalihub/windows-dependencies/pull/51) |

이미 각 patch가 적용된 checkout을 전달받았다면 다시 cherry-pick하지 않는다. Gerrit origin을
사용하는 checkout에서는 다음처럼 정확한 patchset을 받을 수 있다.

```powershell
git -C C:/work/DALi/dali-core fetch origin refs/changes/34/348534/2
git -C C:/work/DALi/dali-core cherry-pick FETCH_HEAD

git -C C:/work/DALi/dali-adaptor fetch origin refs/changes/35/348535/2
git -C C:/work/DALi/dali-adaptor cherry-pick FETCH_HEAD
```

GitHub branch와 PR head를 직접 받는 경우는 다음과 같다.

```powershell
git -C C:/work/DALi/dali-ui fetch `
  https://github.com/bshsqa/dali-ui.git WindowsBackend
git -C C:/work/DALi/dali-ui switch --detach FETCH_HEAD

git -C C:/work/DALi/windows-dependencies fetch `
  https://github.com/bshsqa/windows-dependencies.git agent/windows-msvc-build-support
git -C C:/work/DALi/windows-dependencies switch --detach FETCH_HEAD
```

## 2. 기존 가이드에서 추가된 필수 수정

현재 작업 트리에는 아래 수정이 반영돼 있다. 다른 branch나 새 checkout에서 빌드한다면
이 변경도 함께 commit/cherry-pick해야 한다.

| 저장소 | 보완 내용 |
|---|---|
| `windows-dependencies` | MSVC에서 GCC `__sync_*` builtin을 Interlocked API로 제공 |
| `windows-dependencies` | proxy IP 하드코딩 제거, `VCPKG_PROXY` 기반 처리 및 proxy 미사용 경로의 handle shadowing 수정 |
| `windows-dependencies` | 구형 vcpkg의 VS 2022/v143, 한국어 VS 설치, x64 Meson, 현재 giflib URL 지원 patch 추가 |
| `windows-dependencies` | Windows 시스템 글꼴용 최소 `fonts.conf`를 `share/dali`에 설치 |
| `dali-core` | C++20 designated initializer를 C++17 aggregate 초기화로 변경 |
| `dali-core` | public `SharedPtr` 사용자가 MSVC `__sync_*` 호환 구현을 볼 수 있도록 보완 |
| `dali-core` | Windows에서 uniform hash가 32비트로 잘리지 않도록 `UniformPropertyMapping::Hash`를 `std::size_t`로 변경 |
| `dali-adaptor` | Windows에서 `AddOnManagerFactory` factory symbol을 실제 static member로 정의 |
| `dali-ui` | MSVC에 `/vmg`와 `__restrict__=__restrict` 적용 |
| `dali-ui` | Python autogen 파일 입출력을 UTF-8로 고정하여 CP949 decode 오류 방지 |
| `dali-ui` | 생성 shader 문자열을 8,000 byte 단위 literal로 분할하여 MSVC C2026 방지 |
| `dali-ui` | `SelectableLottieImage::FrameRange` 생성자를 foundation DLL에서 명시적으로 export |
| `dali-ui/samples` | library와 callback member-pointer ABI를 맞추기 위해 `/vmg` 적용 |

관련 working tree는 다음 명령으로 확인한다.

```powershell
git -C C:/work/DALi/windows-dependencies status --short
git -C C:/work/DALi/dali-core status --short
git -C C:/work/DALi/dali-adaptor status --short
git -C C:/work/DALi/dali-ui status --short
```

특히 sample의 `/vmg`를 빼면 빌드는 성공해도 실행 또는 종료 시 `0xc0000005`,
`0xc0000374`가 발생할 수 있다.

## 3. 필수 설치 항목

Visual Studio Installer에서 `Visual Studio Build Tools 2022`의 다음 workload/component를
설치한다.

- `C++를 사용한 데스크톱 개발`
- `MSVC v143 C++ x64/x86 Build Tools`
- Windows 10 또는 Windows 11 SDK
- CMake tools for Windows

Linux용 C++ workload, MFC/ATL, UWP, .NET workload는 이 빌드에 필요하지 않다. 별도로
Git for Windows와 Python 3도 필요하다. Ninja와 CMake는 Visual Studio 설치본을 사용할
수 있다. TizenVG 빌드에는 Meson도 필요하므로 다음과 같이 설치하고 버전을 확인한다.

```powershell
python -m pip install --user "meson==1.4.2"
meson --version
```

`meson --version`은 반드시 새로 설치한 Meson을 가리켜야 한다. `vcpkg`가 내려받은 오래된
Meson 0.52.x가 `PATH` 앞쪽에 있으면 TizenVG configure 중 `Unknown method
"override_dependency"`로 실패한다. 이 경우 사용자 Python의 Scripts 경로 또는 새 Meson wrapper를
`PATH` 앞에 두고 다시 실행한다.

재부팅은 Installer가 요구할 때만 한다.

## 4. 디렉터리 구성

공백과 한글이 없는 짧은 build 경로를 사용한다.

```text
C:\work\DALi\
  dali-core\
  dali-adaptor\
  dali-ui\
  windows-dependencies\
  tizenvg\
  dali-env\
  out\

C:\Tools\DALI_VCPKG\
  vcpkg\
```

원본 checkout이 OneDrive 등의 다른 위치에 있다면 복사할 필요 없이 junction을 만들 수
있다. 대상 경로는 실제 환경에 맞게 바꾼다.

```powershell
New-Item -ItemType Directory -Force C:/work/DALi | Out-Null
New-Item -ItemType Junction -Path C:/work/DALi/dali-core    -Target "D:/src/dali-core"
New-Item -ItemType Junction -Path C:/work/DALi/dali-adaptor -Target "D:/src/dali-adaptor"
New-Item -ItemType Junction -Path C:/work/DALi/dali-ui      -Target "D:/src/dali-ui"
```

이미 같은 이름의 경로가 있으면 junction 명령을 실행하지 않는다.

## 5. 사외 환경 준비

사외에서는 공개 GitHub에 직접 접근한다고 가정한다.

```powershell
Set-Location C:/work/DALi
git clone https://github.com/dalihub/windows-dependencies.git
```

현재 shell에 과거 proxy 설정이 남아 있다면 제거한다.

```powershell
Remove-Item Env:VCPKG_PROXY -ErrorAction SilentlyContinue
Remove-Item Env:HTTP_PROXY  -ErrorAction SilentlyContinue
Remove-Item Env:HTTPS_PROXY -ErrorAction SilentlyContinue
```

보완된 `windows-dependencies`의 통합 setup script로 vcpkg와 TizenVG를 구성한다.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File C:/work/DALi/windows-dependencies/vcpkg-script/setup-dali-dependencies.ps1 `
  -DaliRoot C:/work/DALi `
  -VcpkgRoot C:/Tools/DALI_VCPKG/vcpkg
```

이 script는 다음 작업을 수행한다.

1. `dalihub/vcpkg` clone
2. 검증 revision `a58936506` checkout
3. DALi port patch 4개, proxy patch, VS 2022 호환 patch 적용
4. vcpkg bootstrap
5. 필요한 `x64-windows` third-party package만 설치
6. TizenVG `tizen` 브랜치 clone 및 검증 revision checkout
7. x64 MSVC 환경을 감지하여 TizenVG를 `dali-env`에 빌드·설치

대상 vcpkg 경로가 이미 존재하면 기존 작업을 보호하기 위해 script가 중단된다. 기존 설치를
재사용할 때는 `-SkipVcpkg`를 사용한다. TizenVG를 재사용하려면 `-SkipTizenVg`를 사용한다.

## 6. 사내 환경 준비

사내에서는 승인된 Git mirror와 proxy 정보를 사용한다. 실제 host, port 및 mirror URL은
사내 안내에 따라 넣고 문서나 commit에 credential을 기록하지 않는다.

### 6.1 사내 proxy로 공개 저장소에 접근하는 경우

```powershell
$Proxy = "proxy.company.example:8080"

powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File C:/work/DALi/windows-dependencies/vcpkg-script/setup-dali-dependencies.ps1 `
  -DaliRoot C:/work/DALi `
  -VcpkgRoot C:/Tools/DALI_VCPKG/vcpkg `
  -Proxy $Proxy
```

script는 현재 process에 다음 값을 설정한다.

```text
VCPKG_PROXY=proxy.company.example:8080
HTTP_PROXY=http://proxy.company.example:8080
HTTPS_PROXY=http://proxy.company.example:8080
```

TLS 검증을 끄지 않는다. HTTPS inspection을 사용하는 환경에서는 사내 절차에 따라 회사
root certificate를 Windows trust store에 설치한다.

### 6.2 사내 Git mirror를 사용하는 경우

`windows-dependencies`, DALi 소스와 TizenVG는 사내 mirror에서 받고 setup script에
각 mirror URL을 전달한다.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File C:/work/DALi/windows-dependencies/vcpkg-script/setup-dali-dependencies.ps1 `
  -DaliRoot C:/work/DALi `
  -VcpkgRoot C:/Tools/DALI_VCPKG/vcpkg `
  -VcpkgRepository "https://git.company.example/mirror/dalihub/vcpkg.git" `
  -TizenVgRepository "https://git.company.example/mirror/tizen/tizenvg.git" `
  -Proxy "proxy.company.example:8080"
```

mirror에 vcpkg `a58936506`과 문서에 지정된 TizenVG revision이 있어야 한다. package source
archive까지 사내 mirror로 치환되는 환경이라면 해당 mirror 정책을 따르되 SHA512 검증은
유지한다.

## 7. vcpkg 수동 구성 방법

setup script를 사용할 수 없을 때만 다음 절차를 사용한다. 모든 patch는 보완된
`windows-dependencies`에서 가져오며 `patch.exe` 대신 `git apply`를 사용한다.

```powershell
$VcpkgRoot = "C:/Tools/DALI_VCPKG/vcpkg"
$PatchRoot = "C:/work/DALi/windows-dependencies/vcpkg-script"

git clone https://github.com/dalihub/vcpkg.git $VcpkgRoot
git -C $VcpkgRoot checkout a58936506

$Patches = @(
  "[VCPKG]_0001_Fix_proxy_access.patch"
  "[VCPKG-angle]_0001_Apply_Fix_glInvalidateFramebuffer_crash.patch"
  "[VCPKG-getopt]_0001_Apply_Fix_extern_c.patch"
  "[VCPKG-libjpeg-turbo]_0001_Apply_Fix_fill_jpeg_buffer_cb.patch"
  "[VCPKG-pthreads]_0001_Apply_Fix_define_timespec.patch"
  "[VCPKG]_0002_VS2022_and_modern_downloads.patch"
)

foreach($Patch in $Patches)
{
  git -C $VcpkgRoot apply --check --ignore-whitespace "$PatchRoot/$Patch"
  if($LASTEXITCODE -ne 0) { throw "Patch check failed: $Patch" }
  git -C $VcpkgRoot apply --ignore-whitespace --whitespace=nowarn "$PatchRoot/$Patch"
  if($LASTEXITCODE -ne 0) { throw "Patch apply failed: $Patch" }
}

cmd.exe /d /c "`"$VcpkgRoot/bootstrap-vcpkg.bat`" -disableMetrics"
```

설치 package 목록:

```powershell
$Packages = @(
  "winsock2:x64-windows", "pthreads:x64-windows", "curl:x64-windows",
  "getopt-win32:x64-windows", "libexif:x64-windows",
  "libjpeg-turbo:x64-windows", "libpng:x64-windows", "giflib:x64-windows",
  "angle:x64-windows", "cairo:x64-windows", "fontconfig:x64-windows",
  "freetype:x64-windows", "harfbuzz:x64-windows", "fribidi:x64-windows",
  "libwebp:x64-windows"
)

& "$VcpkgRoot/vcpkg.exe" install @Packages
```

legacy `build-deps.sh`는 `dali2-toolkit`과 x86 package까지 설치하는 광범위한 workflow이므로
이번 smoke test에는 사용하지 않는다. 보완본에서는 안전을 위해 proxy 기본값도 제거했다.

고정한 vcpkg revision에는 TizenVG port가 없으므로 통합 setup script가 Meson build로
설치한다.

## 8. MSVC 환경과 공통 변수 설정

Developer PowerShell을 직접 열 필요는 없다. 일반 PowerShell에서도 아래 코드로 x64 MSVC
환경을 현재 shell에 가져올 수 있다.

이 절의 값은 Ubuntu build 환경에서 사용하는 `setenv`에 대응하며 현재 PowerShell process에만
적용된다. 새 PowerShell을 열면 다시 실행해야 한다. `VsDevCmd.bat` import는 compile/link에
필요하고, DALi 경로와 data 변수는 configure/build/install 및 sample 실행에 사용된다.

```powershell
$VsDevCmd = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat"

cmd.exe /d /c "call `"$VsDevCmd`" -arch=x64 -host_arch=x64 >nul && set" |
  ForEach-Object {
    if($_ -match '^([^=]+)=(.*)$')
    {
      [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
    }
  }

where.exe cl
cmake --version
ninja --version
python --version
git --version
```

그다음 공통 변수를 설정한다.

```powershell
$DALI_ROOT   = "C:/work/DALi"
$DALI_PREFIX = "$DALI_ROOT/dali-env"
$DALI_OUT    = "$DALI_ROOT/out"
$VCPKG_ROOT  = "C:/Tools/DALI_VCPKG/vcpkg"

# Ninja가 MSVC의 /showIncludes 출력을 확실히 해석하도록 영문 출력 사용
$env:VSLANG = "1033"

New-Item -ItemType Directory -Force $DALI_PREFIX, $DALI_OUT | Out-Null

$env:DESKTOP_PREFIX = $DALI_PREFIX
$env:DALI_DATA_RO_DIR = "$DALI_PREFIX/share/dali"
$env:DALI_DATA_RW_DIR = "$DALI_PREFIX/share/dali"
$env:DALI_DATA_RO_INSTALL_DIR = "$DALI_PREFIX/share/dali"
$env:FONTCONFIG_FILE = "$DALI_PREFIX/share/dali/fonts.conf"
$env:PATH = "$DALI_PREFIX/bin;$DALI_PREFIX/lib;$VCPKG_ROOT/installed/x64-windows/bin;$env:PATH"

`cmd.exe /c` 한 줄 명령으로 같은 값을 설정할 때는 반드시 `set "NAME=value"` 형식을 사용한다.
`set NAME=value && cmake ...`처럼 쓰면 `&&` 앞 공백이 값 끝에 포함되어
`C:/work/DALi/dali-env/share/dali /ui/images` 같은 잘못된 install 경로가 생성될 수 있다.

$Common = @(
  "-G", "Ninja"
  "-DCMAKE_BUILD_TYPE=Release"
  "-DCMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"
  "-DVCPKG_TARGET_TRIPLET=x64-windows"
  "-DCMAKE_INSTALL_PREFIX=$DALI_PREFIX"
  "-DCMAKE_PREFIX_PATH=$DALI_PREFIX"
)
```

toolchain, architecture 또는 build type을 바꾼 경우 기존 cache를 재사용하지 말고 새로운
`out` 하위 경로를 사용한다.

## 9. windows-dependencies 빌드

```powershell
cmake -S "$DALI_ROOT/windows-dependencies/build" `
      -B "$DALI_OUT/windows-dependencies" @Common

cmake --build "$DALI_OUT/windows-dependencies" `
      --target install --parallel 8

Test-Path "$DALI_PREFIX/share/dali-windows-dependencies/dali-windows-dependencies-config.cmake"
```

마지막 결과가 `True`여야 한다.

## 10. TizenVG 설치 확인 또는 개별 재설치

DALi의 CanvasRenderer와 `canvas-view`, `chart-view` sample에는 TizenVG가 필요하다. TizenVG는
ThorVG 1.0.7 기반에 DALi가 사용하는 Tizen 확장 API를 더한 구현이다. 5절의 통합 setup을
실행했다면 다음 결과만 확인한다.

```powershell
Test-Path "$DALI_PREFIX/include/thorvg.h"
Test-Path "$DALI_PREFIX/bin/thorvg.dll"
```

설치를 건너뛰었거나 TizenVG만 다시 설치하려면 다음 스크립트를 실행한다.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File "$DALI_ROOT/windows-dependencies/vcpkg-script/setup-tizenvg.ps1" `
  -InstallPrefix "$DALI_PREFIX" `
  -SourceRoot "$DALI_ROOT/tizenvg" `
  -BuildRoot "$DALI_OUT/tizenvg"
```

스크립트는 검증 revision을 checkout하고 `thorvg.h`와 `thorvg.dll` 설치까지 확인한다.
dali-adaptor의 Windows CMake는 설치된 `thorvg.h`의 `TVG_VERSION_*` macro를 읽어 1.x API
경로를 선택한다. CanvasRenderer와 Lottie 모두 TizenVG를 사용한다. Lottie frame은
Windows에서 TBM surface queue 대신 adaptor의 generic CPU PixelBuffer 경로로 전달된다.

Lottie까지 검증해야 하는 환경에서는 설치된 TizenVG에 `thorvg_lottie.h`가 있어야 한다.
없거나 `lottie-animation-view.example` 실행 시 JSON load가 실패하면 TizenVG를 `svg,lottie`
loader로 다시 구성한다. MSVC에서는 Lottie source가 `M_PI`/`M_PI_2`를 사용하므로
`/D_USE_MATH_DEFINES`도 함께 전달한다.

```powershell
meson setup "$DALI_OUT/tizenvg" "$DALI_ROOT/tizenvg" `
  --backend ninja `
  --buildtype release `
  --default-library shared `
  --prefix "$DALI_PREFIX" `
  --libdir lib `
  -Dloaders=svg,lottie `
  -Dcpp_args=/D_USE_MATH_DEFINES `
  -Dstrip=false `
  --reconfigure
meson compile -C "$DALI_OUT/tizenvg"
meson install -C "$DALI_OUT/tizenvg"

Test-Path "$DALI_PREFIX/include/thorvg_lottie.h"
```

## 11. dali-core 빌드

```powershell
$CoreArgs = $Common + @(
  "-DENABLE_PKG_CONFIGURE=OFF"
  "-DENABLE_LINK_TEST=OFF"
  "-DINSTALL_CMAKE_MODULES=ON"
  "-Ddali-windows-dependencies_DIR=$DALI_PREFIX/share/dali-windows-dependencies"
)

cmake -S "$DALI_ROOT/dali-core/build/tizen" `
      -B "$DALI_OUT/dali-core" @CoreArgs

cmake --build "$DALI_OUT/dali-core" `
      --target install --parallel 8

Test-Path "$DALI_PREFIX/bin/dali2-core.dll"
Test-Path "$DALI_PREFIX/share/dali2-core/dali2-core-config.cmake"
```

이미 만들어진 build tree에서 core header를 수정하거나 새 patch를 적용했다면 한 번은 clean
build를 수행한다. 한국어 MSVC의 `/showIncludes` 출력이 Ninja dependency 정보로 인식되지
않아 header 변경 뒤에도 일부 object가 재컴파일되지 않는 경우가 실제로 확인됐다.

```powershell
cmake --build "$DALI_OUT/dali-core" --target install --clean-first --parallel 8
```

## 12. dali-adaptor 빌드

```powershell
$AdaptorArgs = $Common + @(
  "-DENABLE_PKG_CONFIGURE=OFF"
  "-DENABLE_LINK_TEST=OFF"
  "-DINSTALL_CMAKE_MODULES=ON"
  "-DPROFILE_LCASE=windows"
  "-DENABLE_PROFILE=WINDOWS"
  "-DENABLE_GRAPHICS_BACKEND=GLES"
  "-DENABLE_VECTOR_BASED_TEXT_RENDERING=OFF"
  "-Dthorvg_support=ON"
  "-Ddali-windows-dependencies_DIR=$DALI_PREFIX/share/dali-windows-dependencies"
  "-Ddali2-core_DIR=$DALI_PREFIX/share/dali2-core"
)

cmake -S "$DALI_ROOT/dali-adaptor/build/tizen" `
      -B "$DALI_OUT/dali-adaptor" @AdaptorArgs

cmake --build "$DALI_OUT/dali-adaptor" `
      --target install --parallel 8

Test-Path "$DALI_PREFIX/bin/dali2-adaptor.dll"
Test-Path "$DALI_PREFIX/share/dali2-adaptor/dali2-adaptor-config.cmake"
```

## 13. dali-ui 빌드

```powershell
$UiArgs = $Common + @(
  "-DENABLE_PKG_CONFIGURE=OFF"
  "-DINSTALL_CMAKE_MODULES=ON"
  "-DENABLE_VECTOR_BASED_TEXT_RENDERING=OFF"
  "-Ddali2-core_DIR=$DALI_PREFIX/share/dali2-core"
  "-Ddali2-adaptor_DIR=$DALI_PREFIX/share/dali2-adaptor"
)

cmake -S "$DALI_ROOT/dali-ui/build/tizen" `
      -B "$DALI_OUT/dali-ui" @UiArgs

cmake --build "$DALI_OUT/dali-ui" `
      --target install --parallel 8

Test-Path "$DALI_PREFIX/bin/dali2-ui-foundation.dll"
Test-Path "$DALI_PREFIX/bin/dali2-ui-components.dll"
Test-Path "$DALI_PREFIX/share/dali2-ui-foundation/dali2-ui-foundation-config.cmake"
Test-Path "$DALI_PREFIX/share/dali2-ui-components/dali2-ui-components-config.cmake"
```

## 14. sample CMake 이식과 범용 빌드

Ubuntu sample 다수는 각 디렉터리의 `CMakeLists.txt`에서 `PkgConfig`와
`PKG_CHECK_MODULES()`를 직접 사용한다. 이 형태는 Windows의 CMake config package를 찾지
못하므로 해당 sample을 Windows에서 빌드하기 전에 공통 sample CMake 방식으로 이식해야 한다.

최상위 `samples/CMakeLists.txt`가 `common.cmake`를 포함하므로, sample별 CMake에서는 직접
package를 찾고 compile/link option을 반복하지 말고 다음 형태를 사용한다.

```cmake
CMAKE_MINIMUM_REQUIRED(VERSION 3.8.2)
PROJECT(sample-name.example)

SET(CMAKE_CXX_STANDARD 17)
DALI_ADD_SAMPLE(sample-name.example sample-name-example.cpp)

# 필요한 경우에만 sample 전용 define, include, library를 target 단위로 추가한다.
# TARGET_COMPILE_DEFINITIONS(sample-name.example PRIVATE ...)
# TARGET_INCLUDE_DIRECTORIES(sample-name.example PRIVATE ...)
# TARGET_LINK_LIBRARIES(sample-name.example PRIVATE ...)
```

`samples/common.cmake`는 `WIN32`에서 `find_package(... CONFIG)`와 imported target을 사용하고,
Ubuntu에서는 기존 `pkg-config` package를 사용한다. 따라서 위 방식으로 이식해도 Ubuntu 빌드는
유지된다. 단, Tizen 전용 API나 Windows에 없는 plugin을 직접 사용하는 sample은 별도의
platform 조건 또는 Windows 제외 처리가 필요하다.

이식이 끝난 sample 디렉터리 이름을 `$SampleNames`에 나열하면 여러 개를 한 번에 configure,
build, install할 수 있다.

```powershell
$SampleNames = @(
  "sample-directory-1"
  "sample-directory-2"
)
$SampleList = $SampleNames -join ";"

$SampleArgs = $Common + @(
  "-DDALI_UI_SAMPLE_LIST=$SampleList"
  "-Ddali2-core_DIR=$DALI_PREFIX/share/dali2-core"
  "-Ddali2-adaptor_DIR=$DALI_PREFIX/share/dali2-adaptor"
  "-Ddali2-ui-foundation_DIR=$DALI_PREFIX/share/dali2-ui-foundation"
  "-Ddali2-ui-components_DIR=$DALI_PREFIX/share/dali2-ui-components"
)

cmake -S "$DALI_ROOT/dali-ui/samples" `
      -B "$DALI_OUT/dali-ui-samples" @SampleArgs

cmake --build "$DALI_OUT/dali-ui-samples" `
      --target install --parallel 8

Get-ChildItem "$DALI_PREFIX/bin" -Filter "*.example.exe"
```

`DALI_UI_SAMPLE_LIST`를 빈 값으로 설정하면 CMake가 모든 sample 디렉터리를 추가한다. 아직
이식되지 않았거나 Windows에서 지원하지 않는 sample이 하나라도 있으면 configure/build가
중단되므로, 전체 이식 전에는 검증된 디렉터리만 명시한다.

설치된 header/API 또는 sample CMake 구성을 바꾼 뒤 기존 sample build tree를 재사용하면 이전
object가 남아 구 API symbol로 링크될 수 있다. 이 경우 sample만 clean 후 다시 빌드한다.

```powershell
cmake --build "$DALI_OUT/dali-ui-samples" --target clean
cmake --build "$DALI_OUT/dali-ui-samples" --target canvas-view.example chart-view.example --parallel 8
```

Lottie 단독 smoke test는 `image-view` sample 묶음의 다음 target으로 확인한다.

```powershell
$SampleList = "image-view"
$SampleArgs = $Common + @(
  "-DDALI_UI_SAMPLE_LIST=$SampleList"
  "-Ddali2-core_DIR=$DALI_PREFIX/share/dali2-core"
  "-Ddali2-adaptor_DIR=$DALI_PREFIX/share/dali2-adaptor"
  "-Ddali2-ui-foundation_DIR=$DALI_PREFIX/share/dali2-ui-foundation"
  "-Ddali2-ui-components_DIR=$DALI_PREFIX/share/dali2-ui-components"
)

cmake -S "$DALI_ROOT/dali-ui/samples" `
      -B "$DALI_OUT/dali-ui-samples" @SampleArgs
cmake --build "$DALI_OUT/dali-ui-samples" `
      --target lottie-animation-view.example --parallel 8
```

## 15. 실행

새 PowerShell에서 실행한다면 아래 runtime 환경을 먼저 설정한다. 이 부분이 Ubuntu에서
`setenv`를 실행한 뒤 앱을 구동하는 것과 같은 역할이다. Developer PowerShell이나 MSVC compiler
환경은 이미 빌드된 앱을 실행할 때는 필요하지 않지만, `PATH`와 `DALI_DATA_*` 등은 새 shell마다
필요하다.

```powershell
$DALI_PREFIX = "C:/work/DALi/dali-env"
$VCPKG_ROOT  = "C:/Tools/DALI_VCPKG/vcpkg"

$env:PATH = "$DALI_PREFIX/bin;$DALI_PREFIX/lib;$VCPKG_ROOT/installed/x64-windows/bin;$env:PATH"
$env:DESKTOP_PREFIX = $DALI_PREFIX
$env:DALI_DATA_RO_DIR = "$DALI_PREFIX/share/dali"
$env:DALI_DATA_RW_DIR = "$DALI_PREFIX/share/dali"
$env:DALI_DATA_RO_INSTALL_DIR = "$DALI_PREFIX/share/dali"
$env:FONTCONFIG_FILE = "$DALI_PREFIX/share/dali/fonts.conf"

# 원하는 경우 window 초기 크기를 명시한다.
$env:DALI_WINDOW_WIDTH = "1920"
$env:DALI_WINDOW_HEIGHT = "1080"

Set-Location "$DALI_PREFIX/bin"
$SampleExe = "sample-name.example.exe"
& ".\$SampleExe"
```

반복 실행에는 이 문서와 함께 제공되는 `C:\work\DALi\set-dali-runtime-env.ps1`을 새
PowerShell에서 먼저 dot-source한다. 다른 위치에 설치했다면 script 상단의 두 경로만 바꾼다.

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
. C:\work\DALi\set-dali-runtime-env.ps1
& C:\work\DALi\dali-env\bin\sample-name.example.exe
```

첫 줄은 현재 PowerShell process에만 적용되며 시스템 또는 사용자 실행 정책을 영구 변경하지
않는다. script 실행이 이미 허용된 환경에서는 생략해도 된다.

여러 DALi checkout이나 prefix를 번갈아 쓸 수 있으므로 이 값들을 Windows 사용자 환경변수로
영구 등록하는 것보다는 shell별 script를 사용하는 편이 안전하다.

성공 기준:

- `DaliWindow` Win32 window가 생성되고 응답한다.
- sample 고유의 UI와 resource가 표시되고 입력에 응답한다.
- log에 `GraphicsBackend = GLES`, `EGL Information`, `Using OpenGL es 3.0`이 보인다.
- window를 닫았을 때 Windows Application log에 crash가 기록되지 않는다.

첫 실행에서 아래 파일이 없다는 log는 optional GPU cache/config 조회이므로 window와 rendering이
정상이라면 치명 오류가 아니다.

```text
%LOCALAPPDATA%\.cache\dali_common_caches\gpu-environment-gles.conf
```

## 16. 문제 해결

### 창은 열리지만 모든 sample이 흰 화면임

Windows에서 `unsigned long`은 32비트이지만 `std::size_t`와 shader reflection hash는 64비트다.
`dali-core/dali/internal/update/common/uniform-map.h`의 `UniformPropertyMapping::Hash`가
`unsigned long`이면 uniform 이름 hash의 상위 32비트가 잘려 `size`, `offset` 같은 visual
uniform을 찾지 못하고, 결과적으로 모든 quad 크기가 0이 된다. 다음 선언이 반영됐는지 확인한다.

```cpp
using Hash = std::size_t;
```

수정 후에는 위 10절의 `--clean-first` 명령으로 core를 다시 빌드·설치하고 실행 중인 sample을
완전히 종료한 뒤 재실행한다. DLL을 사용하는 process가 남아 있으면 install이 실패하거나 이전
DLL로 계속 실행될 수 있다.

### `cl.exe`를 찾지 못함

8절의 `VsDevCmd.bat` import를 먼저 실행한다. Visual Studio 설치 위치가 다르면
`$VsDevCmd`를 실제 경로로 바꾼다.

### vcpkg가 VS 2022 또는 compiler를 찾지 못함

- vcpkg가 정확히 `a58936506`인지 확인한다.
- 여섯 patch가 모두 적용됐는지 확인한다.
- `MSVC v143 C++ x64/x86 Build Tools` component가 설치돼 있어야 한다.
- 보완 patch를 사용하면 English language pack은 필수가 아니다.

```powershell
git -C C:/Tools/DALI_VCPKG/vcpkg rev-parse --short HEAD
git -C C:/Tools/DALI_VCPKG/vcpkg status --short
```

### 사외에서 download가 사내 proxy로 향함

오래된 `[VCPKG]_0001_Fix_proxy_access.patch`에는 특정 proxy IP가 하드코딩돼 있었다. 이
문서와 함께 수정된 patch를 사용하고 `VCPKG_PROXY`, `HTTP_PROXY`, `HTTPS_PROXY`에 남은
값을 제거한다.

### giflib download 실패

구형 NCHC SourceForge URL이 더 이상 동작하지 않는다.
`[VCPKG]_0002_VS2022_and_modern_downloads.patch` 적용 여부를 확인한다.

### Meson이 x64 build에서 x86을 선택함

동일한 VS 2022 호환 patch가 x64 native file과 architecture 환경을 강제한다. build tree가
이미 잘못 구성됐다면 새로운 vcpkg buildtree 또는 새 vcpkg 경로에서 다시 시도한다.

### Python `UnicodeDecodeError` 또는 CP949 오류

`dali-ui/scripts/autogen/gen-animation-spec.py`의 파일 입출력에 `encoding='utf-8'` 보완이
포함돼 있는지 확인한다.

### `Fontconfig error: Cannot load default config file` 또는 글자가 안 보임

`windows-dependencies` 보완본을 다시 설치하고 아래 환경변수를 실행 전에 설정한다.

```powershell
$env:FONTCONFIG_FILE = "C:/work/DALi/dali-env/share/dali/fonts.conf"
```

### MSVC C2026: string too big

shader generator가 generated raw string literal을 8,000 byte 단위로 분할하는 버전인지
확인한다. generator 변경 후 generated header가 갱신돼야 한다.

### `FrameRange(int,int)` LNK2019

`SelectableLottieImage::FrameRange`의 out-of-line 생성자 선언과 정의가
`DALI_UI_API`로 export돼야 한다. foundation DLL을 다시 설치한 뒤 components를 빌드한다.

### sample 실행/종료 시 `0xc0000005` 또는 `0xc0000374`

`dali-ui/samples/CMakeLists.txt`에서 MSVC compile option `/vmg`가 적용되는지 확인한다.
library와 sample의 member-function pointer ABI가 같아야 한다.

### DLL을 찾지 못함 또는 `0xc000007b`

모든 산출물이 x64인지 확인하고 다음 세 디렉터리를 `PATH`에 넣는다.

```text
C:\work\DALi\dali-env\bin
C:\work\DALi\dali-env\lib
C:\Tools\DALI_VCPKG\vcpkg\installed\x64-windows\bin
```

```powershell
$SampleExe = "C:/work/DALi/dali-env/bin/sample-name.example.exe"
dumpbin /DEPENDENTS $SampleExe
where.exe libEGL.dll
where.exe libGLESv2.dll
```

### package를 찾지 못함

`CMAKE_PREFIX_PATH`와 각 `*_DIR`이 `dali-env/share` 아래 설치 package를 가리키는지
확인한다. vcpkg 안의 오래된 DALi package가 선택되면 안 된다.

## 17. 최종 산출물

정상 완료 시 최소한 다음 파일이 존재한다.

```text
C:\work\DALi\dali-env\bin\dali2-core.dll
C:\work\DALi\dali-env\bin\dali2-adaptor.dll
C:\work\DALi\dali-env\bin\dali2-ui-foundation.dll
C:\work\DALi\dali-env\bin\dali2-ui-components.dll
C:\work\DALi\dali-env\bin\<선택한-sample>.example.exe
```

검증된 sample들에서 실제 `DaliWindow` 1456×939 창 생성, ANGLE EGL 초기화, OpenGL ES 3.0
사용, UI 응답 및 정상 window close 후 crash event 없음까지 확인했다.
