#ifndef DALI_LWE_INPUT_EVENT_CONVERTER_H
#define DALI_LWE_INPUT_EVENT_CONVERTER_H

#include <LWEWebView.h>

namespace Dali
{
class TouchEvent;
class KeyEvent;
class HoverEvent;
class WheelEvent;
} // namespace Dali

namespace LWEDaliBridge
{
// Maps a Dali::KeyEvent onto LWE::KeyValue. Dali key names follow the X11/Ecore
// keysym naming convention across all its platform ports, which is what this
// mapping assumes for non-printable keys; printable keys share LWE::KeyValue's
// ASCII-aligned numbering (32-126) with Dali::KeyEvent::GetKeyString().
LWE::KeyValue ToLWEKeyValue(const Dali::KeyEvent& keyEvent);

// Dispatches a Dali::TouchEvent onto a WebContainer. Only the primary point
// (index 0) is forwarded, as mouse-style press/move/release - LWE's multi-point
// touch dispatch (DispatchTouchStart/Move/EndEvent) exists but is not wired here;
// see plugins/web-engine-lwe/README.md.
void DispatchTouchEvent(LWE::WebContainer* container, const Dali::TouchEvent& touch);

void DispatchKeyEvent(LWE::WebContainer* container, const Dali::KeyEvent& keyEvent);

// Approximated as mouse move, same caveat as DispatchTouchEvent.
void DispatchHoverEvent(LWE::WebContainer* container, const Dali::HoverEvent& hover);

void DispatchWheelEvent(LWE::WebContainer* container, const Dali::WheelEvent& wheel);

} // namespace LWEDaliBridge

#endif // DALI_LWE_INPUT_EVENT_CONVERTER_H
