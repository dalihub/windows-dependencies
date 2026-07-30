#include "LWEWebEnginePlugin.h"

#include "DaliInputEventConverter.h"
#include "LWEWebEngineBackForwardList.h"
#include "LWEWebEngineLoadError.h"
#include "LWEWebEngineSettings.h"

#include <dali/devel-api/adaptor-framework/native-image-devel.h>
#include <dali/public-api/adaptor-framework/native-image.h>
#include <dali/public-api/images/pixel.h>
#include <dali/public-api/math/rect.h>
#include <dali/public-api/math/vector2.h>
#include <dali/public-api/math/vector4.h>
#include <dali/public-api/signals/callback.h>

#include <csignal>
#include <cstdarg>
#include <cstdio>

#include <windows.h>
#include <dbghelp.h>

namespace LWEDaliBridge
{
namespace
{
// TEMP DEBUG
void DbgLog(const char* fmt, ...) { FILE* f = fopen("d:\\lwe_webview.log", "a"); if(!f) return; va_list ap; va_start(ap, fmt); vfprintf(f, fmt, ap); va_end(ap); fputc('\n', f); fclose(f); }

// TEMP DEBUG: shared stack walker for the crash/abort hooks below.
void DumpStackFromContext(CONTEXT ctx)
{
    HANDLE proc = GetCurrentProcess();
    SymSetOptions(SYMOPT_LOAD_LINES | SYMOPT_UNDNAME | SYMOPT_DEFERRED_LOADS);
    SymInitialize(proc, NULL, TRUE);

    STACKFRAME64 frame = {};
    frame.AddrPC.Offset    = ctx.Rip; frame.AddrPC.Mode    = AddrModeFlat;
    frame.AddrFrame.Offset = ctx.Rbp; frame.AddrFrame.Mode = AddrModeFlat;
    frame.AddrStack.Offset = ctx.Rsp; frame.AddrStack.Mode = AddrModeFlat;

    char symBuf[sizeof(SYMBOL_INFO) + 512] = {};
    SYMBOL_INFO* sym = reinterpret_cast<SYMBOL_INFO*>(symBuf);
    sym->SizeOfStruct = sizeof(SYMBOL_INFO);
    sym->MaxNameLen   = 500;

    for (int i = 0; i < 40; ++i)
    {
        if (!StackWalk64(IMAGE_FILE_MACHINE_AMD64, proc, GetCurrentThread(), &frame,
                         &ctx, NULL, SymFunctionTableAccess64, SymGetModuleBase64, NULL))
        {
            break;
        }
        DWORD64 addr = frame.AddrPC.Offset;
        if (!addr) break;

        char modName[MAX_PATH] = "?";
        HMODULE mod = NULL;
        if (GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                               (LPCSTR)addr, &mod) && mod)
        {
            GetModuleFileNameA(mod, modName, sizeof(modName));
        }

        DWORD64 disp = 0;
        if (SymFromAddr(proc, addr, &disp, sym))
        {
            DbgLog("[crash]  #%d %s!%s+0x%llx", i, modName, sym->Name, (unsigned long long)disp);
        }
        else
        {
            DWORD64 base = mod ? (DWORD64)mod : 0;
            DbgLog("[crash]  #%d %s+0x%llx", i, modName, (unsigned long long)(addr - base));
        }
    }
}

// TEMP DEBUG: abort() (ucrtbase __fastfail) bypasses vectored exception
// handlers; hook SIGABRT to log the aborting thread's stack first.
void AbortSignalHandler(int)
{
    DbgLog("[abort] SIGABRT on tid=%lu", GetCurrentThreadId());
    CONTEXT ctx = {};
    ctx.ContextFlags = CONTEXT_FULL;
    RtlCaptureContext(&ctx);
    DumpStackFromContext(ctx);
}

// TEMP DEBUG: capture a symbolized stack on the first access violation, then let
// the process crash as usual. Installed once in Create().
LONG WINAPI CrashStackFilter(EXCEPTION_POINTERS* info)
{
    const DWORD code = info->ExceptionRecord->ExceptionCode;
    if (code != EXCEPTION_ACCESS_VIOLATION && code != EXCEPTION_BREAKPOINT &&
        code != 0xC0000374u /* STATUS_HEAP_CORRUPTION */ &&
        code != 0xC0000421u /* STATUS_VERIFIER_STOP (page heap violation) */)
    {
        return EXCEPTION_CONTINUE_SEARCH;
    }
    static bool s_logged = false;
    if (s_logged) return EXCEPTION_CONTINUE_SEARCH; // first fault only
    s_logged = true;
    DbgLog("[crash] code=0x%08lx at %p tid=%lu", (unsigned long)code, info->ExceptionRecord->ExceptionAddress, GetCurrentThreadId());

    HANDLE proc = GetCurrentProcess();
    SymSetOptions(SYMOPT_LOAD_LINES | SYMOPT_UNDNAME | SYMOPT_DEFERRED_LOADS);
    SymInitialize(proc, NULL, TRUE);

    CONTEXT ctx = *info->ContextRecord;
    STACKFRAME64 frame = {};
    frame.AddrPC.Offset    = ctx.Rip; frame.AddrPC.Mode    = AddrModeFlat;
    frame.AddrFrame.Offset = ctx.Rbp; frame.AddrFrame.Mode = AddrModeFlat;
    frame.AddrStack.Offset = ctx.Rsp; frame.AddrStack.Mode = AddrModeFlat;

    char symBuf[sizeof(SYMBOL_INFO) + 512] = {};
    SYMBOL_INFO* sym = reinterpret_cast<SYMBOL_INFO*>(symBuf);
    sym->SizeOfStruct = sizeof(SYMBOL_INFO);
    sym->MaxNameLen   = 500;

    for (int i = 0; i < 40; ++i)
    {
        if (!StackWalk64(IMAGE_FILE_MACHINE_AMD64, proc, GetCurrentThread(), &frame,
                         &ctx, NULL, SymFunctionTableAccess64, SymGetModuleBase64, NULL))
        {
            break;
        }
        DWORD64 addr = frame.AddrPC.Offset;
        if (!addr) break;

        char modName[MAX_PATH] = "?";
        HMODULE mod = NULL;
        if (GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                               (LPCSTR)addr, &mod) && mod)
        {
            GetModuleFileNameA(mod, modName, sizeof(modName)); // full path (kernel32, no psapi)
        }

        DWORD64 disp = 0;
        if (SymFromAddr(proc, addr, &disp, sym))
        {
            DbgLog("[crash]  #%d %s!%s+0x%llx", i, modName, sym->Name, (unsigned long long)disp);
        }
        else
        {
            DWORD64 base = mod ? (DWORD64)mod : 0;
            DbgLog("[crash]  #%d %s+0x%llx", i, modName, (unsigned long long)(addr - base));
        }
    }
    return EXCEPTION_CONTINUE_SEARCH;
}

