@echo off

rem ##
rem ## join_logo_scp簡易実行 - avs作成までの動作
rem ## 入力：
rem ##  %1     : avsファイル名またはtsファイル名
rem ##
rem ## 出力：
rem ##  (ファイル名)%file_avs_in% : avsファイル
rem ##
rem ## 環境変数（入力）：
rem ##  file_avs_in  : 作成するavsファイル名
rem ##  use_tssplit  : tsファイル入力時の動作指定
rem ##  use_intools  : tsファイル入力時の動作指定
rem ##  tffbff       : L-Smash Worksに設定する場合、TFFまたはBFF
rem ##

rem ##--- avs入力時は事前設定不要 ---
if "%~x1" == ".avs" goto label_in_avs

rem ##------------------------------------------------
rem ## TsSplitter使用例
rem ##------------------------------------------------
rem ##--- tsファイル事前処理動作（例） ---
if "%use_tssplit%" == "1" goto label_tssplitter_1
if "%use_tssplit%" == "2" goto label_tssplitter_2
goto skip_tssplitter

:label_tssplitter_1
  TsSplitter.exe" -EIT -ECM -SD -1SEG "%~1"
  if not exist "%~dpn1_HD%~x1" goto skip_tssplitter
  move /Y "%~1" "%~dpn1_org%~x1"
  move /Y "%~dpn1_HD%~x1" "%~1"
  goto skip_tssplitter

:label_tssplitter_2
  rem 別の切り出しを行う
  goto skip_tssplitter

:skip_tssplitter

rem ##------------------------------------------------
rem ## DGIndex等を使用した動作分岐例
rem ##------------------------------------------------
rem ## 
rem ## use_intoolsの使用例（0が通常）
rem ##  0  : L-SMASH Works
rem ##  1  : dgindex + FAW
rem ## 10  : L-SMASH Works + ts_parser + FAW
rem ## 

rem ##---dgindex動作確認 ---
if "%use_intools%" == "1" goto label_dgindex

rem ##------------------------------------------------
rem ##（通常入力） L-SMASH Worksで入力avsファイル作成
rem ##------------------------------------------------
rem ##--- tsファイル入力時のavs作成 ---
:label_in_ts
set dominance=0
if "%tffbff%" == "TFF" set dominance=1
if "%tffbff%" == "BFF" set dominance=2
>  "%file_avs_in%" echo TSFilePath="%~1"
>> "%file_avs_in%" echo LWLibavVideoSource(TSFilePath, repeat=true, dominance=%dominance%)

rem ##--- 音声をts_parserで作成する場合は移動 ---
if "%use_intools%" == "10" goto label_tsparser

>> "%file_avs_in%" echo AudioDub(last, LWLibavAudioSource(TSFilePath, stream_index=1, av_sync=true))
goto label_in_end

rem ##------------------------------------------------
rem ##（別ツール使用例）DGIndex動作
rem ##------------------------------------------------
:label_dgindex
echo DGIndexを使用します
set named2v=work_d2v
set nameinaac1=%named2v%*ms.aac
set nameinwav1=%named2v%*ms_aac.wav

DGIndex.exe -SD=? -AIF=?%~1? -OF=?%named2v%? -IA=3 -hide -exit
>  "%file_avs_in%" echo MPEG2Source("%named2v%.d2v", idct=3)
call :sublabel_faw
>> "%file_avs_in%" echo AudioDub(last,WavSource("%nameinwav%"))
>> "%file_avs_in%" echo YV12toYUY2(itype=0,interlaced=true,cplace=0)
goto label_in_end

rem ##------------------------------------------------
rem ##（別ツール使用例）ts_parser動作
rem ##------------------------------------------------
:label_tsparser
set nametsp=work_tsp
set nameinaac1=%nametsp%*ms.aac
set nameinwav1=%nametsp%*ms_aac.wav

ts_parser.exe --mode da -o "%nametsp%" "%~1"
call :sublabel_faw
>> "%file_avs_in%" echo AudioDub(last,WavSource("%nameinwav%"))
goto label_in_end

rem ##------------------------------------------------
rem ## サブルーチン
rem ##（別ツール使用例）FAW動作
rem ##------------------------------------------------
:sublabel_faw
FOR /F "delims=* usebackq" %%t IN (`dir /b "%nameinaac1%"`) DO set nameinaac=%%t
fawcl.exe -s2 "%nameinaac%"
FOR /F "delims=\ usebackq" %%t IN (`dir /b "%nameinwav1%"`) DO set nameinwav=%%t
exit /b


rem ##------------------------------------------------
rem ## 入力avsファイル作成（入力avsファイルをコピー）
rem ##------------------------------------------------
rem ##--- avsファイル入力時は作業用の名前でコピー ---
:label_in_avs
copy "%~1" "%file_avs_in%"

:label_in_end

exit /b
