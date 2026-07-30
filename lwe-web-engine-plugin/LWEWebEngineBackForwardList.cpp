#include "LWEWebEngineBackForwardList.h"

namespace LWEDaliBridge
{

std::unique_ptr<Dali::WebEngineBackForwardListItem> LWEWebEngineBackForwardList::GetCurrentItem() const { return nullptr; }
std::unique_ptr<Dali::WebEngineBackForwardListItem> LWEWebEngineBackForwardList::GetPreviousItem() const { return nullptr; }
std::unique_ptr<Dali::WebEngineBackForwardListItem> LWEWebEngineBackForwardList::GetNextItem() const { return nullptr; }
std::unique_ptr<Dali::WebEngineBackForwardListItem> LWEWebEngineBackForwardList::GetItemAtIndex(uint32_t) const { return nullptr; }
uint32_t LWEWebEngineBackForwardList::GetItemCount() const { return 0; }

std::vector<std::unique_ptr<Dali::WebEngineBackForwardListItem>> LWEWebEngineBackForwardList::GetBackwardItems(int)
{
    return {};
}

std::vector<std::unique_ptr<Dali::WebEngineBackForwardListItem>> LWEWebEngineBackForwardList::GetForwardItems(int)
{
    return {};
}

} // namespace LWEDaliBridge