constexpr char kStorageDirectory[] = "./lwe_dali_plugin_storage";

// LWE's Cairo-based Windows canvas backend renders into CAIRO_FORMAT_ARGB32, which is
// laid out as BGRA in memory on little-endian Windows - see README.md for the caveat
// that this hasn't been visually verified.
constexpr Dali::Pixel::Format kRenderBufferPixelFormat = Dali::Pixel::BGRA8888;
constexpr uint32_t            kBytesPerPixel           = 4;
} // namespace

LWEWebEnginePlugin::LWEWebEnginePlugin()
: mContainer(nullptr)
, mPageZoomFactor(1.0f)
, mTextZoomFactor(1.0f)
, mScaleFactor(1.0f)
, mIncognito(false)
{
}

LWEWebEnginePlugin::~LWEWebEnginePlugin()
{
    Destroy();
}

void LWEWebEnginePlugin::EnsureInitialized(const std::string& locale, const std::string& timezoneId)
{
    if (!LWE::LWE::IsInitialized())
    {
        // PreferSeparateThread: LWE runs on its own dedicated thread with its own
        // Win32 message queue (MessageLoopWindows::run). This keeps LWE's messages off
        // the DALi/SDL main-thread queue (which would otherwise consume and drop them),
        // and lets rendering advance without the host pumping anything. The only DALi
        // work is marshalled back to the main thread via mEventThreadCallback.
        LWE::LWE::Initialize(kStorageDirectory, LWE::InitializeOption::PreferSeparateThread);
    }
}

