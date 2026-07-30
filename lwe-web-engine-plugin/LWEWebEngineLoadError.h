#ifndef DALI_LWE_WEB_ENGINE_LOAD_ERROR_H
#define DALI_LWE_WEB_ENGINE_LOAD_ERROR_H

#include <LWEWebView.h>
#include <dali/devel-api/adaptor-framework/web-engine/web-engine-load-error.h>

namespace LWEDaliBridge
{
// LWE::ResourceError only carries a numeric code, description and URL - it has no
// notion of ErrorType, so GetType() always reports NETWORK; see plugins/web-engine-lwe/README.md.
class LWEWebEngineLoadError : public Dali::WebEngineLoadError
{
public:
    explicit LWEWebEngineLoadError(const LWE::ResourceError& error);

    std::string GetUrl() const override;
    ErrorCode GetCode() const override;
    std::string GetDescription() const override;
    ErrorType GetType() const override;

private:
    std::string mUrl;
    std::string mDescription;
    int         mCode;
};

} // namespace LWEDaliBridge

#endif // DALI_LWE_WEB_ENGINE_LOAD_ERROR_H
