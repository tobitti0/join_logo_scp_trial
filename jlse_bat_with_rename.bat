@echo off

rem ## join_logo_scp動作確認用バッチファイル
rem ##
rem ## 都合の悪いファイル名は（TSファイル時のみ）強制的にリネームして実行する
rem ## （元のファイル名は"新ファイル名.title_bak.txt"内に記載して出力する）
rem ##
rem ## 入力：
rem ##  %1     : AVSファイル名またはTSファイル名
rem ## 出力：
rem ## tsfullname : リネーム処理後のファイル名

rem ##------------------------------------------------
rem ## 初期設定
rem ##------------------------------------------------
set BASEDIR=%~dp0
set BINDIR=%BASEDIR%bin\

if "%~1" == "" goto end_rename

:start_rename
rem ##------------------------------------------------
rem ## 都合の悪いファイル名はrename処理、元の名前をファイルに保存
rem ##------------------------------------------------
rem ##
rem ## TSファイル時のみ実行
rem ##
set "tsfullname=%~1"
if not "%~x1" == ".ts" goto skip_rename

rem ##
rem ## 特殊文字を処理して、Shift-JISにファイル名を変換
rem ##
for /F "usebackq delims=" %%I IN (`cscript //nologo "%BINDIR%func_echo.vbs" "%~n1"`) do set tsname_new=%%~I
set "tsname_new=%tsname_new:?=%"
set "tsfullname=%~dp1%tsname_new%%~x1"

rem ##
rem ## 名前変更なければ省略
rem ##
if "%tsname_new%" == "%~n1" goto skip_rename

rem ##
rem ## ファイル名変更
rem ##
move /Y "%~1" "%tsfullname%"

rem ##
rem ## 元ファイル名を保存
rem ##
cscript //nologo "%BINDIR%func_write_unicode.vbs" "%~dp1%tsname_new%.title_bak.txt" "%~n1"

:skip_rename

rem ##------------------------------------------------
rem ## バッチファイル本体実行
rem ##------------------------------------------------
rem ##--- 実行 ---
call "%BASEDIR%jlse_bat.bat" "%tsfullname%"

rem ##
rem ## 繰り返し処理
rem ##
shift
if not "%~1" == "" goto start_rename

:end_rename
exit /b
