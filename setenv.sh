#!/bin/bash

cd ..

setx DALI_APPLICATION_PACKAGE `pwd`/dali-env/opt/share/com.samsung.dali-demo/res/
setx DALI_ENV `pwd`/dali-env/

setx DALI_DATA_READ_ONLY_DIR `pwd`/dali-env/opt/share/
setx DALI_IMAGE_DIR `pwd`/dali-env/opt/share/dali/toolkit/images/
setx DALI_STYLE_DIR `pwd`/dali-env/opt/share/dali/toolkit/styles/
setx DALI_SOUND_DIR `pwd`/dali-env/opt/share/dali/toolkit/sound/
setx DALI_STYLE_IMAGE_DIR `pwd`/dali-env/opt/share/dali/toolkit/styles/images/

setx DALI_WINDOW_WIDTH 480
setx DALI_WINDOW_HEIGHT 800

cd ..
