#ifndef DALI_LWE_WEB_ENGINE_CONTEXT_H
#define DALI_LWE_WEB_ENGINE_CONTEXT_H

#include <dali/devel-api/adaptor-framework/web-engine/web-engine-context.h>

namespace LWEDaliBridge
{
// LWE has no context-level API (proxy/cache/storage/etc. are all per-WebContainer,
// see LWEWebEnginePlugin) so this only stores whatever the caller last set, with no
// effect on any actual WebContainer; see plugins/web-engine-lwe/README.md.
class LWEWebEngineContext : public Dali::WebEngineContext
{
public:
    LWEWebEngineContext();

    CacheModel GetCacheModel() const override;
    void SetCacheModel(CacheModel cacheModel) override;
    void SetProxyUri(const std::string& uri) override;
    std::string GetProxyUri() const override;
    void SetDefaultProxyAuth(const std::string& username, const std::string& password) override;
    void SetProxyBypassRule(const std::string& proxy, const std::string& bypass) override;
    std::string GetProxyBypassRule() const override;
    void SetCertificateFilePath(const std::string& certificatePath) override;
    std::string GetCertificateFilePath() const override;
    void DeleteAllWebDatabase() override;
    bool GetWebDatabaseOrigins(WebEngineSecurityOriginAcquiredCallback callback) override;
    bool DeleteWebDatabase(Dali::WebEngineSecurityOrigin& origin) override;
    bool GetWebStorageOrigins(WebEngineSecurityOriginAcquiredCallback callback) override;
    bool GetWebStorageUsageForOrigin(Dali::WebEngineSecurityOrigin& origin, WebEngineStorageUsageAcquiredCallback callback) override;
    void DeleteAllWebStorage() override;
    bool DeleteWebStorage(Dali::WebEngineSecurityOrigin& origin) override;
    void DeleteLocalFileSystem() override;
    void ClearCache() override;
    bool DeleteApplicationCache(Dali::WebEngineSecurityOrigin& origin) override;
    void GetFormPasswordList(WebEngineFormPasswordAcquiredCallback callback) override;
    void RegisterDownloadStartedCallback(WebEngineDownloadStartedCallback callback) override;
    void RegisterMimeOverriddenCallback(WebEngineMimeOverriddenCallback callback) override;
    void RegisterRequestInterceptedCallback(WebEngineRequestInterceptedCallback callback) override;
    void EnableCache(bool cacheEnabled) override;
    bool IsCacheEnabled() const override;
    void SetAppId(const std::string& appId) override;
    bool SetAppVersion(const std::string& appVersion) override;
    void SetApplicationType(const ApplicationType applicationType) override;
    void SetTimeOffset(float timeOffset) override;
    void SetTimeZoneOffset(float timeZoneOffset, float daylightSavingTime) override;
    void SetDefaultZoomFactor(float zoomFactor) override;
    float GetDefaultZoomFactor() const override;
    void RegisterUrlSchemesAsCorsEnabled(const std::vector<std::string>& schemes) override;
    void RegisterJsPluginMimeTypes(const std::vector<std::string>& mimeTypes) override;
    bool DeleteAllApplicationCache() override;
    bool DeleteAllWebIndexedDatabase() override;
    void DeleteFormPasswordDataList(const std::vector<std::string>& list) override;
    void DeleteAllFormPasswordData() override;
    void DeleteAllFormCandidateData() override;
    bool FreeUnusedMemory() override;

private:
    CacheModel   mCacheModel;
    std::string  mProxyUri;
    std::string  mProxyBypassRule;
    std::string  mCertificateFilePath;
    bool         mCacheEnabled;
    float        mDefaultZoomFactor;
};

} // namespace LWEDaliBridge

#endif // DALI_LWE_WEB_ENGINE_CONTEXT_H
