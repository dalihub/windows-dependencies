cd ..

set appPackage=%cd%"\dali-env\opt\share\com.samsung.dali-demo\res"
setx DALI_APPLICATION_PACKAGE %appPackage:\=/%

setx DALI_WINDOW_WIDTH 480
setx DALI_WINDOW_HEIGHT 800

cd ..

@pause
