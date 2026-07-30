/*
 * Copyright (c) 2026 Samsung Electronics Co., Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

#include "LWEWebEngineContext.h"
#include "LWEWebEngineCookieManager.h"
#include "LWEWebEnginePlugin.h"

// The factory entry points dali-adaptor's web-engine-impl.cpp resolves with
// dlsym() after dlopen'ing this plugin. On Windows the dlfcn shim
// (third-party/windows-platform/dlfcn.cpp) maps the requested
// "libdali2-web-engine-lwe-plugin.so" to "dali2-web-engine-lwe-plugin-win.dll"
// and loads it from the directory of dali2-adaptor.dll.

#ifdef _WIN32
#define LWE_PLUGIN_EXPORT extern "C" __declspec(dllexport)
#else
#define LWE_PLUGIN_EXPORT extern "C"
#endif

LWE_PLUGIN_EXPORT Dali::WebEnginePlugin* CreateWebEnginePlugin()
{
  return new LWEDaliBridge::LWEWebEnginePlugin();
}

LWE_PLUGIN_EXPORT void DestroyWebEnginePlugin(Dali::WebEnginePlugin* plugin)
{
  delete plugin;
}

LWE_PLUGIN_EXPORT Dali::WebEngineContext* GetWebEngineContext(bool /*isIncognito*/)
{
  // Incognito is ignored: LWE has no context-level API, so the bridge exposes a
  // single global context - see README.md (WebEngineContext section).
  static LWEDaliBridge::LWEWebEngineContext context;
  return &context;
}

LWE_PLUGIN_EXPORT Dali::WebEngineCookieManager* GetWebEngineCookieManager(bool /*isIncognito*/)
{
  static LWEDaliBridge::LWEWebEngineCookieManager cookieManager;
  return &cookieManager;
}
