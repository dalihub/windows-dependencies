# DALi Windows MSVC 빌드 및 실행 가이드

이 문서는 다음 네 저장소를 같은 폴더에 clone한 사용자를 위한 절차다.

```text
<workspace>\
  windows-dependencies\
  dali-core\
  dali-adaptor\
  dali-ui\
```

사용자는 CMake 옵션, Visual Studio 경로, 설치 경로를 직접 설정하지 않는다.
`windows-dependencies`에 포함된 스크립트가 형제 저장소와 빌드 도구를 자동으로 찾고,
필요한 순서와 산출물을 검사한다.

검증된 구성:

- Windows x64
- Visual Studio 2022, MSVC v143
- CMake + Ninja
- Release
- GLES/ANGLE
- vcpkg `x64-windows`

Debug, x86, MinGW, Vulkan은 현재 스크립트의 지원 범위가 아니다.

## 1. 사전 준비

Visual Studio Installer에서 다음 항목을 설치한다.

- Visual Studio 2022 또는 Build Tools 2022
- `Desktop development with C++`
- MSVC v143 x64/x86 build tools
- Windows 10 또는 Windows 11 SDK
- CMake tools for Windows

Git for Windows도 필요하다. Python, Meson, Ninja는 별도로 설치할 필요가 없다.

PowerShell에서 `windows-dependencies`로 이동하고, 현재 PowerShell에서 로컬 스크립트
실행을 허용한다.

```powershell
Set-Location .\windows-dependencies
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

## 2. 사용자가 입력할 수 있는 환경정보

대부분의 사용자는 아무것도 설정하지 않아도 된다.

### proxy

기존 `HTTPS_PROXY` 또는 `HTTP_PROXY`가 있으면 자동으로 사용한다. 직접 입력해야 한다면
빌드 전에 다음 두 줄만 실행한다.

```powershell
$env:HTTPS_PROXY = Read-Host "Proxy 주소를 http://host:port 형식으로 입력"
$env:HTTP_PROXY = $env:HTTPS_PROXY
```

### vcpkg 위치

기본 위치는 네 저장소가 있는 폴더의 `.deps\vcpkg`다. 다른 위치를 사용해야 할 때만 설정한다.

```powershell
$env:DALI_VCPKG_ROOT = Read-Host "vcpkg를 설치할 전체 경로 입력"
```

## 3. DALi 빌드

스크립트는 아래 순서대로 실행한다. 각 명령은 경로 탐색, MSVC x64 환경 설정, configure,
build, install, 결과 검증까지 수행하며 실패하면 즉시 중단한다.

### 삼성 사내망

```powershell
.\build_windows_dependencies.ps1
.\build_dali_core.ps1
.\build_dali_adaptor.ps1
.\build_dali_ui.ps1
```

첫 번째 명령은 다음 두 작업을 한 번에 수행한다.

1. vcpkg third-party 패키지와 사내 TizenVG 설치
2. DALi Windows 호환 패키지인 `windows-dependencies` 빌드·설치

사용하는 저장소:

- vcpkg: `https://github.com/dalihub/vcpkg.git`
- TizenVG: `https://github.sec.samsung.net/tizen/tizenvg.git`

TizenVG 저장소는 삼성 사내망에서만 접근할 수 있다.

### 사외망

사외에서는 첫 번째 명령에 `-SkipTizenVg`만 추가한다.

```powershell
.\build_windows_dependencies.ps1 -SkipTizenVg
.\build_dali_core.ps1
.\build_dali_adaptor.ps1
.\build_dali_ui.ps1
```

TizenVG가 없으면 `build_dali_adaptor.ps1`이 자동으로 `thorvg_support=OFF`를 선택한다.
일반 DALi와 정적 SVG는 빌드되며 SVG는 NanoSVG fallback을 사용한다. CanvasRenderer와
내장 Lottie renderer는 사용할 수 없다.

### 선택 옵션

CPU 사용량을 조절하려면 각 스크립트에 `-Jobs`를 지정한다.

```powershell
.\build_dali_core.ps1 -Jobs 4
```

third-party 설치는 끝났고 `windows-dependencies`만 다시 빌드하려면 다음과 같이 실행한다.

```powershell
.\build_windows_dependencies.ps1 -SkipThirdParty
```

## 4. dali-ui sample 빌드 및 실행

인자 없이 실행하면 `dali-ui/samples` 아래의 모든 sample을 빌드한다.

