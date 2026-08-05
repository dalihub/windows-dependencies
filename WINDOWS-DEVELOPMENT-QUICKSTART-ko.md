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

`WindowsDependenciesSDK`에는 선택한 구성의 vcpkg 의존성이 설치되고,
`dali-env`에는 core, adaptor, UI와 sample이 설치된다.

## 의존성 설치

```powershell
cd <workspace>\windows-dependencies
.\install.ps1
```

설치 스크립트는 `windows-sdk-latest` prerelease의 ZIP과 SHA-256 파일을
먼저 받는다. 기본값은 Debug이며 `-Configuration Release`를 지정하면
Release 전용 ZIP을 받는다. 각 ZIP에는 선택한 구성만 들어 있다. 사용할 수
있는 Release가 없거나 다운로드 및 검증이 최종
실패하면 같은 SDK 구조를 소스에서 직접 빌드한다.

```text
vcpkg\installed\x64-windows\debug\bin\    # Debug ZIP
vcpkg\installed\x64-windows\release\bin\  # Release ZIP
```

GitHub 네트워크 작업은 기존 정책을 공통으로 사용한다. 전송 전체 시간이
아니라 전송률이 10초 동안 1 KiB/s 미만일 때만 실패로 판정하며 최대
10회 시도한다. 정상적으로 진행되는 큰 clone이나 다운로드는 10초가
지났다는 이유로 중단하지 않는다.

TizenVG와 그 밖의 사내 확장은 별도 내부 저장소에서 관리하며 이 저장소는
다운로드하거나 빌드하지 않는다.

## 프로젝트별 빌드와 설치

```powershell
cd <workspace>\dali-core
.\build\windows\build.ps1

cd <workspace>\dali-adaptor
.\build\windows\build.ps1

cd <workspace>\dali-ui
.\build\windows\build.ps1

cd <workspace>\dali-ui\samples
.\build.ps1
```

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

환경이 적용된 새 PowerShell을 열 수도 있다.

```powershell
.\windows-dependencies\dali-shell.ps1
```

이 셸에서는 `dali-env\bin`, SDK의 `bin`과 vcpkg runtime `bin`이 PATH에
설정되므로 설치된 sample 실행 파일을 이름으로 실행할 수 있다.

## SDK 자동 배포

GitHub Action은 SDK 빌드 입력이 바뀐 commit이 `master`에 반영될 때
`windows-2022`에서 실행된다. 일반적으로 PR merge가 이 push를 만들며 문서만
바뀐 경우에는 실행하지 않는다. 수동 실행도 지원한다. x64 Debug와 Release
전용 SDK를 각각 빌드해 다음 `windows-sdk-latest` prerelease 자산을 관리한다.

```text
DALi-WindowsDependenciesSDK-x64-Debug.zip
DALi-WindowsDependenciesSDK-x64-Debug.zip.sha256
DALi-WindowsDependenciesSDK-x64-Release.zip
DALi-WindowsDependenciesSDK-x64-Release.zip.sha256
build-inputs-Debug.json / build-inputs-Release.json
sdk-contents-Debug.json / sdk-contents-Release.json
```

빌드 입력 manifest가 기존 구성과 같으면 빌드와 업로드를 모두
건너뛴다. 입력이 달라도 SDK 파일 내용이 같으면 ZIP은 유지하고 다음
실행의 비교를 위해 입력 manifest만 갱신한다.

정식 버전 정책은 `WINDOWS-SDK-VERSIONING-TODO.md`에 정리되어 있다.
