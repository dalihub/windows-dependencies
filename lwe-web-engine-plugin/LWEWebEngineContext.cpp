#include "LWEWebEngineContext.h"

namespace LWEDaliBridge
{

LWEWebEngineContext::LWEWebEngineContext()
: mCacheModel(CacheModel::DOCUMENT_VIEWER)
, mCacheEnabled(true)
, mDefaultZoomFactor(1.0f)
{
}

Dali::WebEngineContext::CacheModel LWEWebEngineContext::GetCacheModel() const { return mCacheModel; }
void LWEWebEngineContext::SetCacheModel(CacheModel cacheModel) { mCacheModel = cacheModel; }
void LWEWebEngineContext::SetProxyUri(const std::string& uri) { mProxyUri = uri; }
std::string LWEWebEngineContext::GetProxyUri() const { return mProxyUri; }
void LWEWebEngineContext::SetDefaultProxyAuth(const std::string&, const std::string&) {}
void LWEWebEngineContext::SetProxyBypassRule(const std::string&, const std::string& bypass) { mProxyBypassRule = bypass; }
std::string LWEWebEngineContext::GetProxyBypassRule() const { return mProxyBypassRule; }
void LWEWebEngineContext::SetCertificateFilePath(const std::string& certificatePath) { mCertificateFilePath = certificatePath; }
std::string LWEWebEngineContext::GetCertificateFilePath() const { return mCertificateFilePath; }
void LWEWebEngineContext::DeleteAllWebDatabase() {}
bool LWEWebEngineContext::GetWebDatabaseOrigins(WebEngineSecurityOriginAcquiredCallback) { return false; }
bool LWEWebEngineContext::DeleteWebDatabase(Dali::WebEngineSecurityOrigin&) { return false; }
bool LWEWebEngineContext::GetWebStorageOrigins(WebEngineSecurityOriginAcquiredCallback) { return false; }
bool LWEWebEngineContext::GetWebStorageUsageForOrigin(Dali::WebEngineSecurityOrigin&, WebEngineStorageUsageAcquiredCallback) { return false; }
void LWEWebEngineContext::DeleteAllWebStorage() {}
bool LWEWebEngineContext::DeleteWebStorage(Dali::WebEngineSecurityOrigin&) { return false; }
void LWEWebEngineContext::DeleteLocalFileSystem() {}
void LWEWebEngineContext::ClearCache() {}
bool LWEWebEngineContext::DeleteApplicationCache(Dali::WebEngineSecurityOrigin&) { return false; }
void LWEWebEngineContext::GetFormPasswordList(WebEngineFormPasswordAcquiredCallback) {}
void LWEWebEngineContext::RegisterDownloadStartedCallback(WebEngineDownloadStartedCallback) {}
void LWEWebEngineContext::RegisterMimeOverriddenCallback(WebEngineMimeOverriddenCallback) {}
void LWEWebEngineContext::RegisterRequestInterceptedCallback(WebEngineRequestInterceptedCallback) {}
void LWEWebEngineContext::EnableCache(bool cacheEnabled) { mCacheEnabled = cacheEnabled; }
bool LWEWebEngineContext::IsCacheEnabled() const { return mCacheEnabled; }
void LWEWebEngineContext::SetAppId(const std::string&) {}
bool LWEWebEngineContext::SetAppVersion(const std::string&) { return true; }
void LWEWebEngineContext::SetApplicationType(const ApplicationType) {}
void LWEWebEngineContext::SetTimeOffset(float) {}
void LWEWebEngineContext::SetTimeZoneOffset(float, float) {}
void LWEWebEngineContext::SetDefaultZoomFactor(float zoomFactor) { mDefaultZoomFactor = zoomFactor; }
float LWEWebEngineContext::GetDefaultZoomFactor() const { return mDefaultZoomFactor; }
void LWEWebEngineContext::RegisterUrlSchemesAsCorsEnabled(const std::vector<std::string>&) {}
void LWEWebEngineContext::RegisterJsPluginMimeTypes(const std::vector<std::string>&) {}
bool LWEWebEngineContext::DeleteAllApplicationCache() { return true; }
bool LWEWebEngineContext::DeleteAllWebIndexedDatabase() { return true; }
void LWEWebEngineContext::DeleteFormPasswordDataList(const std::vector<std::string>&) {}
void LWEWebEngineContext::DeleteAllFormPasswordData() {}
void LWEWebEngineContext::DeleteAllFormCandidateData() {}
bool LWEWebEngineContext::FreeUnusedMemory() { return true; }

} // namespace LWEDaliBridge
