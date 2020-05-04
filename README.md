# join_logo_scp_trial for nodejs & linux
## 概要
「join_logo_scp動作確認用バッチファイル  by Yobi」を参考に[sogaani氏][1]が作成された[nodejs版][2]の改造です。  
ファイルの生成先などをオリジナルに近づけています。  
## 機能
join_logo_scpのCM位置検出機能について動作確認をするスクリプトです。  
TSファイルを入力として、

* CMカットしたAVSファイル  

を作成します。

[1]:https://github.com/sogaani
[2]:https://github.com/sogaani/JoinLogoScp/tree/master/join_logo_scp_trial

## 実行方法
事前にAviSynth+3.5.XとL-SMASH Sourceは入れてください。
1. chapter_exe、logoframe、join_logo_scpをbinフォルダに入れてください。
1. 使用するロゴデータ(*.lgd)をこのフォルダ直下logoフォルダに格納  
1. 実行  
  `npm start "TSファイル"`
1. 検出が自動で行われ結果が生成されます。  

## 謝辞
オリジナルの製作者Yobi氏、  
nodejsに移植をされたsogaani氏、  
に深く感謝いたします。
