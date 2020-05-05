# join_logo_scp_trial for nodejs & linux
## 概要
「join_logo_scp動作確認用バッチファイル  by Yobi」を参考に[sogaani氏][1]が作成された[nodejs版][2]の改造です。  
ファイルの生成先などをYobi氏の作成されたオリジナルにあわせています。 

[1]:https://github.com/sogaani
[2]:https://github.com/sogaani/JoinLogoScp/tree/master/join_logo_scp_trial

## 機能
join_logo_scpのCM位置検出機能について動作確認をするスクリプトです。  
TSファイルを入力として、

* CMカットしたAVSファイル  
* CMカットのためのffmpegへのフィルターオプション

を作成します。  
（私はffmpegへのフィルターオプションは利用しないので未確認です。sogaani氏の作られたコードで生成されます。）

## 実行方法
事前にAviSynth+3.5.XとL-SMASH Sourceは入れてください。
1. chapter_exe、logoframe、join_logo_scpをbinフォルダに入れてください。
1. 使用するロゴデータ(*.lgd)をこのフォルダ直下logoフォルダに格納  
1. 実行  
  `npm start -- -i "TSファイル"`
1. 検出が自動で行われ結果が生成されます。  

TSファイルは相対パスで指定しても一応絶対パスに変換しますが、絶対パスで入力を推奨とします。

| オプション| 指定内容 |説明 |
|:---:|:---:|:---|
|--|何も指定しない|仕様上必須です。|
|-i|対象動画のパス|必須です。TSファイルのパスを指定します|
|-f|true<br>false|\[デフォルト:false\]任意です。<br>ffmpegへのフィルターを生成する場合はtrueを指定します。|

例（ffmpegフィルタ生成時）：`npm start -- -i "/tmp/test/局名_タイトル 話数.ts" -f true`

## 生成されるもの
| ファイル名| 内容 |
|:---|:---|
|in_cutcm.avs|結果（CMカットした入力ファイル）|
|in_cutcm_logo.avs|結果（CMカット＋delogo.so適用入力ファイル）[delogoもlinux対応改造済み][3]|
|in_org.avs|CMカット前の入力ファイル|
|obs_cut.avs|CMカットフレーム位置|
|obs_chapterexe.txt|chapter_exe結果|
|obs_logoframe.txt|logoframe結果|
|obs_jlscp.txt|join_logo_scpによる番組構成解析結果|
|obs_param.txt|ファイル名からタイトル、局名を検出し使用したJLparamの情報|

その他にもいくつか出力されますが、一時ファイルです。

[3]:https://github.com/tobitti0/delogo-AviSynthPlus-Linux

## 謝辞
オリジナルの製作者Yobi氏、  
nodejsに移植をされたsogaani氏、  
に深く感謝いたします。

## 主な変更点
sogaani氏が作成されたnodejs版からの主な改造点です。
* チャンネル略称が先頭に来る場合のチャンネル検出パターンの追加
* JLparam検出がうまくいっていなかったのを修正
* JLparam検出結果（利用したJLparam情報）を保存するようにした
* in_cutcm.avs in_cutcm_logo.avsを生成する機能の追加（そのままffmpegに食わせて実行できるファイル）
* Yobi氏が制作されたものと同じようにresultフォルダにファイル名のフォルダを生成し、そこにデータを保存するようにした
* 上記の変更に伴い、avsファイルとfilterファイルの保存先オプションの廃止
* ffmpeg用のfilterはオプションで指定し生成するように変更
* ファイル名からチャンネル名を検出できなかった時や、ロゴデータを見つけれなかった時はロゴフォルダの中をすべてlogoframeにわたすように変更
* FFMS2ではなくL-SMASH Sourceを用いて入力するように変更
* ライブラリの更新
