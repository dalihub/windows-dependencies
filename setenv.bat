cd ..

set appPackage=%cd%"\dali-env\opt\share\com.samsung.dali-demo\res"
setx DALI_APPLICATION_PACKAGE %appPackage:\=/%



setx DALI_ENV %cd%"\dali-env"
setx DALI_DATA_READ_ONLY_DIR %DALI_ENV%"\share"
setx DALI_IMAGE_DIR %DALI_ENV%"\share\dali\toolkit\images"
setx DALI_STYLE_DIR %DALI_ENV%"\share\dali\toolkit\style"
setx DALI_SOUND_DIR %DALI_ENV%"\share\dali\toolkit\sound"
setx DALI_STYLE_IMAGE_DIR %DALI_ENV%"\share\dali\toolkit\style\images"



setx DALI_WINDOW_WIDTH 480
setx DALI_WINDOW_HEIGHT 800

cd ..

@pause
