#!/bin/bash
# アプリを短時間実行してログを取得
echo "=== Negaboku-Bevy マークダウンシステム テスト実行 ==="
echo "アプリを10秒間実行してログを確認します..."

cargo run &
APP_PID=$!

# 10秒待機
sleep 10

# アプリを終了
kill $APP_PID 2>/dev/null

echo "=== テスト実行完了 ==="
