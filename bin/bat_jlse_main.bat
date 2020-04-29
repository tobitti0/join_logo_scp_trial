@echo off

rem ## join_logo_scp簡易実行 - CMカット動作
rem ## 出力：
rem ##  join_logo_scpの結果ファイル
rem ##
rem ## 環境変数（入力）：
rem ##  BINDIR    : 実行ファイルフォルダ
rem ##  LOGO_PATH       : ロゴファイル名
rem ##  LOGOSUB_PATH    : CM検出に使わないロゴファイル名
rem ##  JLOGO_CMD_PATH  : join_logo_scpの実行スクリプト
rem ##  JLOGO_OPT1      : join_logo_scpのオプション1
rem ##  JLOGO_OPT2      : join_logo_scpのオプション2
rem ##  JL_FLAGS        : join_logo_scpの-flagsオプション内容
rem ##  OPT_CHAPTER_EXE : chapter_exeのオプション
rem ##  file_avs_in     : 入力avsファイル名
rem ##  RESTART_AFTER_TRIM : 1の時カット位置は手動修正済みとして省略
rem ##


rem ##------------------------------------------------
rem ## 初期設定（別の所でまとめて設定）
rem ##------------------------------------------------
rem ##--- ファイル名設定 ---
rem set file_avs_in=in_org.avs
rem set file_avs_logo=obs_logo_erase.avs
rem set file_avs_cut=obs_cut.avs
rem set file_avs_in_cutcm=in_cutcm.avs
rem set file_avs_in_cutcl=in_cutcm_logo.avs
rem set file_txt_logoframe=obs_logoframe.txt
rem set file_txt_chapterexe=obs_chapterexe.txt
rem set file_txt_jlscp=obs_jlscp.txt

rem ## "文字列"の文字列が\で終わるとバッチ処理で後半の"が認識されないため対策
set DISP_LOGO_PATH=
if not "%LOGO_PATH%" == "" set "DISP_LOGO_PATH=%LOGO_PATH:\=\\%"

rem ##------------------------------------------------
rem ## 手動修正時用の省略処理
rem ##------------------------------------------------
if "%RESTART_AFTER_TRIM%" == "1" goto skip_exe_jls

rem ##------------------------------------------------
rem ## chapter_exe実行
rem ##------------------------------------------------
"%BINDIR%chapter_exe.exe" -v "lwinput.aui://%file_avs_in%" %OPT_CHAPTER_EXE% -o "%file_txt_chapterexe%"
if %ERRORLEVEL% neq 0 goto err_chapterexe

rem ##------------------------------------------------
rem ## logoframe実行
rem ##------------------------------------------------
rem ## ロゴデータ（CM確認用、無関係用）を確認し、何もなければ実行しない
set DISP_LOGO_OPT=
set JL_INLOGO=
if not "%DISP_LOGO_PATH%" == "" set DISP_LOGO_OPT=-logo "%DISP_LOGO_PATH%"
if not "%LOGOSUB_PATH%" == ""   set DISP_LOGO_OPT=%DISP_LOGO_OPT% -logo99 "%LOGOSUB_PATH%"
if "%DISP_LOGO_PATH%" == "" if "%LOGOSUB_PATH%" == "" goto skip_logoframe

"%BINDIR%logoframe.exe" "%file_avs_in%" %DISP_LOGO_OPT% -oa "%file_txt_logoframe%" -o "%file_avs_logo%"
if %ERRORLEVEL% neq 0 goto err_logoframe
if not exist "%file_txt_logoframe%" goto skip_logoframe
set JL_INLOGO=-inlogo "%file_txt_logoframe%"

:skip_logoframe

rem ##------------------------------------------------
rem ## join_logo_scp実行
rem ##------------------------------------------------
"%BINDIR%join_logo_scp.exe" %JL_INLOGO% -inscp "%file_txt_chapterexe%" -incmd "%JLOGO_CMD_PATH%" -o "%file_avs_cut%" -oscp "%file_txt_jlscp%" -flags "%JL_FLAGS%" %JLOGO_OPT1% %JLOGO_OPT2%

:skip_exe_jls

rem ##------------------------------------------------
rem ## 結果avsファイル作成
rem ##------------------------------------------------
copy "%file_avs_in%" "%file_avs_in_cutcm%"
>>"%file_avs_in_cutcm%" type "%file_avs_cut%"

copy "%file_avs_in%" "%file_avs_in_cutcl%"
if exist "%file_avs_logo%" >>"%file_avs_in_cutcl%" type "%file_avs_logo%"
>>"%file_avs_in_cutcl%" type "%file_avs_cut%"

rem ##------------------------------------------------
rem ## 完了
rem ##------------------------------------------------
exit /b 0


rem ##------------------------------------------------
rem ## エラー処理
rem ##------------------------------------------------
:err_chapterexe
echo chapter_exeでエラー発生のため、中断します。
goto err_end

:err_logoframe
echo logoframeでエラー発生のため、中断します。
goto err_end

:err_join
echo join_logo_scpでエラー発生のため、中断します。
goto err_end

rem ##------------------------------------------------
rem ## エラー終了
rem ##------------------------------------------------
:err_end
exit /b 1
