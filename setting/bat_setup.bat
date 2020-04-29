rem ## 
rem ## join_logo_scp動作確認用バッチファイルの設定ファイル
rem ## 入力：
rem ##  %1     : AVSファイル名またはTSファイル名
rem ## 
rem ## 環境変数（入力）：
rem ##  BASEDIR   : 最初のバッチファイル場所
rem ## 

rem ##------------------------------------------------
rem ## チャプター設定
rem ##------------------------------------------------
rem === チャプター出力先（tvtplay用）を入力ファイルにする場合次のremを消す ===
rem set file_chapter_tvtplay=%~dpn1.chapter

rem === チャプター出力先（カット前）を入力ファイルにする場合次のremを消す ===
rem set file_chapter_org=%~dpn1.chapter.txt
rem === チャプター出力先（カット後）を入力ファイルにする場合次のremを消す ===
rem set file_chapter_cut=%~dpn1.chapter.txt

rem ##------------------------------------------------
rem ## TSファイル指定時の出力先
rem ## OUTDIR\OUTNAME\ に結果が出力される
rem ##------------------------------------------------
rem ##--- 出力設定 ---
set OUTDIR=%BASEDIR%result\
set "OUTNAME=%~n1\"

rem ##------------------------------------------------
rem ## 入力ファイルのフォルダ設定
rem ##------------------------------------------------
rem ##--- 入力設定 ---
set BINDIR=%BASEDIR%bin\
set SETDIR=%BASEDIR%setting\
set JL_DIR=%BASEDIR%JL\
set LG_DIR=%BASEDIR%logo\

rem ##------------------------------------------------
rem ## 動作パラメータ設定
rem ##------------------------------------------------
set LOGO_PATH=%LG_DIR%
set OPT_CHAPTER_EXE=-s 8 -e 4
set JLOGO_CMD=JL_標準.txt

rem ##------------------------------------------------
rem ## 動作設定に使用するファイル名
rem ##------------------------------------------------
rem ##--- 入力データ ---
set file_csv_chlist=ChList.csv
set file_csv_param1=JLparam_set1.csv
set file_csv_param2=JLparam_set2.csv

rem ##--- パラメータ設定用（新規作成ファイル） ---
set file_bat_param=obs_param.bat

rem ##------------------------------------------------
rem ## 作成ファイル名設定
rem ##------------------------------------------------
rem ##--- 作成ファイル名 ---
set file_avs_in=in_org.avs
set file_txt_cpt_org=obs_chapter_org.chapter.txt
set file_txt_cpt_cut=obs_chapter_cut.chapter.txt
set file_txt_cpt_tvt=obs_chapter_tvtplay.chapter

rem ##--- ファイル名設定 ---
set file_avs_logo=obs_logo_erase.avs
set file_avs_cut=obs_cut.avs
set file_avs_in_cutcm=in_cutcm.avs
set file_avs_in_cutcl=in_cutcm_logo.avs
set file_txt_logoframe=obs_logoframe.txt
set file_txt_chapterexe=obs_chapterexe.txt
set file_txt_jlscp=obs_jlscp.txt

exit /b
