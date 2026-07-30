# LWE(Lightweight Web Engine) 기반 Windows WebEnginePlugin 구현

이 디렉터리는 Windows에서 `Dali::WebEnginePlugin`을 LWE(Lightweight Web Engine,
`Starfish.dll`)로 구현한 어댑터입니다. **소스는 dali-adaptor가 아닌 이 저장소
(windows-dependencies)에 있으며**, 별도 플러그인 DLL
`dali2-web-engine-lwe-plugin.dll` 로 빌드되어 dali-envin(= dali2-adaptor.dll 옆)에
설치됩니다. dali-adaptor의 `web-engine-impl.cpp`가 런타임에
`libdali2-web-engine-lwe-plugin.so`를 `dlopen`하면 Windows dlfcn shim이 이를
`dali2-web-engine-lwe-plugin.dll`로 변환해 로드하므로, dali-adaptor에는 어떤
빌드타임 의존성도 없습니다. 플러그인 진입점(`CreateWebEnginePlugin` 등 4개)은
`web-engine-lwe-plugin.cpp`에 있습니다.

## 빌드 방법

```powershell
# 선행: install.ps1(SDK+Starfish) -> dali-core -> dali-adaptor 빌드 후
.uild.ps1                      # Release (기본)
.uild.ps1 -Configuration Debug
```

플러그인은 dali-env에 **설치된** dali2-core/dali2-adaptor 패키지(public/devel
API 헤더 + import lib)와 WindowsDependenciesSDK의 LWE SDK만 사용한다.

## 빌드 의존성

- `LWEWebView.h`(LWE 공개 API), `Starfish.lib`, `Starfish.dll` 및 LWE 런타임 DLL들은
  windows-dependencies의 `vcpkg-script/setup-starfish.ps1`이 사내 저장소
  (`github.sec.samsung.net/lws/starfish`)를 클론·빌드해 `WindowsDependenciesSDK`의
  `include/`, `lib/`, `bin/`으로 설치합니다. LWE 소스/바이너리를 저장소에 직접
  벤더링하는 것은 금지되어 있어, tizenvg와 같은 소스 빌드 방식을 따릅니다.
- `build/tizen/plugins/CMakeLists.txt`가 WINDOWS 프로파일에서 `LWEWebView.h`와
  `Starfish.lib`를 찾으면(`CMAKE_PREFIX_PATH`의 SDK 경로) 이 플러그인을 빌드하고,
  없으면 플러그인 빌드를 건너뜁니다.
- LWE 공개 API가 `std::string` 등 CRT/STL 객체를 DLL 경계로 주고받으므로,
  Starfish의 빌드 구성(`setup-starfish.ps1 -Mode`, 기본 debug)과 dali의 빌드 구성
  (`build\windows\build.ps1 -Configuration Debug`)을 반드시 맞춰야 합니다.
- **주의**: starfish master의 `build/windows.cmake`는 ARCH=x86만 허용합니다. dali는
  x64이므로 x64를 지원하는 브랜치/리비전을 `setup-starfish.ps1 -Revision`으로
  고정해야 합니다 (이전에 쓰던 x64 Debug 드롭이 존재하므로 해당 브랜치를 LWS 팀에
  확인할 것).

## 임시 디버그 계측 (TEMP DEBUG)

`LWEWebEnginePlugin.cpp`에는 화살표 키 입력 이슈 조사용 임시 계측이 남아 있습니다:
`DbgLog()`(고정 경로 `d:\lwe_webview.log`에 파일 로깅)와 `CrashStackFilter`(dbghelp 기반
크래시 스택 덤프, `AddVectoredExceptionHandler`). 이슈 해결 후 반드시 제거할 것.

## LWE에 대응 기능이 없어 no-op/기본값으로 남긴 것

### WebEnginePlugin (`LWEWebEnginePlugin`)
- `IsIncognito` - 항상 false
- `GetFavicon`, `GetScreenshot`, `GetScreenshotAsynchronously` - 아직 `Dali::PixelData()` 기본값
  (실제 dali-core/dali-adaptor가 정적으로 링크되어 있으므로 `PixelData::New()` 호출은 가능함 -
  아직 구현 안 됨)
- `GetNativeImage` - **구현됨.** `Create()`/`SetSize()`에서 `Dali::NativeImage::New()`로
  고정 크기 버퍼를 만들고, `WebContainer::RegisterPreRenderingHandler`로 LWE에 렌더 대상
  버퍼를 알려준 뒤 `RegisterOnRenderedHandler`에서 `Dali::DevelNativeImage::SetPixels()`로
  매 프레임 복사한다. **주의**: 픽셀 포맷을 `Pixel::BGRA8888`로 가정했는데(LWE의 Cairo
  기반 Windows 캔버스가 `CAIRO_FORMAT_ARGB32`를 쓰고 이는 리틀엔디언에서 메모리상
  BGRA 순서라는 가정), 실제 화면에 그려서 색상이 맞는지 육안 검증은 아직 안 됨 - 만약
  색이 반전되어 보이면 `LWEWebEnginePlugin.cpp`의 `kRenderBufferPixelFormat`을
  `Pixel::RGBA8888`로 바꿔볼 것. 또한 리사이즈 시마다 `NativeImage`를 새로 만드므로
  (public API에 리사이즈가 없음) DALi 쪽에서 이미지 핸들 교체를 인지하는지 확인 필요.
