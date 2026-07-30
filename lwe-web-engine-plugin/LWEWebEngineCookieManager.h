#ifndef DALI_LWE_WEB_ENGINE_COOKIE_MANAGER_H
#define DALI_LWE_WEB_ENGINE_COOKIE_MANAGER_H

#include <dali/devel-api/adaptor-framework/web-engine/web-engine-cookie-manager.h>

namespace LWEDaliBridge
{
// Wraps LWE::CookieManager (a process-wide singleton), which only supports
// GetCookie/HasCookies/ClearCookies - accept policy and persistent storage have
// no LWE equivalent; see plugins/web-engine-lwe/README.md.
class LWEWebEngineCookieManager : public Dali::WebEngineCookieManager
{
public:
    void SetCookieAcceptPolicy(CookieAcceptPolicy policy) override;
    CookieAcceptPolicy GetCookieAcceptPolicy() const override;
    void ClearCookies() override;
    void SetPersistentStorage(const std::string& path, CookiePersistentStorage storage) override;
    void ChangesWatch(WebEngineCookieManagerChangesWatchCallback callback) override;

private:
    CookieAcceptPolicy mAcceptPolicy = CookieAcceptPolicy::NO_THIRD_PARTY;
};

} // namespace LWEDaliBridge

#endif // DALI_LWE_WEB_ENGINE_COOKIE_MANAGER_H
