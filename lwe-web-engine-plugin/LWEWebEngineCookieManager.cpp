#include "LWEWebEngineCookieManager.h"

#include <LWEWebView.h>

namespace LWEDaliBridge
{

void LWEWebEngineCookieManager::SetCookieAcceptPolicy(CookieAcceptPolicy policy)
{
    mAcceptPolicy = policy;
}

Dali::WebEngineCookieManager::CookieAcceptPolicy LWEWebEngineCookieManager::GetCookieAcceptPolicy() const
{
    return mAcceptPolicy;
}

void LWEWebEngineCookieManager::ClearCookies()
{
    LWE::CookieManager::GetInstance()->ClearCookies();
}

void LWEWebEngineCookieManager::SetPersistentStorage(const std::string&, CookiePersistentStorage) {}

void LWEWebEngineCookieManager::ChangesWatch(WebEngineCookieManagerChangesWatchCallback) {}

} // namespace LWEDaliBridge
