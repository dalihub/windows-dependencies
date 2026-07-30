#ifndef DALI_LWE_WEB_ENGINE_BACK_FORWARD_LIST_H
#define DALI_LWE_WEB_ENGINE_BACK_FORWARD_LIST_H

#include <dali/devel-api/adaptor-framework/web-engine/web-engine-back-forward-list.h>

namespace LWEDaliBridge
{
// LWE exposes only CanGoBack/CanGoForward/GoBack/GoForward on WebContainer (handled
// directly by LWEWebEnginePlugin) with no way to enumerate history items, so this
// is a stub returning empty results throughout; see plugins/web-engine-lwe/README.md.
class LWEWebEngineBackForwardList : public Dali::WebEngineBackForwardList
{
public:
    std::unique_ptr<Dali::WebEngineBackForwardListItem> GetCurrentItem() const override;
    std::unique_ptr<Dali::WebEngineBackForwardListItem> GetPreviousItem() const override;
    std::unique_ptr<Dali::WebEngineBackForwardListItem> GetNextItem() const override;
    std::unique_ptr<Dali::WebEngineBackForwardListItem> GetItemAtIndex(uint32_t index) const override;
    uint32_t GetItemCount() const override;
    std::vector<std::unique_ptr<Dali::WebEngineBackForwardListItem>> GetBackwardItems(int limit) override;
    std::vector<std::unique_ptr<Dali::WebEngineBackForwardListItem>> GetForwardItems(int limit) override;
};

} // namespace LWEDaliBridge

#endif // DALI_LWE_WEB_ENGINE_BACK_FORWARD_LIST_H
