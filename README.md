# hsr_party_score

崩壊：スターレイル 向け攻略ツール。
巡星ビザ（サポートキャラ、星海同伴）に設定した８キャラから４キャラをピックアップした編成にて、
パーティメンバーの能力値について現在値および目標値との差異を確認するツール。

編成単位を考慮するため、しばらくの間は速度のみを取り扱う。

## 実装済み機能

* コマンドライン処理（rubyスクリプトとして）
  * 巡星ビザ（サポートキャラ、星海同伴）に設定したキャラのステータスを MiHoMo API から取得する。
    `curl -X GET https://api.mihomo.me/sr_info_parsed/{uid}?language={lg} -H User-Agent: hsr_party_score` 相当のクエリを実行する。
    詳細は https://march7th.xyz/en/ から、 MiHoMo API > Parsed Data API を参照。
  * 取得した最大8キャラクター分のデータをもとに、ステータスを記載した画像ファイルを出力する。これをパーティーカードと呼ぶ。
    * 表示ステータスを、速度のみに絞り込んでパーティーカードのレイアウトを調整する。

## 対応予定要求事項（処理部分）

* プログラム内でJSONデータを持ち、下記を管理する。
  * 編成（２編成以上を管理する）
  * １人目の目標速度ステータス
  * ２人目の目標速度ステータス（２人以上の編成の場合）
  * ３人目の目標速度ステータス（３人以上の編成の場合）
  * ４人目の目標速度ステータス（４人以上の編成の場合）
* パーティーカード1枚あたりの出力は、１編成つまり4キャラまでとなる。
* パーティーカードの出力に、目標値との差異（評価値）を出力する。

## 対応予定要求事項（操作性、インタフェース部分）

* Web UIを準備する。
  * UIDおよび言語を指定し、「データ取得」ボタンを押下すると、上記「～MiHoMo API から取得する。」処理が動く。
    そのままパーティカードを生成・表示し、ダウンロード可能な状態にする。
  * 編成および目標値を設定・管理する手段を提供する。上記「プログラム内でJSONデータを持ち、下記を管理する。」のためのインタフェース。

### 言語、開発プラットフォーム

* コンテナの手元作成： docker compose build コマンドを想定。
* コンテナの手元実行： docker compose up コマンドを想定。
* コンテナの正式作成： GitHub Actions ワークフロー を想定。
* コンテナレジストリ： GitHub Container Registry （ghcr.io）を想定。
  参考： https://docs.github.com/ja/packages/working-with-a-github-packages-registry/working-with-the-container-registry
* コンテナの正式実行： Azure Container Apps を想定。
  参照： https://learn.microsoft.com/ja-jp/azure/container-apps/overview
