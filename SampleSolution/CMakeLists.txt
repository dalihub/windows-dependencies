cmake_minimum_required(VERSION 3.11)

PROJECT (dali)

add_subdirectory(../../dali-core dali-core.out)
add_subdirectory(../../dali-adaptor dali-adaptor.out)
add_subdirectory(../../dali-toolkit dali-toolkit.out)

SET( SOURCES ${SOURCES}
../../dali-demo/main/main-example.cpp
)

ADD_DEFINITIONS(
#-D _CRT_SECURE_NO_WARNINGS
-DDALI_ENV="../../dali-env/"
-DAPP_DATA_RES_DIR=DALI_ENV"/opt/share/com.samsung.dali-demo/res"
-DIMAGES_DIR=APP_DATA_RES_DIR"/images/"
-DSTYLE_DIR=APP_DATA_RES_DIR"/style/"
-DDEMO_THEME_PATH=STYLE_DIR"demo-theme.json"
-DDEMO_IMAGE_DIR=IMAGES_DIR
-DdataReadOnlyDir=DDALI_ENV"/opt/share/dali/"
-Ddaliimagedir=dataReadOnlyDir"toolkit/images/"
-DDALI_IMAGE_DIR=daliimagedir
-DDEMO_STYLE_DIR=APP_DATA_RES_DIR"/style/"
-DAPPLICATION_RESOURCE_PATH=DDALI_ENV"/opt/share/com.samsung.dali-demo/res"
-DDEMO_VIDEO_DIR=DALI_ENV"/opt/share/com.samsung.dali-demo/res/videos/"
-DDEMO_MODEL_DIR=DALI_ENV"/opt/share/com.samsung.dali-demo/res/models/"
-DDEMO_SHADER_DIR=DALI_ENV"/opt/share/com.samsung.dali-demo/res/shaders/"
-DDEMO_SCRIPT_DIR=DALI_ENV"/opt/share/com.samsung.dali-demo/res/scripts/"
-DDEMO_GAME_DIR=DALI_ENV"/opt/share/com.samsung.dali-demo/res/game"
/vmg
/FI"../ExInclude/PreprocessorDefinitions.h"
/FI"../ExInclude/DaliDemoPreDefine.h"
-Dssize_t=size_t
/Gz
)
#head file path  
INCLUDE_DIRECTORIES(  
../../dali-demo
../../dali-env/opt/include
../../dali-demo/examples/text-label-emojis
../../dali-core
../../dali-adaptor
../../dali-toolkit
../ExInclude
)

link_directories(
../ExLib
../../bin
)

set(EXECUTABLE_OUTPUT_PATH ../../bin)

add_executable(dali-demo ${SOURCES})

target_link_libraries(dali-demo dali-core.lib)
target_link_libraries(dali-demo dali-adaptor.lib)
target_link_libraries(dali-demo dali-toolkit.lib)
target_link_libraries(dali-demo Win32File.lib)
target_link_libraries(dali-demo WindowsPlatform.lib)
target_link_libraries(dali-demo libjpeg.lib)
target_link_libraries(dali-demo libcurl_a.lib)
target_link_libraries(dali-demo turbojpeg.lib)
target_link_libraries(dali-demo getopt.lib)
target_link_libraries(dali-demo giflib.lib)
target_link_libraries(dali-demo libEGL.lib)
target_link_libraries(dali-demo libexif.lib)
target_link_libraries(dali-demo libGLESv2.lib)
target_link_libraries(dali-demo pthread.lib)
target_link_libraries(dali-demo libpng.lib)
target_link_libraries(dali-demo zlibstat.lib)
target_link_libraries(dali-demo legacy_stdio_definitions.lib)
target_link_libraries(dali-demo freetype.lib)
target_link_libraries(dali-demo FontConfig.lib)
target_link_libraries(dali-demo libexpat.lib)
target_link_libraries(dali-demo fribidi.lib)
target_link_libraries(dali-demo harfbuzz-1.4.7.lib)
target_link_libraries(dali-demo dlfcn.lib)
target_link_libraries(dali-demo Iphlpapi.lib)
target_link_libraries(dali-demo Psapi.lib)
target_link_libraries(dali-demo Userenv.lib)

add_dependencies(dali-demo dali-core)
add_dependencies(dali-demo dali-adaptor)
add_dependencies(dali-demo dali-toolkit)

