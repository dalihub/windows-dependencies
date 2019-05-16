cd ..
set appPackage=%cd%"\dali-env\opt\share\com.samsung.dali-demo\res"
set csharpDemoDir=%cd%\"dali-windows-backend\csharp-demo"

setx DaliEnv %cd%"\dali-env
setx DaliToolKitRes %cd%"\dali-env\opt\share\dali\toolkit"
setx dali_csharp-demo %csharpDemoDir:\=/%
setx DALI_APPLICATION_PACKAGE %appPackage:\=/%
setx DALI_WINDOW_WIDTH 1920
setx DALI_WINDOW_HEIGHT 1080

cd ..
setx DemoRes %cd%\demo\csharp-demo\res
@pause