@echo off

rem ## join_logo_scp動作確認用バッチファイル - 前処理実行
rem ## ファイル名から実行に必要な情報を取得し、環境変数に設定する
rem ## 入力：
rem ##  %1     : avsファイル名またはtsファイル名
rem ##
rem ## 環境変数（入力）：
rem ##  BINDIR    : 実行ファイルフォルダ
rem ##  SETDIR    : 設定入力フォルダ
rem ##  LG_DIR    : ロゴデータフォルダ
rem ##  RESTART_AFTER_PARAM : 1の時ファイル名から取得のパラメータ手修正後の再開
rem ##
rem ## 環境変数（出力）：
rem ##  LOGO_NAME    : 放送局名（認識用）
rem ##  LOGO_INST    : 放送局名（設定用）
rem ##  LOGO_ABBR    : 放送局略称
rem ##  LOGO_PATH    : ロゴデータ検索パス名（入出力）
rem ##  LOGOSUB_PATH : CMとは無関係のロゴデータ検索パス名
rem ##  その他settingファイルによる設定
rem ##

rem ##------------------------------------------------
rem ## 初期設定（別の所でまとめて設定）
rem ##------------------------------------------------
rem ##--- 入力データ ---
rem set file_csv_chlist=ChList.csv
rem set file_csv_param1=JLparam_set1.csv
rem set file_csv_param2=JLparam_set2.csv

rem ##--- パラメータ設定用（新規作成ファイル） ---
rem set file_bat_param=obs_param.bat

rem ##------------------------------------------------
rem ## 手動修正時用の省略処理
rem ## 環境変数 RESTART_AFTER_PARAM=1 を事前設定時はカット位置検出まで省略
rem ## パラメータ設定を手動修正して再開する用途を想定
rem ##------------------------------------------------
if "%RESTART_AFTER_PARAM%" == "1" (
  echo RESTART_AFTER_PARAM=1が設定されているため、パラメータ検出は省略します
  goto label_setparam
)

rem ##------------------------------------------------
rem ## 放送局名・略称の取得
rem ##------------------------------------------------
rem ##--- ファイル名から放送局情報を取得 ---
set LOGO_NAME=
set LOGO_INST=
set LOGO_ABBR=
for /F "usebackq delims=" %%I IN (`cscript //nologo "%BINDIR%func_get_chname.vbs" 1 "%SETDIR%%file_csv_chlist%" "%~n1"`) do set LOGO_NAME=%%~I
for /F "usebackq delims=" %%I IN (`cscript //nologo "%BINDIR%func_get_chname.vbs" 2 "%SETDIR%%file_csv_chlist%" "%~n1"`) do set LOGO_INST=%%~I
for /F "usebackq delims=" %%I IN (`cscript //nologo "%BINDIR%func_get_chname.vbs" 3 "%SETDIR%%file_csv_chlist%" "%~n1"`) do set LOGO_ABBR=%%~I

rem ##--- 見つからない時は直前フォルダ名で検索 ---
set TITLE2ND=
if not "%LOGO_ABBR%" == "" goto skip_chname
set TITLE2ND=%~dp1
if "%TITLE2ND%" == "" goto skip_chname
for /F "usebackq delims=" %%I IN (`echo "%TITLE2ND:~0,-1%"`) do set TITLE2ND=%%~nI
if "%TITLE2ND%" == "" goto skip_chname
for /F "usebackq delims=" %%I IN (`cscript //nologo "%BINDIR%func_get_chname.vbs" 1 "%SETDIR%%file_csv_chlist%" "%TITLE2ND%"`) do set LOGO_NAME=%%~I
for /F "usebackq delims=" %%I IN (`cscript //nologo "%BINDIR%func_get_chname.vbs" 2 "%SETDIR%%file_csv_chlist%" "%TITLE2ND%"`) do set LOGO_INST=%%~I
for /F "usebackq delims=" %%I IN (`cscript //nologo "%BINDIR%func_get_chname.vbs" 3 "%SETDIR%%file_csv_chlist%" "%TITLE2ND%"`) do set LOGO_ABBR=%%~I
set TITLE2ND= %TITLE2ND%
:skip_chname

rem ##--- ロゴ取得情報をパラメータファイルに書き出し ---
>  "%file_bat_param%" echo rem ## 放送局認識
>> "%file_bat_param%" echo set LOGO_NAME=%LOGO_NAME%
>> "%file_bat_param%" echo set LOGO_INST=%LOGO_INST%
>> "%file_bat_param%" echo set LOGO_ABBR=%LOGO_ABBR%
>> "%file_bat_param%" echo.

rem ##------------------------------------------------
rem ## CMカット実行用パラメータの取得・設定
rem ##------------------------------------------------
rem ##--- パラメータ情報を取得 ---
cscript //nologo "%BINDIR%func_jls_params.vbs" "%SETDIR%%file_csv_param1%" "%LOGO_ABBR%" "%~n1%TITLE2ND%" >> "%file_bat_param%"
cscript //nologo "%BINDIR%func_jls_params.vbs" "%SETDIR%%file_csv_param2%" "%LOGO_ABBR%" "%~n1%TITLE2ND%" >> "%file_bat_param%"

:label_setparam
rem ##--- 取得したパラメータ情報を設定 ---
call "%file_bat_param%"

rem ##------------------------------------------------
rem ## パラメータ情報から変数設定
rem ##------------------------------------------------
rem ##--- CM用ロゴがない場合 ---
if "%JLOGO_NOLOGO%" == "1" set LOGO_PATH=

rem ##--- CM検出とは関係ないロゴがある場合 ---
if not "%LOGOSUBHEAD%" == "" set LOGOSUB_PATH=%LG_DIR%%LOGOSUBHEAD%.lgd

rem ##--- 検出放送局名の表示 ---
if not "%LOGO_ABBR%" == "" echo "放送局：%LOGO_NAME%（%LOGO_ABBR%）"
if "%LOGO_ABBR%" == "" echo 放送局はファイル名から検出できませんでした


rem ##------------------------------------------------
rem ## 完了
rem ##------------------------------------------------
exit /b
