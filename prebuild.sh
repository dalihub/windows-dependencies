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







#xcopy /s/y/i/f/d "../dali-toolkit/dali-toolkit/styles/*.json" "../dali-env/opt/share/dali/toolkit/styles"
#xcopy /s/y/i/f/d "../dali-toolkit/dali-toolkit/styles/480x800/*.json" "../dali-env/opt/share/dali/toolkit/styles"
#xcopy /s/y/i/f/d "../dali-toolkit/dali-toolkit/styles/480x800/images/*.png" "../dali-env/opt/share/dali/toolkit/styles/images"
#xcopy /s/y/i/f/d "../dali-toolkit/dali-toolkit/styles/images-common/*.png" "../dali-env/opt/share/dali/toolkit/images"
#xcopy /s/y/i/f/d "../dali-toolkit/dali-toolkit/sounds/*.ogg" "../dali-env/opt/share/dali/toolkit/sounds"

#xcopy /s/y/i/f/d "../dali-demo/resources/game/*.*" "../dali-env/opt/share/com.samsung.dali-demo/res/game"
#xcopy /s/y/i/f/d "../dali-demo/resources/images/*.*" "../dali-env/opt/share/com.samsung.dali-demo/res/images"
#xcopy /s/y/i/f/d "../dali-demo/resources/models/*.*" "../dali-env/opt/share/com.samsung.dali-demo/res/models"
#xcopy /s/y/i/f/d "../dali-demo/resources/scripts/*.json" "../dali-env/opt/share/com.samsung.dali-demo/res/scripts"
#xcopy /s/y/i/f/d "../dali-demo/resources/shaders/*.*" "../dali-env/opt/share/com.samsung.dali-demo/res/shaders"
#xcopy /s/y/i/f/d "../dali-demo/resources/style/*.json" "../dali-env/opt/share/com.samsung.dali-demo/res/style"
#xcopy /s/y/i/f/d "../dali-demo/resources/style/images/*.png" "../dali-env/opt/share/com.samsung.dali-demo/res/style/images"
#xcopy /s/y/i/f/d "../dali-demo/resources/videos/*.*" "../dali-env/opt/share/com.samsung.dali-demo/res/videos"

#@pause


#/s Copies directories and subdirectories, unless they are empty. If you omit /s, xcopy works within a single directory.
#/y Suppresses prompting to confirm that you want to overwrite an existing destination file.
#/i If Source is a directory or contains wildcards and Destination does not exist, xcopy assumes Destination specifies a directory name and creates a new directory. Then, xcopy copies all specified files into the new directory. By default, xcopy prompts you to specify whether Destination is a file or a directory.
#/f Displays source and destination file names while copying.
#/d Copies source files changed on or after the specified date only. If you do not include a MM-DD-YYYY value, xcopy copies all Source files that are newer than existing Destination files. This command-line option allows you to update files that have changed.
