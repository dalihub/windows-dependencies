:: copy headers
:: 
:: args:
:: 1, location in dali folder (where all repositories are located)
:: 2, target path in dali-env (/opt/include/)
:: 3, API
::
mkdir %DALI_ENV%\opt\include\%2
mkdir %DALI_ENV%\opt\include\%2\%3

xcopy %~dp0\..\..\..\%1\%2\%3\*.h %DALI_ENV%\opt\include\%2\%3 /Y /S
