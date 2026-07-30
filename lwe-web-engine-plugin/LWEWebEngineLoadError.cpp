#include "LWEWebEngineLoadError.h"

namespace LWEDaliBridge
{

LWEWebEngineLoadError::LWEWebEngineLoadError(const LWE::ResourceError& error)
: mUrl(error.GetUrl())
, mDescription(error.GetDescription())
, mCode(error.GetErrorCode())
{
}

std::string LWEWebEngineLoadError::GetUrl() const { return mUrl; }

Dali::WebEngineLoadError::ErrorCode LWEWebEngineLoadError::GetCode() const
{
    return static_cast<ErrorCode>(mCode);
}

std::string LWEWebEngineLoadError::GetDescription() const { return mDescription; }

Dali::WebEngineLoadError::ErrorType LWEWebEngineLoadError::GetType() const
{
    return ErrorType::NETWORK;
}

} // namespace LWEDaliBridge