- `LoadContents`, `ReloadWithoutCache`(단순 Reload로 근사), `AddCustomHeader`/`RemoveCustomHeader`,
  `StartInspectorServer`/`StopInspectorServer`, `ScrollEdgeBy`, `ClearAllTilesResources`,
  `ChangeOrientation`, `SetDocumentBackgroundColor`, `ClearTilesWhenHidden`,
  `SetTileCoverAreaMultiplier`, `EnableCursorByClient`, `GetSelectedText`,
  `EnableMouseEvents`/`EnableKeyEvents`, `SetImePositionAndAlignment`, `SetCursorThemeName`,
  `GetLoadProgressPercentage`, `ActivateAccessibility`/`GetAccessibilityAddress`,
  `SetVisibility`(항상 true), `HighlightText`, `AddDynamicCertificatePath`,
  `CheckVideoPlayingAsynchronously`, `EnableVideoHole`/`SetVideoHole`, `ExitFullscreen`,
  `CreateHitTest`/`CreateHitTestAsynchronously`(항상 nullptr/false)
- Register 계열 중 실제로 LWE 콜백에 연결한 것: `PageLoadStarted`, `PageLoadFinished`,
  `PageLoadError`, `UrlChanged`, `JavaScriptAlert`(Confirm/Prompt는 LWE에 대응 콜백 없어
  등록만 받고 트리거 안 함), `FrameRendered`(비어 있음). 나머지 Register* 전부
  (ScrollEdgeReached, OverScrolled, FormRepostDecided, ConsoleMessageReceived,
  Response/Navigation/NewWindowPolicyDecided, NewWindowCreated, CertificateConfirmed,
  SslCertificateChanged, HttpAuthHandler, ContextMenuShown/Hidden, FullscreenEntered/Exited,
  TextFound, WebAuthDisplayQR/Response, FileChooserRequested, WebProcessCrashed,
  UserMediaPermissionRequest, DeviceConnectionChanged/DeviceListGet, GeolocationPermission)는
  콜백을 저장만 하고 호출되지 않음(LWE에 대응 이벤트가 없음)
- `SendTouchEvent`/`SendHoverEvent` - 첫 번째 포인트만 마우스 이벤트로 근사 변환
  (LWE의 멀티터치 `DispatchTouchStart/Move/EndEvent` API는 아직 연결 안 함)

### WebEngineSettings
LWE가 실제로 지원하는 것(`EnableSpatialNavigation`, `SetDefaultFontSize`,
`EnableWebSecurity`)만 `LWE::Settings`에 위임. 나머지 30여 개 설정 항목은 멤버 변수에
저장만 하고 실제 엔진 동작에 영향 없음.

### WebEngineBackForwardList
`CanGoBack`/`GoBack` 등은 `LWEWebEnginePlugin`이 `WebContainer`에 직접 위임하지만,
이 클래스(히스토리 아이템 열거) 자체는 전부 빈 값/nullptr - LWE에 히스토리 아이템
열거 API가 없음.

### WebEngineContext
LWE는 컨텍스트 단위(프록시/캐시/스토리지) API가 전혀 없고 전부 `WebContainer` 단위라서,
이 클래스는 호출값을 멤버에 저장만 하고 어떤 `WebContainer`에도 영향을 주지 않음.

### WebEngineCookieManager
`ClearCookies`만 실제로 `LWE::CookieManager`에 위임. accept policy/영구 저장소는 저장만.

## 다음에 볼 사람을 위한 리스크 요약
1. **GetNativeImage 렌더 브릿지 구현됨, 육안 검증 필요** - 픽셀 포맷(BGRA vs RGBA) 가정을
   실제 화면 렌더로 확인할 것 (위 GetNativeImage 항목 참고).
2. **Debug/Release CRT 혼용 주의** - 플러그인 DLL과 Starfish.dll의 빌드 구성이 다르면
   `std::string`을 주고받는 LWE API 경계에서 크래시 위험. 현재 Starfish SDK가 Debug만
   제공되므로 dali 전체를 Debug로 빌드해서 맞출 것 (위 빌드 의존성 참고).
3. LWE 런타임 DLL 중 `harfbuzz.dll`, `cairo-2.dll`, `fontconfig-1.dll` 등은 vcpkg가 제공하는
   DLL과 이름이 겹치는데, SDK 스테이징에서 **vcpkg 쪽을 우선**하고 겹치는 LWE DLL은
   복사하지 않는다(windows-dependencies의 `setup-starfish.ps1`). Windows는 프로세스당
   같은 이름의 DLL을 하나만 로드하므로, LWE(Debug 빌드)가 vcpkg Release DLL과 조합될 때
   문제가 생기면 이 지점부터 의심할 것.
4. 통합 테스트는 정적 검증(빌드 성공) 수준까지만 했고, 실제 프로세스에서
   `WebEngine::New()` → `LoadUrl` → 렌더까지 실행해서 확인하지는 못했음.
