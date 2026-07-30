CMAKE_MINIMUM_REQUIRED(VERSION 3.16)

# LWE (Lightweight Web Engine / Starfish) WebEnginePlugin for DALi on Windows.
#
# dali-adaptor's web-engine-impl.cpp dlopen's "libdali2-web-engine-lwe-plugin.so"
# at runtime; the Windows dlfcn shim maps that to dali2-web-engine-lwe-plugin.dll
# and loads it from the directory containing dali2-adaptor.dll. This project
# builds that DLL out-of-tree so dali-adaptor itself carries no plugin sources.
#
# Build AFTER dali-core and dali-adaptor are installed into dali-env: the plugin
# links their installed packages (public/devel API only). The LWE SDK
# (LWEWebView.h / Starfish.lib) comes from WindowsDependenciesSDK via
# CMAKE_PREFIX_PATH.

PROJECT(dali2-web-engine-lwe-plugin-win CXX)

SET(CMAKE_CXX_STANDARD 17)
SET(CMAKE_CXX_STANDARD_REQUIRED ON)

FIND_PACKAGE(dali2-core CONFIG REQUIRED)
FIND_PACKAGE(dali2-adaptor CONFIG REQUIRED)

FIND_PATH(LWE_INCLUDE_DIR NAMES LWEWebView.h REQUIRED)
FIND_LIBRARY(STARFISH_LIBRARY NAMES Starfish REQUIRED)
MESSAGE(STATUS "LWE include: ${LWE_INCLUDE_DIR}")
MESSAGE(STATUS "Starfish   : ${STARFISH_LIBRARY}")

ADD_LIBRARY(${PROJECT_NAME} SHARED
  DaliInputEventConverter.cpp
  LWEWebEngineBackForwardList.cpp
  LWEWebEngineContext.cpp
  LWEWebEngineCookieManager.cpp
  LWEWebEngineLoadError.cpp
  LWEWebEnginePlugin.cpp
  LWEWebEngineSettings.cpp
  web-engine-lwe-plugin.cpp
)

# The DLL must carry the exact name the dlfcn shim derives from
# libdali2-web-engine-lwe-plugin.so.
SET_TARGET_PROPERTIES(${PROJECT_NAME} PROPERTIES
  OUTPUT_NAME "dali2-web-engine-lwe-plugin"
  PREFIX ""
)

TARGET_INCLUDE_DIRECTORIES(${PROJECT_NAME} PRIVATE ${LWE_INCLUDE_DIR})

# Match the DALi Windows ABI: /vmg (member-function-pointer representation used
# by DALi callbacks) and the __restrict__ mapping, same as the dali-ui samples.
TARGET_COMPILE_OPTIONS(${PROJECT_NAME} PRIVATE /vmg /utf-8 /wd4251)
TARGET_COMPILE_DEFINITIONS(${PROJECT_NAME} PRIVATE __restrict__=__restrict)

TARGET_LINK_LIBRARIES(${PROJECT_NAME} PRIVATE
  dali2-adaptor::dali2-adaptor
  dali2-core::dali2-core
  ${STARFISH_LIBRARY}
  dbghelp # TEMP DEBUG: crash/abort stack dumps in LWEWebEnginePlugin.cpp
)

# Install next to dali2-adaptor.dll so the dlfcn shim finds it.
INSTALL(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION bin)