void LWEWebEnginePlugin::Create(uint32_t width, uint32_t height, const std::string& locale, const std::string& timezoneId)
{
    DbgLog("[LWE] Create %ux%u locale=%s tz=%s", width, height, locale.c_str(), timezoneId.c_str());
    static bool s_crashFilterInstalled = false;
    if (!s_crashFilterInstalled)
    {
        s_crashFilterInstalled = true;
        AddVectoredExceptionHandler(1 /*first*/, CrashStackFilter);
        signal(SIGABRT, AbortSignalHandler); // TEMP DEBUG: see AbortSignalHandler
    }
    DbgLog("[LWE] Create: before EnsureInitialized");
    EnsureInitialized(locale, timezoneId);
    DbgLog("[LWE] Create: after EnsureInitialized, before WebContainer::Create");
    mContainer = LWE::WebContainer::Create(width, height, 1.0f, "sans-serif", locale.c_str(), timezoneId.c_str());
    DbgLog("[LWE] Create: after WebContainer::Create container=%p", (void*)mContainer);
    mSettings       = std::make_unique<LWEWebEngineSettings>(mContainer);
    mBackForwardList = std::make_unique<LWEWebEngineBackForwardList>();

    mWidth.store(width);
    mHeight.store(height);

    // Constructed on the DALi main thread (required by EventThreadCallback). LWE's
    // render thread calls Trigger(); DALi then runs OnFrameReadyMainThread on the main
    // thread.
    mEventThreadCallback = std::make_unique<Dali::EventThreadCallback>(
        Dali::MakeCallback(this, &LWEWebEnginePlugin::OnFrameReadyMainThread));

    // Both handlers below run on LWE's render thread. They must not touch any DALi
    // object; they only manage plugin-owned CPU buffers and signal the main thread.
    mContainer->RegisterPreRenderingHandler([this]() -> LWE::WebContainer::RenderInfo {
        const uint32_t w = mWidth.load();
        const uint32_t h = mHeight.load();
        const size_t   needed = static_cast<size_t>(w) * h * kBytesPerPixel;
        if (mRenderBuffer.size() != needed)
        {
            mRenderBuffer.assign(needed, 0); // (re)sized only here, on the LWE thread
        }
        LWE::WebContainer::RenderInfo info;
        info.updatedBufferAddress = mRenderBuffer.data();
        info.bufferStride         = static_cast<size_t>(w) * kBytesPerPixel;
        return info;
    });
    mContainer->RegisterOnRenderedHandler([this](LWE::WebContainer*, const LWE::WebContainer::RenderResult&) {
        DbgLog("[LWE] OnRendered(LWE thread) enter renderBuf=%zu", mRenderBuffer.size());
        {
            std::lock_guard<std::mutex> lock(mBufferMutex);
            mReadyBuffer  = mRenderBuffer;
            mReadyWidth   = mWidth.load();
            mReadyHeight  = mHeight.load();
        }
        if (mEventThreadCallback)
        {
            mEventThreadCallback->Trigger();
        }
        DbgLog("[LWE] OnRendered(LWE thread) triggered");
    });
}

void LWEWebEnginePlugin::Create(uint32_t width, uint32_t height, uint32_t, char**)
{
    Create(width, height, "en-US", "UTC");
}

void LWEWebEnginePlugin::OnFrameReadyMainThread()
{
    DbgLog("[LWE] OnFrameReadyMainThread(main) enter");
    uint32_t w = 0, h = 0;
    {
        std::lock_guard<std::mutex> lock(mBufferMutex);
        w = mReadyWidth;
        h = mReadyHeight;
        if (w == 0 || h == 0 || mReadyBuffer.size() != static_cast<size_t>(w) * h * kBytesPerPixel)
        {
            return;
        }
        if (!mNativeImage || mImageWidth != w || mImageHeight != h)
        {
            mNativeImage = Dali::NativeImage::New(w, h, Dali::NativeImage::COLOR_DEPTH_32);
            mImageWidth  = w;
            mImageHeight = h;
        }
        {
            const size_t cx = (static_cast<size_t>(h) / 2) * (static_cast<size_t>(w) * kBytesPerPixel) + (static_cast<size_t>(w) / 2) * kBytesPerPixel;
            const uint8_t* p0 = mReadyBuffer.data();
            const uint8_t* pc = mReadyBuffer.data() + cx;
            DbgLog("[LWE] pixels px0=[%02x %02x %02x %02x] center=[%02x %02x %02x %02x]",
                   p0[0], p0[1], p0[2], p0[3], pc[0], pc[1], pc[2], pc[3]);
        }
        DbgLog("[LWE] OnFrameReadyMainThread SetPixels %ux%u img=%p", w, h, (void*)mNativeImage.Get());
        Dali::DevelNativeImage::SetPixels(*mNativeImage, mReadyBuffer.data(), kRenderBufferPixelFormat);
    }
    // WebViewImpl only (re)creates its image visual in response to this callback.
    if (mFrameRenderedCallback)
    {
        mFrameRenderedCallback();
    }
    DbgLog("[LWE] OnFrameReadyMainThread done cb=%d", (int)(bool)mFrameRenderedCallback);
}

