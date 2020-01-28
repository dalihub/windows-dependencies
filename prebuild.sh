#!/bin/bash

mkdir -p ../dali-env/opt/share/dali/toolkit/styles/images
mkdir -p ../dali-env/opt/share/dali/toolkit/images
mkdir -p ../dali-env/opt/share/dali/toolkit/sounds

mkdir -p ../dali-env/opt/share/com.samsung.dali-demo/res/game
mkdir -p ../dali-env/opt/share/com.samsung.dali-demo/res/images
mkdir -p ../dali-env/opt/share/com.samsung.dali-demo/res/models
mkdir -p ../dali-env/opt/share/com.samsung.dali-demo/res/scripts
mkdir -p ../dali-env/opt/share/com.samsung.dali-demo/res/shaders
mkdir -p ../dali-env/opt/share/com.samsung.dali-demo/res/style
mkdir -p ../dali-env/opt/share/com.samsung.dali-demo/res/style/images
mkdir -p ../dali-env/opt/share/com.samsung.dali-demo/res/videos

cp -r -u -v ../dali-toolkit/dali-toolkit/styles/*.json ../dali-env/opt/share/dali/toolkit/styles
cp -r -u -v ../dali-toolkit/dali-toolkit/styles/480x800/*.json ../dali-env/opt/share/dali/toolkit/styles
cp -r -u -v ../dali-toolkit/dali-toolkit/styles/480x800/images/*.png ../dali-env/opt/share/dali/toolkit/styles/images
cp -r -u -v ../dali-toolkit/dali-toolkit/styles/images-common/*.png ../dali-env/opt/share/dali/toolkit/images
cp -r -u -v ../dali-toolkit/dali-toolkit/sounds/*.ogg ../dali-env/opt/share/dali/toolkit/sounds

cp -r -u -v ../dali-demo/resources/game/*.* ../dali-env/opt/share/com.samsung.dali-demo/res/game
cp -r -u -v ../dali-demo/resources/images/*.* ../dali-env/opt/share/com.samsung.dali-demo/res/images
cp -r -u -v ../dali-demo/resources/models/*.* ../dali-env/opt/share/com.samsung.dali-demo/res/models
cp -r -u -v ../dali-demo/resources/scripts/*.json ../dali-env/opt/share/com.samsung.dali-demo/res/scripts
cp -r -u -v ../dali-demo/resources/shaders/*.* ../dali-env/opt/share/com.samsung.dali-demo/res/shaders
cp -r -u -v ../dali-demo/resources/style/*.json ../dali-env/opt/share/com.samsung.dali-demo/res/style
cp -r -u -v ../dali-demo/resources/style/images/*.png ../dali-env/opt/share/com.samsung.dali-demo/res/style/images
cp -r -u -v ../dali-demo/resources/videos/*.* ../dali-env/opt/share/com.samsung.dali-demo/res/videos
