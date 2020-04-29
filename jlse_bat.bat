@echo off
setlocal

rem ## join_logo_scp動作確認用バッチファイル
rem ## 入力：
rem ##  %1     : AVSファイル名またはTSファイル名
rem ##
rem ## 環境変数（入力）：
rem ##  RESTART_AFTER_TRIM  : 1の時CM位置手修正後の再開
rem ##  RESTART_AFTER_PARAM : 1の時ファイル名から取得のパラメータ手修正後の再開

rem ##------------------------------------------------
rem ## 初期設定
rem ##------------------------------------------------
set BASEDIR=%~dp0
set FILESETUP=%BASEDIR%setting\bat_setup.bat

rem ##--- 設定読み込み ---
call "%FILESETUP%" "%~1"

rem ##------------------------------------------------
rem ## 作業場所に移動
rem ##------------------------------------------------
rem ##--- avs入力の場合はavs場所に出力 ---
if not "%~x1" == ".avs" goto skip_avs_dir
set OUTDIR=%~dp1
set OUTNAME=
:skip_avs_dir

rem ##--- 拡張子確認 ---
if not "%~x1" == ".ts" if not "%~x1" == ".avs" goto err_in_name

rem ##--- ファイル存在確認 ---
if not exist "%~1" goto err_in_none

rem ##--- 出力フォルダ確認・移動 ---
if not exist "%OUTDIR%" goto err_in_outdir
pushd "%OUTDIR%"
if "%OUTNAME%" == "" goto skip_newdir
if not exist "%OUTNAME%" mkdir "%OUTNAME%"
if not exist "%OUTNAME%" goto err_in_outdir
cd "%OUTNAME%"
:skip_newdir

rem ##--- 実行パスを通す ---
set path=%path%;%BINDIR%

rem ##------------------------------------------------
rem ## 手動修正時用の省略処理
rem ## 環境変数 RESTART_AFTER_TRIM=1 を事前設定時はCM位置検出まで省略
rem ## CM位置(obs_cut.avs)を手動修正して再開する用途を想定
rem ##------------------------------------------------
if "%RESTART_AFTER_TRIM%" == "1" (
  echo RESTART_AFTER_TRIM=1が設定されているため、CM位置検出は省略します
  goto skip_intools
)

rem ##------------------------------------------------
rem ## ファイル名による動作変更
rem ##------------------------------------------------
rem ##--- ファイル名によってパラメータ変更する場合 ---
call "%BINDIR%bat_jlse_pre.bat" "%~dpnx1"

rem ##--- 共通設定 ---
set JLOGO_CMD_PATH=%JL_DIR%%JLOGO_CMD%

rem ##--- ロゴ検出しない時はロゴ設定省略 ---
if "%LOGO_PATH%" == "" goto skip_logoname
if "%LOGO_ABBR%" == "" goto skip_logoname
rem ##################################################
rem ##  放送局名や略称でロゴ限定する場合に設定する
rem ##    %LOGO_NAME% : 放送局名（認識用）
rem ##    %LOGO_INST% : 放送局名（設定用）
rem ##    %LOGO_ABBR% : 放送局略称
rem ##################################################
rem ===== 以下、設定するロゴのremを外す =====
rem set LOGO_PATH=%LG_DIR%%LOGO_NAME%.lgd
set LOGO_PATH=%LG_DIR%%LOGO_INST%.lgd
rem set LOGO_PATH=%LG_DIR%%LOGO_ABBR%.lgd
:skip_logoname

rem ##------------------------------------------------
rem ## CMカット実行前の動作
rem ##------------------------------------------------
rem ##--- 実行 ---
call "%BINDIR%bat_intools.bat" "%~dpnx1"
:skip_intools

rem ##------------------------------------------------
rem ## CMカット動作
rem ##------------------------------------------------
rem ##--- 実行 ---
call "%BINDIR%bat_jlse_main.bat"
if %ERRORLEVEL% neq 0 goto err_end

rem ##------------------------------------------------
rem ## chapter作成
rem ##------------------------------------------------
cscript //nologo "%BINDIR%func_chapter_jls.vbs" org     "%file_avs_cut%" "%file_txt_jlscp%" > "%file_txt_cpt_org%"
cscript //nologo "%BINDIR%func_chapter_jls.vbs" cut     "%file_avs_cut%" "%file_txt_jlscp%" > "%file_txt_cpt_cut%"
cscript //nologo "%BINDIR%func_chapter_jls.vbs" tvtplay "%file_avs_cut%" "%file_txt_jlscp%" > "%file_txt_cpt_tvt%"
if not "%file_chapter_tvtplay%" == "" copy "%file_txt_cpt_tvt%" "%file_chapter_tvtplay%"
if not "%file_chapter_org%" == "" copy "%file_txt_cpt_org%" "%file_chapter_org%"
if not "%file_chapter_cut%" == "" copy "%file_txt_cpt_cut%" "%file_chapter_cut%"


rem ##--- 完了 ---
echo 結果出力先："%OUTDIR%%OUTNAME%"

popd
endlocal
exit /b 0


rem ##------------------------------------------------
rem ## エラー処理
rem ##------------------------------------------------
:err_in_name
echo 入力したファイルの拡張子がtsまたはavsではありません
goto err_end

:err_in_none
echo 入力ファイルが見つかりません（"%~1"）
goto err_end

:err_in_outdir
echo 出力フォルダが生成できません（"%OUTDIR%%OUTNAME%"）
goto err_end

rem ##------------------------------------------------
rem ## エラー終了
rem ##------------------------------------------------
:err_end
timeout /t 30
if %ERRORLEVEL% neq 0 pause
endlocal
exit /b 1