void LWEWebEnginePlugin::Destroy()
{
    if (mContainer)
    {
        mContainer->Destroy();
        mContainer = nullptr;
    }
}

bool LWEWebEnginePlugin::IsIncognito() const { return mIncognito; }

Dali::WebEngineSettings& LWEWebEnginePlugin::GetSettings() const { return *mSettings; }

Dali::WebEngineBackForwardList& LWEWebEnginePlugin::GetBackForwardList() const { return *mBackForwardList; }

void LWEWebEnginePlugin::LoadUrl(const std::string& url) { mContainer->LoadURL(url); }

std::string LWEWebEnginePlugin::GetTitle() const { return mContainer->GetTitle(); }

Dali::PixelData LWEWebEnginePlugin::GetFavicon() const
{
    // LWE has no favicon API; requires Dali::PixelData::New(), which is only
    // implemented in dali-core.lib (not linked here - see plugins/web-engine-lwe/README.md).
    return Dali::PixelData();
}

Dali::NativeImagePtr LWEWebEnginePlugin::GetNativeImage()
{
    return mNativeImage;
}

void LWEWebEnginePlugin::ChangeOrientation(int) {}

std::string LWEWebEnginePlugin::GetUrl() const { return mContainer->GetURL(); }

void LWEWebEnginePlugin::LoadHtmlString(const std::string& htmlString) { mContainer->LoadData(htmlString); }

bool LWEWebEnginePlugin::LoadHtmlStringOverrideCurrentEntry(const std::string& html, const std::string&, const std::string&)
{
    mContainer->LoadData(html);
    return true;
}

bool LWEWebEnginePlugin::LoadContents(const int8_t*, uint32_t, const std::string&, const std::string&, const std::string&)
{
    return false;
}

void LWEWebEnginePlugin::Reload() { mContainer->Reload(); }

bool LWEWebEnginePlugin::ReloadWithoutCache()
{
    mContainer->Reload();
    return true;
}

void LWEWebEnginePlugin::StopLoading() { mContainer->StopLoading(); }
void LWEWebEnginePlugin::Suspend() { mContainer->Pause(); }
void LWEWebEnginePlugin::Resume() { mContainer->Resume(); }
void LWEWebEnginePlugin::SuspendNetworkLoading() {}
void LWEWebEnginePlugin::ResumeNetworkLoading() {}
bool LWEWebEnginePlugin::AddCustomHeader(const std::string&, const std::string&) { return false; }
bool LWEWebEnginePlugin::RemoveCustomHeader(const std::string&) { return false; }
uint32_t LWEWebEnginePlugin::StartInspectorServer(uint32_t) { return 0; }
bool LWEWebEnginePlugin::StopInspectorServer() { return false; }

void LWEWebEnginePlugin::ScrollBy(int32_t deltaX, int32_t deltaY) { mContainer->ScrollBy(deltaX, deltaY); }
bool LWEWebEnginePlugin::ScrollEdgeBy(int32_t, int32_t) { return false; }
void LWEWebEnginePlugin::SetScrollPosition(int32_t x, int32_t y) { mContainer->ScrollTo(x, y); }

Dali::Vector2 LWEWebEnginePlugin::GetScrollPosition() const
{
    return Dali::Vector2(static_cast<float>(mContainer->GetScrollX()), static_cast<float>(mContainer->GetScrollY()));
}

Dali::Vector2 LWEWebEnginePlugin::GetScrollSize() const
{
    return Dali::Vector2(static_cast<float>(mContainer->Width()), static_cast<float>(mContainer->Height()));
}

