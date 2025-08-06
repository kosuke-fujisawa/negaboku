# Phase 2 テストシナリオ：順次実行

## シーン1：背景表示テスト

[bg storage=forest_day.jpg time=500]

**システム**「背景が森の日中に変更されました。」

---

## シーン2：キャラクター表示テスト

[chara_show name=souma face=normal pos=left]

**ソウマ**「僕がソウマです。左側に表示されています。」

---

[chara_show name=yuzuki face=smile pos=right]

**ユズキ**「私はユズキ。右側に登場しました！」

**ソウマ**「二人同時に表示されているはずです。」

---

## シーン3：背景変更テスト

[bg storage=ruins_entrance.jpg time=800]

**ユズキ**「背景が遺跡の入り口に変わりました。」

**ソウマ**「マークダウンファイルの順番通りに処理されていますね。」

---

## シーン4：キャラクター表情変更

[chara_show name=yuzuki face=worried pos=right]

**ユズキ**「表情が心配そうに変わったはずです。」

**ソウマ**「表情の変化もマークダウンで制御できています。」

---

## シーン5：キャラクター非表示テスト

[chara_hide name=souma]

**ユズキ**「ソウマが非表示になりました。私だけが見えているはずです。」

---

[chara_show name=souma face=surprised pos=left]

**ソウマ**「驚いた表情で再登場です！」

**ユズキ**「また二人揃いましたね。」

---

## シーン6：背景＋キャラクター同時変更

[bg storage=ruins_interior.jpg time=600]
[chara_show name=souma face=confident pos=left]
[chara_show name=yuzuki face=determined pos=right]

**ソウマ**「遺跡の内部に入り、二人とも決意を固めた表情になりました。」

**ユズキ**「コマンドが順番に実行されて、背景と立ち絵が同時に更新されています。」

---

## シーン7：待機コマンドテスト

[wait time=1000]

**システム**「1秒間の待機が発生しました。」

**ソウマ**「待機コマンドも正常に動作しています。」

---

## シーン8：完了

**ユズキ**「Phase 2のテストが完了しました！」

**ソウマ**「マークダウンファイルを上から順に読み込み、背景とキャラクター表示が正常に制御されています。」

**システム**「すべてのテストが成功しました。ESCキーでタイトルに戻ってください。」
