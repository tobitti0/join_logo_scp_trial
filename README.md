# 概要
「join_logo_scp動作確認用バッチファイル  by Yobi」を参考に作成させていただきました。
フォルダ構成や設定ファイル等は「join_logo_scp動作確認用バッチファイル  by Yobi」と同様にしています。

join_logo_scpのCM位置検出機能について動作確認をするスクリプトです。
TSファイルを入力として、
* CMカットのためのffmpegへのフィルターオプション
* CMカットしたAVSファイル

を作成します。

# 想定読者
join_logo_scp, Linux, ffmpeg, docker についての知識を有している方。

# 事前準備

## OS
Linux上での動作を想定しています。

## その他
Dockerfileを使って、実行環境を構築できます。
通常は次のDockerfileを使って環境を構築してください。
* /docker/normal/Dockerfile


vaapiを使ってlogoframeやchpter_exeのデコードを行いたい場合は次のDockerfileを利用できます。
* /docker/vaapi/Dockerfile

  vaapiを使う場合は、ホスト上でvaapiが利用できるようになっていることと、コンテナ起動時に `--privileged` オプションが必要です。

# 実行方法

```
npm start -- -i "TSファイル" -f "出力ffmpegフィルター" -a "出力AVS"
```

例
```
npm start -- -i "/mnt/share/hoge.ts" -f "/usr/local/hoge.filter" -a "/usr/local/hoge.avs"
```