Dali::Vector2 LWEWebEnginePlugin::GetContentSize() const
{
    return Dali::Vector2(static_cast<float>(mContainer->Width()), static_cast<float>(mContainer->Height()));
}

bool LWEWebEnginePlugin::CanGoForward() { return mContainer->CanGoForward(); }
void LWEWebEnginePlugin::GoForward() { mContainer->GoForward(); }
bool LWEWebEnginePlugin::CanGoBack() { return mContainer->CanGoBack(); }
void LWEWebEnginePlugin::GoBack() { mContainer->GoBack(); }

void LWEWebEnginePlugin::EvaluateJavaScript(const std::string& script, JavaScriptMessageHandlerCallback resultHandler)
{
    mContainer->EvaluateJavaScript(script, [resultHandler](const std::string& result) {
        if (resultHandler)
        {
            resultHandler(result);
        }
    });
}

void LWEWebEnginePlugin::AddJavaScriptMessageHandler(const std::string& exposedObjectName, JavaScriptMessageHandlerCallback handler)
{
    mContainer->AddJavaScriptInterface(exposedObjectName, "postMessage", [handler](const std::string& message) -> std::string {
        if (handler)
        {
            handler(message);
        }
        return "";
    });
}

void LWEWebEnginePlugin::AddJavaScriptEntireMessageHandler(const std::string& exposedObjectName, JavaScriptEntireMessageHandlerCallback handler)
{
    mContainer->AddJavaScriptInterface(exposedObjectName, "postMessage", [handler](const std::string& message) -> std::string {
        if (handler)
        {
            handler("", message);
        }
        return "";
    });
}

void LWEWebEnginePlugin::RegisterJavaScriptAlertCallback(JavaScriptAlertCallback callback)
{
    mContainer->RegisterShowAlertHandler([callback](LWE::WebContainer*, const std::string&, const std::string& message) {
        if (callback)
        {
            callback(message);
        }
    });
}

void LWEWebEnginePlugin::JavaScriptAlertReply() {}

void LWEWebEnginePlugin::RegisterJavaScriptConfirmCallback(JavaScriptConfirmCallback) {}
void LWEWebEnginePlugin::JavaScriptConfirmReply(bool) {}
void LWEWebEnginePlugin::RegisterJavaScriptPromptCallback(JavaScriptPromptCallback) {}
void LWEWebEnginePlugin::JavaScriptPromptReply(const std::string&) {}

std::unique_ptr<Dali::WebEngineHitTest> LWEWebEnginePlugin::CreateHitTest(int32_t, int32_t, Dali::WebEngineHitTest::HitTestMode)
{
    return nullptr;
}

bool LWEWebEnginePlugin::CreateHitTestAsynchronously(int32_t, int32_t, Dali::WebEngineHitTest::HitTestMode, WebEngineHitTestCreatedCallback)
{
    return false;
}

void LWEWebEnginePlugin::ClearHistory() { mContainer->ClearHistory(); }
void LWEWebEnginePlugin::ClearAllTilesResources() {}

std::string LWEWebEnginePlugin::GetUserAgent() const { return mUserAgent; }

void LWEWebEnginePlugin::SetUserAgent(const std::string& userAgent)
{
    mUserAgent = userAgent;
    mContainer->SetUserAgentString(userAgent);
}

void LWEWebEnginePlugin::SetSize(uint32_t width, uint32_t height)
{
    // Only publish the new desired size (atomic). The LWE render thread resizes
    // mRenderBuffer in its PreRendering handler, and the main thread recreates
    // mNativeImage in OnFrameReadyMainThread when the arriving frame size changes -
    // so neither buffer nor image is reallocated from the wrong thread.
    mWidth.store(width);
    mHeight.store(height);
    mContainer->ResizeTo(width, height);
}
void LWEWebEnginePlugin::SetDocumentBackgroundColor(Dali::Vector4) {}
void LWEWebEnginePlugin::ClearTilesWhenHidden(bool) {}
void LWEWebEnginePlugin::SetTileCoverAreaMultiplier(float) {}
void LWEWebEnginePlugin::EnableCursorByClient(bool) {}
std::string LWEWebEnginePlugin::GetSelectedText() const { return ""; }

