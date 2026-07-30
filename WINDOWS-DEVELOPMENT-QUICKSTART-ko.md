# DALi Windows 개발 및 SDK 배포 빠른 시작

## 작업공간 구조

경로와 드라이브 이름은 고정되어 있지 않다. 네 저장소를 같은 부모
디렉터리에 두면 스크립트가 공통 부모를 작업공간으로 계산한다.

```text
<workspace>\
  dali-core\
  dali-adaptor\
  dali-ui\
  windows-dependencies\
  WindowsDependenciesSDK\
  dali-env\
```

`WindowsDependenciesSDK`에는 vcpkg 의존성과 선택적 TizenVG가 설치되고,
`dali-env`에는 core, adaptor, UI와 sample이 설치된다.

## 의존성 설치

```powershell
cd <workspace>\windows-dependencies
.\install.ps1
```

설치 스크립트는 `windows-sdk-latest` prerelease의 ZIP과 SHA-256 파일을
먼저 받는다. 사용할 수 있는 Release가 없거나 다운로드 및 검증이 최종
실패하면 같은 SDK 구조를 소스에서 직접 빌드한다.

GitHub 네트워크 작업은 기존 정책을 공통으로 사용한다. 전송 전체 시간이
아니라 전송률이 10초 동안 1 KiB/s 미만일 때만 실패로 판정하며 최대
10회 시도한다. 정상적으로 진행되는 큰 clone이나 다운로드는 10초가
지났다는 이유로 중단하지 않는다.

공개 SDK에는 TizenVG가 없다. `install.ps1`은 TizenVG 저장소도 자동으로
확인한다. 사내에서 접근되면 같은 `WindowsDependenciesSDK`에 추가하고,
저장소에 접근할 수 없으면 경고 후 TizenVG 없이 완료한다. 저장소 접근
후 발생한 TizenVG configure, build, install 오류는 숨기지 않는다.

TizenVG에 이어 WebView용 LWE(Starfish) SDK도 자동으로 준비한다
(`vcpkg-script\setup-starfish.ps1`). 첫 실행은 소스 빌드 때문에 오래
걸리며(약 30~60분), 실패 시 경고만 남기고 계속한다. 자세한 내용과 재실행
방법은 아래 "LWE(Starfish) SDK 준비" 절을 참고한다.

Debug 빌드가 필요하면 `-Configuration Debug`를 지정한다 (기본은 Release).
공개 SDK는 Release 전용이므로 이때 정적 라이브러리
`dali-windows-dependencies.lib`만 Debug로 자동 재빌드한다. 같은 SDK로
Release를 다시 쓰려면 `-Configuration Release`로 재실행하면 된다.

```powershell
.\install.ps1 -Configuration Debug
```

Debug 빌드 참고:

- WebView(LWE)는 현재 Release 전용이다. LWE 공개 API가 std::string을 DLL
  경계로 주고받아 전체 구성 일치가 필수인데 Starfish SDK가 Release로만
  빌드되기 때문이다. `lwe-web-engine-pluginuild.ps1`은 Debug 요청 시
  명확한 오류로 중단한다.
- TizenVG는 C API라 구성 혼용이 안전해 Release 그대로 사용한다.

## 프로젝트별 빌드와 설치

```powershell
cd <workspace>\dali-core
.\build\windows\build.ps1

cd <workspace>\dali-adaptor
.\build\windows\build.ps1

cd <workspace>\windows-dependencies\lwe-web-engine-plugin
.\build.ps1

cd <workspace>\dali-ui
.\build\windows\build.ps1

cd <workspace>\dali-ui\samples
.\build.ps1
```

`lwe-web-engine-plugin`은 WebView용 LWE(Starfish) 웹엔진 플러그인
(`dali2-web-engine-lwe-plugin.dll`)을 빌드해 `dali-env\bin`에 설치한다.
dali-env에 설치된 dali2-core/dali2-adaptor 패키지를 링크하므로 반드시
dali-adaptor 다음, dali-ui 이전 순서로 빌드한다. 선행 조건으로
`WindowsDependenciesSDK`에 LWE SDK(`include\LWEWebView.h`,
`lib\Starfish.lib`, `bin\Starfish.dll`)가 있어야 하며, 준비 방법은
아래 "LWE(Starfish) SDK 준비" 절을 참고한다. WebView가 필요 없으면 이
단계는 건너뛴다.

각 명령은 configure, build, install을 모두 수행한다. 빌드 중간 산출물은
각 저장소의 `_build\windows`에 있고 설치 결과는 `dali-env`에 모인다.

