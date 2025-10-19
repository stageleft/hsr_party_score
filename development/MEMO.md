# hsr_party_score 開発・運用メモ

## 仕様調査

test.txt に記載の curl コマンドを投げた結果を整形したものが test.json である。

## フォント化けが発生する

OS環境に日本語フォントがないため。
本アプリでは、 "IPAGothic" で決め打つ。

```sh
sudo apt install -y fonts-ipafont
```

利用許諾は https://moji.or.jp/ipafont/license/ を参照。