bool LWEWebEnginePlugin::SendTouchEvent(const Dali::TouchEvent& touch)
{
    DispatchTouchEvent(mContainer, touch);
    return true;
}

bool LWEWebEnginePlugin::SendKeyEvent(const Dali::KeyEvent& event)
{
    DispatchKeyEvent(mContainer, event);
    return true;
}

void LWEWebEnginePlugin::EnableMouseEvents(bool) {}
void LWEWebEnginePlugin::EnableKeyEvents(bool) {}
void LWEWebEnginePlugin::SetFocus(bool focused)
{
    if (focused)
    {
        mContainer->Focus();
    }
    else
    {
        mContainer->Blur();
    }
}
bool LWEWebEnginePlugin::SetImePositionAndAlignment(Dali::Vector2, int) { return false; }
void LWEWebEnginePlugin::SetCursorThemeName(const std::string) {}

void LWEWebEnginePlugin::SetPageZoomFactor(float zoomFactor) { mPageZoomFactor = zoomFactor; }
float LWEWebEnginePlugin::GetPageZoomFactor() const { return mPageZoomFactor; }
void LWEWebEnginePlugin::SetTextZoomFactor(float zoomFactor) { mTextZoomFactor = zoomFactor; }
float LWEWebEnginePlugin::GetTextZoomFactor() const { return mTextZoomFactor; }
float LWEWebEnginePlugin::GetLoadProgressPercentage() const { return 0.0f; }
void LWEWebEnginePlugin::SetScaleFactor(float scaleFactor, Dali::Vector2) { mScaleFactor = scaleFactor; }
float LWEWebEnginePlugin::GetScaleFactor() const { return mScaleFactor; }
void LWEWebEnginePlugin::ActivateAccessibility(bool) {}

Dali::Devel::Accessibility::Address LWEWebEnginePlugin::GetAccessibilityAddress()
{
    return Dali::Devel::Accessibility::Address();
}

bool LWEWebEnginePlugin::SetVisibility(bool) { return true; }
bool LWEWebEnginePlugin::HighlightText(const std::string&, FindOption, uint32_t) { return false; }
void LWEWebEnginePlugin::AddDynamicCertificatePath(const std::string&, const std::string&) {}

Dali::PixelData LWEWebEnginePlugin::GetScreenshot(Dali::BoundsInteger, float)
{
    // Requires Dali::PixelData::New() from dali-core.lib; see plugins/web-engine-lwe/README.md.
    return Dali::PixelData();
}

bool LWEWebEnginePlugin::GetScreenshotAsynchronously(Dali::BoundsInteger, float, ScreenshotCapturedCallback) { return false; }
bool LWEWebEnginePlugin::CheckVideoPlayingAsynchronously(VideoPlayingCallback) { return false; }
void LWEWebEnginePlugin::RegisterGeolocationPermissionCallback(GeolocationPermissionCallback) {}
void LWEWebEnginePlugin::UpdateDisplayArea(Dali::BoundsInteger displayArea) { SetSize(displayArea.width, displayArea.height); }
void LWEWebEnginePlugin::EnableVideoHole(bool) {}

bool LWEWebEnginePlugin::SendHoverEvent(const Dali::HoverEvent& event)
{
    DispatchHoverEvent(mContainer, event);
    return true;
}

bool LWEWebEnginePlugin::SendWheelEvent(const Dali::WheelEvent& event)
{
    DispatchWheelEvent(mContainer, event);
    return true;
}

void LWEWebEnginePlugin::ExitFullscreen() {}
void LWEWebEnginePlugin::RegisterFrameRenderedCallback(WebEngineFrameRenderedCallback callback)
{
    mFrameRenderedCallback = callback;
}

void LWEWebEnginePlugin::RegisterPageLoadStartedCallback(WebEnginePageLoadCallback callback)
{
    mContainer->RegisterOnPageStartedHandler([callback](LWE::WebContainer*, const std::string& url) {
        if (callback)
        {
            callback(url);
        }
    });
}

void LWEWebEnginePlugin::RegisterPageLoadInProgressCallback(WebEnginePageLoadCallback) {}

void LWEWebEnginePlugin::RegisterPageLoadFinishedCallback(WebEnginePageLoadCallback callback)
{
    mContainer->RegisterOnPageLoadedHandler([callback](LWE::WebContainer*, const std::string& url) {
        if (callback)
        {
            callback(url);
        }
    });
}

