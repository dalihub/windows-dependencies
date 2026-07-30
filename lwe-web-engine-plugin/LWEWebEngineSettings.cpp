#include "LWEWebEngineSettings.h"

namespace LWEDaliBridge
{

LWEWebEngineSettings::LWEWebEngineSettings(LWE::WebContainer* container)
: mContainer(container)
, mDefaultFontSize(LWE_DEFAULT_FONT_SIZE)
, mJavaScriptEnabled(true)
, mAutoFittingEnabled(true)
, mPluginsEnabled(false)
, mPrivateBrowsingEnabled(false)
, mLinkMagnifierEnabled(false)
, mKeypadWithoutUserActionUsed(true)
, mAutofillPasswordFormEnabled(false)
, mFormCandidateDataEnabled(false)
, mTextSelectionEnabled(true)
, mTextAutosizingEnabled(false)
, mArrowScrollEnabled(true)
, mClipboardEnabled(true)
, mImePanelEnabled(true)
, mImagesLoadedAutomatically(true)
, mZoomForced(false)
, mTextZoomEnabled(true)
, mImeStyle(0)
, mDefaultTextEncodingName("UTF-8")
{
}

void LWEWebEngineSettings::AllowMixedContents(bool) {}

void LWEWebEngineSettings::EnableSpatialNavigation(bool enabled)
{
    LWE::Settings settings = mContainer->GetSettings();
    settings.SetUseSpatialNavigation(enabled);
    mContainer->SetSettings(settings);
}

uint32_t LWEWebEngineSettings::GetDefaultFontSize() const
{
    return mDefaultFontSize;
}

void LWEWebEngineSettings::SetDefaultFontSize(uint32_t size)
{
    mDefaultFontSize = size;
    LWE::Settings settings = mContainer->GetSettings();
    settings.setDefaultFontSize(static_cast<int>(size));
    mContainer->SetSettings(settings);
}

void LWEWebEngineSettings::EnableWebSecurity(bool enabled)
{
    LWE::Settings settings = mContainer->GetSettings();
    settings.SetWebSecurityMode(enabled ? LWE::WebSecurityMode::Enable : LWE::WebSecurityMode::Disable);
    mContainer->SetSettings(settings);
}

void LWEWebEngineSettings::EnableCacheBuilder(bool) {}
void LWEWebEngineSettings::UseScrollbarThumbFocusNotifications(bool) {}
void LWEWebEngineSettings::EnableDoNotTrack(bool) {}
void LWEWebEngineSettings::AllowFileAccessFromExternalUrl(bool) {}

bool LWEWebEngineSettings::IsJavaScriptEnabled() const { return mJavaScriptEnabled; }
void LWEWebEngineSettings::EnableJavaScript(bool enabled) { mJavaScriptEnabled = enabled; }

bool LWEWebEngineSettings::IsAutoFittingEnabled() const { return mAutoFittingEnabled; }
void LWEWebEngineSettings::EnableAutoFitting(bool enabled) { mAutoFittingEnabled = enabled; }

bool LWEWebEngineSettings::ArePluginsEnabled() const { return mPluginsEnabled; }
void LWEWebEngineSettings::EnablePlugins(bool enabled) { mPluginsEnabled = enabled; }

bool LWEWebEngineSettings::IsPrivateBrowsingEnabled() const { return mPrivateBrowsingEnabled; }
void LWEWebEngineSettings::EnablePrivateBrowsing(bool enabled) { mPrivateBrowsingEnabled = enabled; }

bool LWEWebEngineSettings::IsLinkMagnifierEnabled() const { return mLinkMagnifierEnabled; }
void LWEWebEngineSettings::EnableLinkMagnifier(bool enabled) { mLinkMagnifierEnabled = enabled; }

bool LWEWebEngineSettings::IsKeypadWithoutUserActionUsed() const { return mKeypadWithoutUserActionUsed; }
void LWEWebEngineSettings::UseKeypadWithoutUserAction(bool used) { mKeypadWithoutUserActionUsed = used; }

bool LWEWebEngineSettings::IsAutofillPasswordFormEnabled() const { return mAutofillPasswordFormEnabled; }
void LWEWebEngineSettings::EnableAutofillPasswordForm(bool enabled) { mAutofillPasswordFormEnabled = enabled; }

bool LWEWebEngineSettings::IsFormCandidateDataEnabled() const { return mFormCandidateDataEnabled; }
void LWEWebEngineSettings::EnableFormCandidateData(bool enabled) { mFormCandidateDataEnabled = enabled; }

bool LWEWebEngineSettings::IsTextSelectionEnabled() const { return mTextSelectionEnabled; }
void LWEWebEngineSettings::EnableTextSelection(bool enabled) { mTextSelectionEnabled = enabled; }

bool LWEWebEngineSettings::IsTextAutosizingEnabled() const { return mTextAutosizingEnabled; }
void LWEWebEngineSettings::EnableTextAutosizing(bool enabled) { mTextAutosizingEnabled = enabled; }

bool LWEWebEngineSettings::IsArrowScrollEnabled() const { return mArrowScrollEnabled; }
void LWEWebEngineSettings::EnableArrowScroll(bool enable) { mArrowScrollEnabled = enable; }

bool LWEWebEngineSettings::IsClipboardEnabled() const { return mClipboardEnabled; }
void LWEWebEngineSettings::EnableClipboard(bool enabled) { mClipboardEnabled = enabled; }

bool LWEWebEngineSettings::IsImePanelEnabled() const { return mImePanelEnabled; }
void LWEWebEngineSettings::EnableImePanel(bool enabled) { mImePanelEnabled = enabled; }

void LWEWebEngineSettings::AllowScriptsOpenWindows(bool) {}

bool LWEWebEngineSettings::AreImagesLoadedAutomatically() const { return mImagesLoadedAutomatically; }
void LWEWebEngineSettings::AllowImagesLoadAutomatically(bool automatic) { mImagesLoadedAutomatically = automatic; }

std::string LWEWebEngineSettings::GetDefaultTextEncodingName() const { return mDefaultTextEncodingName; }
void LWEWebEngineSettings::SetDefaultTextEncodingName(const std::string& defaultTextEncodingName)
{
    mDefaultTextEncodingName = defaultTextEncodingName;
}

bool LWEWebEngineSettings::SetViewportMetaTag(bool) { return true; }

bool LWEWebEngineSettings::SetForceZoom(bool enable)
{
    mZoomForced = enable;
    return true;
}
bool LWEWebEngineSettings::IsZoomForced() const { return mZoomForced; }

bool LWEWebEngineSettings::SetTextZoomEnabled(bool enable)
{
    mTextZoomEnabled = enable;
    return true;
}
bool LWEWebEngineSettings::IsTextZoomEnabled() const { return mTextZoomEnabled; }

void LWEWebEngineSettings::SetExtraFeature(const std::string& feature, bool enable)
{
    mExtraFeatures[feature] = enable;
}

bool LWEWebEngineSettings::IsExtraFeatureEnabled(const std::string& feature) const
{
    auto it = mExtraFeatures.find(feature);
    return it != mExtraFeatures.end() && it->second;
}

void LWEWebEngineSettings::SetImeStyle(int style) { mImeStyle = style; }
int LWEWebEngineSettings::GetImeStyle() const { return mImeStyle; }

void LWEWebEngineSettings::SetDefaultAudioInputDevice(const std::string&) const {}

void LWEWebEngineSettings::EnableDragAndDrop(bool) {}

} // namespace LWEDaliBridge
