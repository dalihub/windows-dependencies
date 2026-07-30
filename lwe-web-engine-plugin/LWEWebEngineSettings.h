#ifndef DALI_LWE_WEB_ENGINE_SETTINGS_H
#define DALI_LWE_WEB_ENGINE_SETTINGS_H

#include <LWEWebView.h>
#include <dali/devel-api/adaptor-framework/web-engine/web-engine-settings.h>

#include <map>
#include <string>

namespace LWEDaliBridge
{
// Wraps LWE::Settings for the subset of WebEngineSettings that LWE actually
// supports (spatial navigation, web security mode, default font size). The
// rest have no LWE counterpart and are tracked here only so the getters
// return whatever was last set; see plugins/web-engine-lwe/README.md.
class LWEWebEngineSettings : public Dali::WebEngineSettings
{
public:
    explicit LWEWebEngineSettings(LWE::WebContainer* container);

    void AllowMixedContents(bool allowed) override;
    void EnableSpatialNavigation(bool enabled) override;
    uint32_t GetDefaultFontSize() const override;
    void SetDefaultFontSize(uint32_t size) override;
    void EnableWebSecurity(bool enabled) override;
    void EnableCacheBuilder(bool enabled) override;
    void UseScrollbarThumbFocusNotifications(bool used) override;
    void EnableDoNotTrack(bool enabled) override;
    void AllowFileAccessFromExternalUrl(bool allowed) override;
    bool IsJavaScriptEnabled() const override;
    void EnableJavaScript(bool enabled) override;
    bool IsAutoFittingEnabled() const override;
    void EnableAutoFitting(bool enabled) override;
    bool ArePluginsEnabled() const override;
    void EnablePlugins(bool enabled) override;
    bool IsPrivateBrowsingEnabled() const override;
    void EnablePrivateBrowsing(bool enabled) override;
    bool IsLinkMagnifierEnabled() const override;
    void EnableLinkMagnifier(bool enabled) override;
    bool IsKeypadWithoutUserActionUsed() const override;
    void UseKeypadWithoutUserAction(bool used) override;
    bool IsAutofillPasswordFormEnabled() const override;
    void EnableAutofillPasswordForm(bool enabled) override;
    bool IsFormCandidateDataEnabled() const override;
    void EnableFormCandidateData(bool enabled) override;
    bool IsTextSelectionEnabled() const override;
    void EnableTextSelection(bool enabled) override;
    bool IsTextAutosizingEnabled() const override;
    void EnableTextAutosizing(bool enabled) override;
    bool IsArrowScrollEnabled() const override;
    void EnableArrowScroll(bool enable) override;
    bool IsClipboardEnabled() const override;
    void EnableClipboard(bool enabled) override;
    bool IsImePanelEnabled() const override;
    void EnableImePanel(bool enabled) override;
    void AllowScriptsOpenWindows(bool allowed) override;
    bool AreImagesLoadedAutomatically() const override;
    void AllowImagesLoadAutomatically(bool automatic) override;
    std::string GetDefaultTextEncodingName() const override;
    void SetDefaultTextEncodingName(const std::string& defaultTextEncodingName) override;
    bool SetViewportMetaTag(bool enable) override;
    bool SetForceZoom(bool enable) override;
    bool IsZoomForced() const override;
    bool SetTextZoomEnabled(bool enable) override;
    bool IsTextZoomEnabled() const override;
    void SetExtraFeature(const std::string& feature, bool enable) override;
    bool IsExtraFeatureEnabled(const std::string& feature) const override;
    void SetImeStyle(int style) override;
    int GetImeStyle() const override;
    void SetDefaultAudioInputDevice(const std::string& deviceId) const override;
    void EnableDragAndDrop(bool enable) override;

private:
    LWE::WebContainer* mContainer;
    uint32_t mDefaultFontSize;
    bool mJavaScriptEnabled;
    bool mAutoFittingEnabled;
    bool mPluginsEnabled;
    bool mPrivateBrowsingEnabled;
    bool mLinkMagnifierEnabled;
    bool mKeypadWithoutUserActionUsed;
    bool mAutofillPasswordFormEnabled;
    bool mFormCandidateDataEnabled;
    bool mTextSelectionEnabled;
    bool mTextAutosizingEnabled;
    bool mArrowScrollEnabled;
    bool mClipboardEnabled;
    bool mImePanelEnabled;
    bool mImagesLoadedAutomatically;
    bool mZoomForced;
    bool mTextZoomEnabled;
    int mImeStyle;
    std::string mDefaultTextEncodingName;
    std::map<std::string, bool> mExtraFeatures;
};

} // namespace LWEDaliBridge

#endif // DALI_LWE_WEB_ENGINE_SETTINGS_H
