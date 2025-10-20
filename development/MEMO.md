# hsr_party_score 開発・運用メモ

## 仕様調査

test.txt に記載の curl コマンドを投げた結果を整形したものが test.json である。

### フォント化けが発生する

OS環境に日本語フォントがないため。
本アプリでは、 "IPAGothic" で決め打つ。

```sh
sudo apt install -y fonts-ipafont
```

利用許諾は https://moji.or.jp/ipafont/license/ を参照。

## 機能設計

以下の処理を準備する。

* 巡星ビザ（サポートキャラ、星海同伴）に設定したキャラのステータスを MiHoMo API から取得する。

## モジュール設計

* ステータス取得処理
  * 入力： UID
  * 処理： `curl -X GET https://api.mihomo.me/sr_info_parsed/{uid}?language={lg} -H User-Agent: hsr_party_score` 相当のクエリを実行する。
  * 出力： 巡星ビザに設定したキャラクターのステータス一式（JSONデータ）
  * is-aクラス： なし
  * has-aクラス： なし
* （未定義）パーティカード向けJSONデータ加工処理
  * メモ：下記「パーティカード生成処理」の入力に無理があるので、いずれ必要になる。
* パーティカード生成処理
  * 入力： 巡星ビザに設定したキャラクターのステータス一式
    * メモ：データの抜き出し・加工処理が必要になっており、「パーティカード生成」の責務としては過大。rubocopにもそう言われている。
      ```
      api/scorecard.rb:10:1: C: Metrics/ClassLength: Class has too many lines. [163/100]
      class ScoreCard ...
      ^^^^^^^^^^^^^^^
      ```
      このままでは、目標値まわりの判定処理まで発生しうるので、
  * 出力： パーティカード
  * is-aクラス： なし
  * has-aクラス
    * （未定義）スコアカード・プレイヤー描画データ管理[1]
    * （未定義）スコアカード・キャラクター描画データ管理[1..8]
    * （削除予定）スコアカード・セル描画データ管理[1...]

* （未定義）スコアカード・プレイヤー描画データ管理
  * 入力： プレイヤーの基礎情報として下記の内容を、スコアカード・セル描画データ管理からの継承で表現する。
    * プレイヤーが使っているアイコンを示すURL。String の形式で `https://raw.githubusercontent.com/Mar-7th/StarRailRes/refs/heads/master/` 以下のディレクトリを表すこと。
    * プレイヤーに属する情報を示した文字列。
  * 出力： スコアカード・セル描画データ管理より下記を継承する。
    * render_area: プレイヤーの情報を描画する関数
    * calc_area: 上記描画に必要な領域のサイズを算出する関数。
  * is-aクラス： スコアカード・セル描画データ管理
  * has-aクラス： なし

* （未定義）スコアカード・キャラクター描画データ管理
  * 入力：JSONデータ
  * 出力：パーティカード
  * is-aクラス： スコアカード・セル描画データ管理
  * has-aクラス： スコアカード・セル描画データ管理[1..11]
    * キャラクター x 1
    * 光円錐 x 1
    * 遺物・オーナメント x 6
    * 遺物セット効果 x 3

* scorecard_anycell: スコアカード・セル描画データ管理
  * 定数
    * @domain: URLのドメイン名。デフォルト値を `https://raw.githubusercontent.com/Mar-7th/StarRailRes/refs/heads/master/` とする。
  * 入力
    * image_path: 画像を示すURL。String の形式とし、 `#{@domain}#{image_path}` で 以下のディレクトリを表すこと。
    * text_array: 上記画像の左に表示する文字列。Array of String の形式で表し、各String内は1行に表示する文字とすること。
  * 出力
    * render_area: 入力された情報をもとに、 Cairo::Context オブジェクトにセルを描画する関数
    * calc_area: 上記描画に必要な領域のサイズを算出する関数。 { x: integer, y: integer } のHashオブジェクトを返す。
  * is-aクラス：なし
  * has-aクラス：なし

* （定義しない）描画データ管理抽象クラス
  * initialize: コンストラクタ、データを描画するのに必要な情報。
    * 引数なし、管理すべきデータを継承先にて入力データとする。
    * コンストラクタなので戻り値なし。
  * render_area: Cairo::Context オブジェクトに描画するメソッド
    * 引数context＠出力: 描画先の Cairo::Context オブジェクト
    * 引数offset＠入力: 描画開始点を表す { x: integer, y: integer } 形式のHashオブジェクト
    * 戻り値なし。
  * calc_area: 上記描画に必要な領域のサイズを算出するメソッド。
    * 引数なし。
    * 戻り値： { x: integer, y: integer } のHashオブジェクト

## 参考

* March 7th : https://march7th.xyz/en/
  * MiHoMo API > Parsed Data API を、API仕様書として参照。