void LWEWebEnginePlugin::RegisterPageLoadErrorCallback(WebEnginePageLoadErrorCallback callback)
{
    mContainer->RegisterOnReceivedErrorHandler([callback](LWE::WebContainer*, LWE::ResourceError error) {
        if (callback)
        {
            callback(std::make_unique<LWEWebEngineLoadError>(error));
        }
    });
}

void LWEWebEnginePlugin::RegisterScrollEdgeReachedCallback(WebEngineScrollEdgeReachedCallback) {}
void LWEWebEnginePlugin::RegisterOverScrolledCallback(WebEngineOverScrolledCallback) {}

void LWEWebEnginePlugin::RegisterUrlChangedCallback(WebEngineUrlChangedCallback callback)
{
    mContainer->RegisterOnPageStartedHandler([callback](LWE::WebContainer*, const std::string& url) {
        if (callback)
        {
            callback(url);
        }
    });
}

void LWEWebEnginePlugin::RegisterFormRepostDecidedCallback(WebEngineFormRepostDecidedCallback) {}
void LWEWebEnginePlugin::RegisterConsoleMessageReceivedCallback(WebEngineConsoleMessageReceivedCallback) {}
void LWEWebEnginePlugin::RegisterResponsePolicyDecidedCallback(WebEngineResponsePolicyDecidedCallback) {}
void LWEWebEnginePlugin::RegisterNavigationPolicyDecidedCallback(WebEngineNavigationPolicyDecidedCallback) {}
void LWEWebEnginePlugin::RegisterNewWindowPolicyDecidedCallback(WebEngineNewWindowPolicyDecidedCallback) {}
void LWEWebEnginePlugin::RegisterNewWindowCreatedCallback(WebEngineNewWindowCreatedCallback) {}
void LWEWebEnginePlugin::RegisterCertificateConfirmedCallback(WebEngineCertificateCallback) {}
void LWEWebEnginePlugin::RegisterSslCertificateChangedCallback(WebEngineCertificateCallback) {}
void LWEWebEnginePlugin::RegisterHttpAuthHandlerCallback(WebEngineHttpAuthHandlerCallback) {}
void LWEWebEnginePlugin::RegisterContextMenuShownCallback(WebEngineContextMenuShownCallback) {}
void LWEWebEnginePlugin::RegisterContextMenuHiddenCallback(WebEngineContextMenuHiddenCallback) {}
void LWEWebEnginePlugin::RegisterFullscreenEnteredCallback(WebEngineFullscreenEnteredCallback) {}
void LWEWebEnginePlugin::RegisterFullscreenExitedCallback(WebEngineFullscreenExitedCallback) {}
void LWEWebEnginePlugin::RegisterTextFoundCallback(WebEngineTextFoundCallback) {}
void LWEWebEnginePlugin::GetPlainTextAsynchronously(PlainTextReceivedCallback) {}
void LWEWebEnginePlugin::WebAuthenticationCancel() {}
void LWEWebEnginePlugin::RegisterWebAuthDisplayQRCallback(WebEngineWebAuthDisplayQRCallback) {}
void LWEWebEnginePlugin::RegisterWebAuthResponseCallback(WebEngineWebAuthResponseCallback) {}
void LWEWebEnginePlugin::RegisterFileChooserRequestedCallback(WebEngineFileChooserRequestedCallback) {}
void LWEWebEnginePlugin::RegisterWebProcessCrashedCallback(WebEngineWebProcessCrashedCallback) {}
void LWEWebEnginePlugin::RegisterUserMediaPermissionRequestCallback(WebEngineUserMediaPermissionRequestCallback) {}
void LWEWebEnginePlugin::RegisterDeviceConnectionChangedCallback(WebEngineDeviceConnectionChangedCallback) {}
void LWEWebEnginePlugin::RegisterDeviceListGetCallback(WebEngineDeviceListGetCallback) {}

void LWEWebEnginePlugin::FeedMouseWheel(bool, int step, int x, int y)
{
    mContainer->DispatchMouseWheelEvent(x, y, step);
}

void LWEWebEnginePlugin::SetVideoHole(bool, bool) {}

} // namespace LWEDaliBridge
