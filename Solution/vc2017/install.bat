set LIBDLI_DEPLOY_DIR=%DALI_ENV%\opt\lib\
if not exist %LIBDLI_DEPLOY_DIR% (
	mkdir %LIBDLI_DEPLOY_DIR%
)

:: copy library (provide path as first argument)
xcopy %1 %LIBDLI_DEPLOY_DIR% /Y /S