```powershell
.\build\windows\build.ps1 -Clean
.\build\windows\build.ps1 -Configuration Debug
.\build.ps1 -Clean -Samples hello-world,text
```

`-Clean`은 현재 저장소의 `_build\windows`만 지운다.

## 실행 환경

현재 PowerShell에 환경을 적용하려면 dot-source한다.

```powershell
cd <workspace>
. .\dali-env\setenv.ps1
```

Debug 설치 결과를 실행할 때는 다음과 같이 지정한다.

```powershell
. .\dali-env\setenv.ps1 -Configuration Debug
```

환경이 적용된 새 PowerShell을 열 수도 있다.

```powershell
.\windows-dependencies\dali-shell.ps1
.\windows-dependencies\dali-shell.ps1 -Configuration Debug
```

이 셸에서는 `dali-env\bin`, SDK의 `bin`과 vcpkg runtime `bin`이 PATH에
설정되므로 설치된 sample 실행 파일을 이름으로 실행할 수 있다.

## SDK 자동 배포

GitHub Action은 SDK 빌드 입력이 바뀐 commit이 `master`에 반영될 때
`windows-2022`에서 실행된다. 일반적으로 PR merge가 이 push를 만들며 문서만
바뀐 경우에는 실행하지 않는다. 수동 실행도 지원한다. TizenVG 없이 x64
Release SDK를 빌드해 다음 `windows-sdk-latest` prerelease 자산을 관리한다.

```text
DALi-WindowsDependenciesSDK-x64.zip
DALi-WindowsDependenciesSDK-x64.zip.sha256
build-inputs.json
sdk-contents.json
```

빌드 입력 manifest가 기존 Release와 같으면 빌드와 업로드를 모두
건너뛴다. 입력이 달라도 SDK 파일 내용이 같으면 ZIP은 유지하고 다음
실행의 비교를 위해 입력 manifest만 갱신한다.

정식 버전 정책은 `WINDOWS-SDK-VERSIONING-TODO.md`에 정리되어 있다.

## LWE(Starfish) SDK 준비

`lwe-web-engine-plugin` 빌드의 선행 조건으로, `WindowsDependenciesSDK`에
LWE 헤더(`LWEWebView.h` 등)와 `lib\Starfish.lib`, `bin\Starfish.dll`이
있어야 한다.

**`install.ps1`이 자동으로 처리한다.** 의존성 설치 단계에서
`vcpkg-script\setup-starfish.ps1`이 함께 실행되어 LWE SDK까지 준비된다.
실패해도 경고만 남기고 SDK 설치는 계속되며(WebView만 비활성), 문제를
해결한 뒤 스크립트만 다시 실행하면 된다:

```powershell
cd <workspace>\windows-dependencies
.\vcpkg-script\setup-starfish.ps1           # 재실행 (이미 완료된 단계는 건너뜀)
.\vcpkg-script\setup-starfish.ps1 -Force    # 강제 재빌드
# install.ps1 -SkipStarfish                 # LWE를 아예 건너뛰기
```

스크립트가 자동으로 수행하는 일:

1. **vcpkg 추가 포트**: openssl / libwebsockets / glew 설치 (구버전 포트
   호환 수정 포함, release 전용). openssl이 10~20분 걸린다.
2. **Starfish 소스**: `github.sec.samsung.net/lws/starfish` 클론 + 서브모듈
   + `lwe-web-engine-plugin\patches\`의 x64 패치 적용 + 바인딩 생성기용
   python3/jinja2/ply 준비.
3. **빌드·설치**: VS2022 x64 Release로 `Starfish.dll` 빌드(첫 빌드 20~40분)
   후 SDK의 `include\`, `lib\`, `bin\`에 복사.

추가 전제 조건: Python 3 + pip, `github.sec.samsung.net` 접근 권한.

**지름길**: 이미 빌드된 SDK가 있으면(예: 다른 작업공간) `include\LWEWebView.h`,
`include\LWEWorker.h`, `include\PlatformIntegrationData.h`, `lib\Starfish.lib`,
`bin\Starfish.dll`(+선택 `bin\Starfish.pdb`)만 새 SDK로 복사해도 된다 —
스크립트가 이 파일들을 발견하면 전체를 건너뛴다.

## WebView 샘플 실행

```powershell
cd <workspace>
. .\dali-env\setenv.ps1
.\dali-env\bin\web-view-win.example.exe
```

키: `ESC` 종료, `B`/`F` 뒤로/앞으로, `R` 새로고침, `H` 인라인 HTML, `J` JS 실행.
