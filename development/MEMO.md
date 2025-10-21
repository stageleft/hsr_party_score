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

* score_from_mihomo: ステータス取得処理
  * 入力： UID
  * 処理： `curl -X GET https://api.mihomo.me/sr_info_parsed/{uid}?language={lg} -H User-Agent: hsr_party_score` 相当のクエリを実行する。
  * 出力： 巡星ビザに設定したキャラクターのステータス一式（JSONデータ）
  * is-aクラス： なし
  * has-aクラス： なし
* partycard: パーティカード向けデータ加工処理
  * initialize: コンストラクタ。生成元よりデータを得て、各セルを生成していく。
    * 引数 input_json＠入力: score_from_mihomo より入力されたJSONデータ
  * is-aクラス： パーティカード生成処理
* scorecard: パーティカード生成処理
  ```sh
  # Create Card that can contain 1 player profile and 1...8 unit profile.
  # Each unit has 1 to 11 cells.
  # It means 1 character, 0 to 1 light cone, 0 to 6 relic, 0 to 3 relic set effect.
  # [Player]
  # [unit 1 character   ] [unit 2 character   ] ... [unit 8 character   ]
  # [unit 1 light cone 1] [unit 2 light cone 1] ... [unit 8 light cone 1]
  # [unit 1 relics     1] [unit 2 relics     1] ... [unit 8 relics     1]
  # [    :              ] [    :              ] ... [    :              ]
  # [unit 1 relics     6] [unit 2 relics     6] ... [unit 8 relics     6]
  # [unit 1 relic sets 1] [unit 2 relic sets 1] ... [unit 8 relic sets 1]
  # [    :              ] [    :              ] ... [    :              ]
  # [unit 1 relic sets 3] [unit 2 relic sets 3] ... [unit 8 relic sets 3]
  # All cells are scorecard_anycell class. They have 1 image and multi text line.
  ```
  * initialize: コンストラクタ。生成元よりデータを得て、各セルを生成していく。
    抽象クラスとし、本クラス自身は NotImplementedError をスローする。子クラスは、以下の処理を必須入力とする。
    ```ruby
    @player_info = nil
    @unit_info = []
    ```
  * init_player_info: player部分のセルについて、描画する情報を設定する。
    * 引数cell_param＠入力: セルを描画するために必要な情報
      Hash 形式とし、 `{"image": "image.png", "text": ["text1", "text2", ...]}` で示すような構造をとる。
  * push_unit_info: unit X 部分のセル列について、描画する情報を設定する。
    * 引数cell_array_param＠入力: セルを描画するために必要な情報
      Array of Hash 形式とし、 `[{"image": "image.png", "text": ["text1", "text2", ...]}, ...]` で示すような構造をとる。
  * generate: パーティカードを生成する。
    * 引数output_path＠出力: パーティカードを出力するファイルのパス
  * is-aクラス： なし
  * has-aクラス： scorecard_anycell（パーティカード・セル描画データ管理）
    * 1: プレイヤーの描画データ管理
    * [1..11] x [1..8]: キャラクターの描画データ管理
* scorecard_anycell: パーティカード・セル描画データ管理（基底クラス）
  ```sh
  # A cell that can contain an image and multi-line text.
  # [        ] multi-line text
  # [An Image] multi-line text
  # [        ] multi-line text
  #            multi-line text
  #                :
  ```
  * initialize: コンストラクタ、データを描画するのに必要な情報。
    * @domain: 画像を示すURLのドメイン名。デフォルト値を `https://raw.githubusercontent.com/Mar-7th/StarRailRes/refs/heads/master/` とする。
    * 引数image_path＠入力: 画像を示すURLのパス部分。String の形式とし、 `#{@domain}#{image_path}` で 以下のディレクトリを表すこと。
    * 引数text_array＠入力: 上記画像の左に表示する文字列。Array of String の形式で表し、各String内は1行に表示する文字とすること。
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

