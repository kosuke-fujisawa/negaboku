# シナリオ品質管理システム - textlint導入ガイド

## 🎯 概要

「願い石と僕たちの絆」プロジェクトでは、シナリオファイル（マークダウン形式）の品質管理にtextlintを導入しています。これにより、誤字脱字・表記揺れの自動検出、統一性チェック、CI/CD統合による継続的品質保証を実現しています。

## 📁 対象ファイル

- `negaboku-bevy/assets/scenarios/**/*.md` - すべてのシナリオファイル

## 🔧 ローカル開発での使用方法

### 1. 依存関係のインストール

```bash
npm install --legacy-peer-deps
```

### 2. 基本コマンド

```bash
# シナリオファイルの品質チェック実行
npm run textlint:check

# 自動修正可能な問題を修正
npm run textlint:fix

# 手動チェック（全ファイル対象）
npm run textlint
```

### 3. VS Code統合（推奨）

#### 必要な拡張機能
- `taichi.vscode-textlint` - リアルタイム品質チェック
- `davidanson.vscode-markdownlint` - Markdown lint機能
- `yzhang.markdown-all-in-one` - Markdown編集支援

#### 設定
- `.vscode/settings.json`で自動設定済み
- ファイル保存時に`source.fixAll.textlint`が実行される
- リアルタイムで問題が表示される

## 📋 品質チェック項目

### 基本品質ルール

1. **文章長制限**: 1文120文字以内
2. **句読点統一**: 適切な句読点使用
3. **表記統一**: 半角・全角間スペース調整
4. **文体統一**: である調で統一（設定可能）

### カスタムルール（ゲーム固有）

#### 1. キャラクター名統一 (`character-names`)
- **ソウマ** - `souma`, `そうま`, `Souma` → `ソウマ`
- **ユズキ** - `yuzuki`, `ゆずき`, `Yuzuki` → `ユズキ`
- **レツジ** - `retsuji`, `れつじ`, `Retsuji` → `レツジ`
- **カイ** - `kai`, `かい`, `Kai` → `カイ`

#### 2. ゲーム内用語統一 (`game-terminology`)
- **願い石** - `ねがいいし`, `願石` → `願い石`
- **遺跡** - `いせき`, `遺跡群` → `遺跡`
- **技術用語スペース** - `Rust版` → `Rust 版`

#### 3. セリフ記法正規化 (`dialogue-format`)
- 正しい記法: `**キャラクター名**「セリフ内容」`
- 間違い例:
  - `*キャラクター名*「セリフ」` → アスタリスク1つ
  - `**キャラクター名**: セリフ` → コロン使用
  - `キャラクター名「セリフ」` → **囲みなし

## 🚀 CI/CD統合

### GitHub Actions自動チェック

- **トリガー**: PRまたはmainブランチへのプッシュ
- **対象**: シナリオファイル変更時のみ実行
- **結果**: PRにコメントで詳細表示

### 品質ゲート

- **エラーレベル**: マージブロック対象
- **警告レベル**: マージ可能、要確認
- **自動修正**: `npm run textlint:fix`コマンド提案

## 🛠️ pre-commitフック

### インストール

```bash
pip install pre-commit
pre-commit install
```

### 自動実行内容

1. **textlint**: シナリオファイルの品質チェック
2. **cargo fmt**: Rustコードフォーマット
3. **cargo clippy**: Rustコード品質チェック
4. **基本チェック**: trailing whitespace、JSON/YAML構文等

## 📖 エラーメッセージの読み方

### 基本構造

```
/path/to/file.md
  行:列  error  エラーメッセージ  ルール名

例:
scene01.md
  32:10  error  "…" が連続して2回使われています。  ja-technical-writing/ja-no-successive-word
  45:1   error  キャラクター名は「ソウマ」で統一してください（「souma」→「ソウマ」）  character-names
```

### 修正の優先順位

1. **🔴 エラーレベル**: 必修修正（マージブロック対象）
2. **🟡 警告レベル**: 推奨修正
3. **✓ 自動修正可能**: `npm run textlint:fix`で一括修正

## 🔍 トラブルシューティング

### よくある問題

#### 1. カスタムルールが動作しない
```bash
# 設定ファイル確認
cat .textlintrc.json

# ルールファイル存在確認
ls -la textlint-rules/
```

#### 2. pre-commitフックでエラー
```bash
# 手動でpre-commitテスト
pre-commit run --all-files

# 特定フックのみ実行
pre-commit run textlint-scenario-check
```

#### 3. VS Code拡張機能が動作しない
1. textlint拡張機能の再起動
2. `Developer: Reload Window`実行
3. `.vscode/settings.json`設定確認

### デバッグコマンド

```bash
# textlint詳細ログ
npx textlint --debug negaboku-bevy/assets/scenarios/scene01.md

# 設定内容確認
npx textlint --print-config

# ルールディレクトリ確認
npx textlint --rulesdir ./textlint-rules --help
```

## 📚 参考リンク

- [textlint公式ドキュメント](https://textlint.github.io/)
- [プリセットja-technical-writing](https://github.com/textlint-ja/textlint-rule-preset-ja-technical-writing)
- [GitHub Actions textlintワークフロー例](https://github.com/textlint/textlint/wiki)

---

## 🎮 プロジェクト固有の品質方針

### シナリオライティングガイドライン

1. **キャラクターの一貫性**: 各キャラクターの口調・性格を統一
2. **世界観の統一**: ゲーム内用語の表記を徹底的に統一
3. **読みやすさ**: 適切な文章長と句読点で視認性確保
4. **自動化優先**: 人的チェックを最小限にし、自動品質保証を重視

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