```powershell
.\build_dali_samples.ps1
.\run_dali_sample.ps1 hello-world.example
```

여러 sample 디렉터리를 선택할 수도 있다.

```powershell
.\build_dali_samples.ps1 -Samples hello-world,chart-view
.\run_dali_sample.ps1 chart-view.example
```

사내 TizenVG 설치 후 Lottie sample을 빌드하는 예:

```powershell
.\build_dali_samples.ps1 `
  -Samples image-view `
  -ImageViewTargets lottie-animation-view.example

.\run_dali_sample.ps1 lottie-animation-view.example
```

창 크기는 실행 인자로 지정할 수 있다.

```powershell
.\run_dali_sample.ps1 hello-world.example -Width 1920 -Height 1080
```

실행 스크립트가 `PATH`, DALi data 경로, Fontconfig 경로를 자동으로 설정한다.

## 5. 재빌드와 초기화

코드를 수정한 뒤에는 해당 프로젝트부터 뒤쪽 스크립트만 다시 실행하면 된다.

- core 변경: core → adaptor → ui
- adaptor 변경: adaptor → ui
- ui 변경: ui
- sample 변경: sample

스크립트를 반복 실행하면 기존 CMake/Ninja build tree와 dependency cache를 재사용한다.
다운로드 실패 후에도 같은 명령을 다시 실행하는 것이 가장 빠르다.

완전히 처음부터 다시 설치할 때만 실행 중인 DALi 앱을 모두 종료하고 다음 생성물을 삭제한다.
이 명령은 네 저장소 자체를 삭제하지 않는다.

```powershell
$Workspace = Split-Path -Parent (Get-Location).Path
Remove-Item -LiteralPath `
  "$Workspace\out", `
  "$Workspace\dali-env", `
  "$Workspace\tizenvg", `
  "$Workspace\.deps" `
  -Recurse -Force -ErrorAction SilentlyContinue
```

`windows-dependencies\build`는 이름과 달리 CMake 소스 디렉터리이므로 삭제하면 안 된다.

## 6. 문제 해결

### GitHub 또는 package 다운로드가 느림

같은 명령을 다시 실행한다. 설치 스크립트는 1 KiB/s 미만 전송이 10초간 지속되면 연결을
중단하고 최대 5회 재시도한다. 기존 다운로드와 package cache는 유지한다.

### proxy 또는 인증서 오류

- `HTTPS_PROXY`와 `HTTP_PROXY`를 확인한다.
- TLS 검증을 끄지 않는다.
- 회사 TLS inspection 인증서를 Windows의 신뢰할 수 있는 루트 인증 기관에 설치한다.

### `cl.exe`, CMake 또는 Ninja를 찾지 못함

Visual Studio Installer에서 v143 C++ build tools, Windows SDK, CMake tools가 설치됐는지
확인한다. 스크립트는 `vswhere.exe`를 사용해 Visual Studio 위치를 자동으로 찾는다.

### 먼저 실행해야 할 package가 없다는 오류

3절의 스크립트를 위에서 아래 순서로 실행한다. 각 스크립트는 필요한 이전 단계가 없으면
실행해야 할 스크립트 이름과 함께 중단한다.

### install 중 `Access denied`

실행 중인 DALi sample과 DALi DLL을 사용하는 프로세스를 모두 종료하고 같은 빌드 명령을
다시 실행한다.

### DLL을 찾지 못하거나 `0xc000007b` 발생

직접 EXE를 실행하지 말고 `run_dali_sample.ps1`을 사용한다. 이 스크립트는 DALi와 vcpkg의
x64 DLL 경로를 자동으로 추가한다.

### Fontconfig 오류

`build_windows_dependencies.ps1`을 먼저 실행하고 sample은 `run_dali_sample.ps1`로 실행한다.
두 스크립트가 `fonts.conf` 설치와 `FONTCONFIG_FILE` 설정을 처리한다.

### TizenVG 설치가 불완전하다는 오류

사내망에서는 `build_windows_dependencies.ps1`을 다시 실행한다. 사외 clean 환경에서는
`build_windows_dependencies.ps1 -SkipTizenVg`로 시작한다.

## 7. 생성되는 디렉터리

```text
<workspace>\
  .deps\vcpkg\       # vcpkg checkout과 패키지
  tizenvg\            # 사내망에서만 생성
  out\                # CMake/Meson build tree
  dali-env\           # 최종 DLL, LIB, 헤더, 리소스, sample
```
