#include "DaliInputEventConverter.h"

#include <cstdio>
#include <dali/public-api/events/hover-event.h>
#include <dali/public-api/events/key-event.h>
#include <dali/public-api/events/mouse-button.h>
#include <dali/public-api/events/point-state.h>
#include <dali/public-api/events/touch-event.h>
#include <dali/public-api/events/wheel-event.h>
#include <dali/public-api/math/vector2.h>

namespace LWEDaliBridge
{
namespace
{
LWE::KeyValue MapNamedKey(const std::string& keyName)
{
    if (keyName == "Left") return LWE::ArrowLeftKey;
    if (keyName == "Right") return LWE::ArrowRightKey;
    if (keyName == "Up") return LWE::ArrowUpKey;
    if (keyName == "Down") return LWE::ArrowDownKey;
    if (keyName == "Return" || keyName == "KP_Enter") return LWE::EnterKey;
    if (keyName == "BackSpace") return LWE::BackspaceKey;
    if (keyName == "Tab") return LWE::TabKey;
    if (keyName == "Escape") return LWE::EscapeKey;
    if (keyName == "Delete") return LWE::DeleteKey;
    if (keyName == "Insert") return LWE::InsertKey;
    if (keyName == "Home") return LWE::HomeKey;
    if (keyName == "End") return LWE::EndKey;
    if (keyName == "Prior") return LWE::PageUpKey;
    if (keyName == "Next") return LWE::PageDownKey;
    return LWE::UnidentifiedKey;
}
} // namespace

LWE::KeyValue ToLWEKeyValue(const Dali::KeyEvent& keyEvent)
{
    // Resolve named/special keys (arrows, Return, Backspace, ...) FIRST. DALi reports the arrow
    // keys with a one-byte GetKeyString() whose value is the Win32 VK code (Left=0x25='%',
    // Up=0x26='&', Down=0x28='('), which falls in the printable ASCII range - so keying off the
    // string would mis-map arrows to the characters '%'/'&'/'(' and never reach the arrow
    // handling. The key name ("Left"/"Up"/...) is unambiguous, so try it before the string.
    LWE::KeyValue named = MapNamedKey(keyEvent.GetKeyName().CStr());
    if (named != LWE::UnidentifiedKey)
    {
        return named;
    }

    const Dali::String& keyString = keyEvent.GetKeyString();
    if (keyString.Size() == 1)
    {
        unsigned char ch = static_cast<unsigned char>(keyString.CStr()[0]);
        if (ch >= 32 && ch <= 126)
        {
            return static_cast<LWE::KeyValue>(ch);
        }
    }
    return named;
}

void DispatchTouchEvent(LWE::WebContainer* container, const Dali::TouchEvent& touch)
{
    if (touch.GetPointCount() == 0)
    {
        return;
    }

    // LWE expects coordinates relative to the web content's top-left, i.e. relative to the
    // WebView actor that received the touch. GetScreenPosition() is window-absolute and would
    // land the click at the wrong place in the page (so DOM inputs never get focus / text).
    const Dali::Vector2& position = touch.GetLocalPosition(0);
    { FILE* f = fopen("d:\\lwe_webview.log", "a"); if(f){ const Dali::Vector2& sp = touch.GetScreenPosition(0); fprintf(f, "[MOUSE] state=%d local=(%.0f,%.0f) screen=(%.0f,%.0f)\n", (int)touch.GetState(0), position.x, position.y, sp.x, sp.y); fclose(f);} }
    switch (touch.GetState(0))
    {
        case Dali::PointState::STARTED:
            container->DispatchMouseDownEvent(LWE::LeftButton, LWE::LeftButtonDown, position.x, position.y);
            break;
        case Dali::PointState::MOTION:
            container->DispatchMouseMoveEvent(LWE::LeftButton, LWE::LeftButtonDown, position.x, position.y);
            break;
        case Dali::PointState::FINISHED:
        case Dali::PointState::LEAVE:
        case Dali::PointState::INTERRUPTED:
        default:
            container->DispatchMouseUpEvent(LWE::NoButton, LWE::NoButtonDown, position.x, position.y);
            break;
    }
}

void DispatchKeyEvent(LWE::WebContainer* container, const Dali::KeyEvent& keyEvent)
{
    LWE::KeyValue value = ToLWEKeyValue(keyEvent);
    { FILE* f = fopen("d:\\lwe_webview.log", "a"); if(f){ fprintf(f, "[KEY] DispatchKeyEvent name='%s' str='%s' code=%d state=%d -> lweVal=%d\n", keyEvent.GetKeyName().CStr(), keyEvent.GetKeyString().CStr(), keyEvent.GetKeyCode(), (int)keyEvent.GetState(), (int)value); fclose(f);} }
    if (keyEvent.GetState() == Dali::KeyEvent::DOWN)
    {
        container->DispatchKeyDownEvent(value);
        container->DispatchKeyPressEvent(value);
    }
    else
    {
        container->DispatchKeyUpEvent(value);
    }
}

void DispatchHoverEvent(LWE::WebContainer* container, const Dali::HoverEvent& hover)
{
    if (hover.GetPointCount() == 0)
    {
        return;
    }
    const Dali::Vector2& position = hover.GetScreenPosition(0);
    container->DispatchMouseMoveEvent(LWE::NoButton, LWE::NoButtonDown, position.x, position.y);
}

void DispatchWheelEvent(LWE::WebContainer* container, const Dali::WheelEvent& wheel)
{
    const Dali::Vector2& point = wheel.GetPoint();
    container->DispatchMouseWheelEvent(point.x, point.y, wheel.GetDelta());
}

} // namespace LWEDaliBridge
