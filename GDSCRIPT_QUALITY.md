# GDScript Code Quality Management

## Overview

このプロジェクトでは`gdtoolkit`を使用してGDScriptコードの品質管理を行います。

## Setup

### Requirements

- Python 3.6+
- pipx (推奨) または pip3

### Installation

```bash
# pipxを使用（推奨）
brew install pipx
pipx install "gdtoolkit==4.*"
pipx ensurepath

# 新しいターミナルを開くか、PATHを更新
export PATH="$PATH:$HOME/.local/bin"
```

### Verification

```bash
gdlint --version
gdformat --version
```

## Usage

### Quick Commands

プロジェクトルートで以下のコマンドを実行：

```bash
# 全体の品質チェック（lint + format）
./gdtools.sh all

# リンターのみ実行
./gdtools.sh lint

# フォーマッターのみ実行
./gdtools.sh format

# フォーマット確認（dry run）
./gdtools.sh check
```

### Manual Commands

```bash
# 単一ファイルのリント
gdlint GodotProject/Scripts/game_manager.gd

# 単一ファイルのフォーマット
gdformat GodotProject/Scripts/game_manager.gd

# 全ファイルのフォーマット
find GodotProject/Scripts -name "*.gd" -exec gdformat {} +

# 全ファイルのリント
find GodotProject/Scripts -name "*.gd" -exec gdlint {} +
```

## Configuration

### .gdlintrc

プロジェクトの品質基準に合わせて設定されています：

- **緩和されたルール**: class-definitions-order, max-public-methods, max-returns等
- **重要なチェック**: unused-variable, duplicated-load, trailing-whitespace等
- **調整された制限値**: 行長120文字、ファイル700行まで等

### .gdformat.cfg

フォーマット設定：

- インデント: タブ（Godot標準）
- 行長: 120文字
- 論理演算子前での改行許可

## Quality Improvements Achieved

gdtoolkit導入により以下の改善を実現：

### Before (導入前)
- 100+ lint issues
- 一貫性のないフォーマット
- 多数のtrailing whitespace
- 重複したファイル読み込み

### After (導入後)
- 14 lint issues (83% reduction)
- 統一されたコードフォーマット
- 自動化された品質チェック
- 重複読み込みの解決

## Current Issues

残存する品質問題（14件）：

1. **unused-argument** (14件): 使用されていない関数引数
   - 対処法: `_`プレフィックスを追加するか引数を削除

## Development Workflow

### Pre-commit Workflow

```bash
# コード変更後
./gdtools.sh format  # 自動フォーマット
./gdtools.sh lint    # 品質チェック
git add .
git commit -m "your commit message"
```

### CI/CD Integration

将来的に以下を検討：

```yaml
# .github/workflows/quality.yml
- name: GDScript Quality Check
  run: |
    pip install "gdtoolkit==4.*"
    ./gdtools.sh all
```

## Common Issues and Solutions

### Unused Arguments

```gdscript
# Before
func some_function(used_arg: int, unused_arg: String):
    print(used_arg)

# After
func some_function(used_arg: int, _unused_arg: String):
    print(used_arg)
```

### Line Length

```gdscript
# Before
enum RelationshipLevel { HOSTILE = -1, COLD = 0, NORMAL = 1, FRIENDLY = 2, INTIMATE = 3 }  # Very long line

# After
enum RelationshipLevel {
    HOSTILE = -1,  # 敵対
    COLD = 0,      # 冷淡
    NORMAL = 1,    # 普通
    FRIENDLY = 2,  # 友好
    INTIMATE = 3   # 親密
}
```

### Duplicated Loads

```gdscript
# Before
func function1():
    var script = load("res://Scripts/some_script.gd")
    
func function2():
    var script = load("res://Scripts/some_script.gd")  # Duplicate!

# After
var some_script = preload("res://Scripts/some_script.gd")  # Class-level

func function1():
    # Use some_script
    
func function2():
    # Use some_script
```

## Tools Reference

### gdlint

GDScriptの静的解析ツール：

- 構文チェック
- コードスタイル検証
- 潜在的な問題の検出

### gdformat

GDScriptの自動フォーマッター：

- インデント統一
- 空白の正規化
- コードスタイルの統一

## Configuration Files

- `.gdlintrc`: リンター設定
- `.gdformat.cfg`: フォーマッター設定
- `gdtools.sh`: プロジェクト専用スクリプト

## Next Steps

1. 残りの未使用引数の修正
2. pre-commit hook の導入検討
3. CI/CDパイプラインへの統合
4. 定期的な品質監視の実装

---

## Contributing

コードを変更する際は必ず品質チェックを実行してください：

```bash
./gdtools.sh all
```

品質問題がある場合はコミット前に修正してください。