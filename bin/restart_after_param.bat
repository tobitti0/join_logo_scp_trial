@echo off
setlocal

rem ##
rem ## join_logo_scp動作確認用バッチファイルの手動修正後再開用
rem ## ファイル名から取得したパラメータを手修正した後の再開
rem ##

rem ## １階層上のフォルダ取得
set TMPPATH=%~dp0
for /F "usebackq delims=" %%I IN (`echo "%TMPPATH:~0,-1%"`) do set TMPPATH=%%~dpI

set RESTART_AFTER_PARAM=1
call "%TMPPATH%jlse_bat.bat" "%~1"

endlocal
exit /b
