# リポジトリガイドライン

## プロジェクト概要

**願い石と僕たちの絆** は Rust + Bevy ECS で開発された関係値重視のRPGです。固定2人パーティ、選択肢ベースの探索、3段階の親密度システム（対立／通常／親密）を特徴とし、Windows・Mac・Linuxで動作します。

### 主な特徴
- 親密度に応じた動的な戦闘スキル（親密時：共闘技、対立時：ライバル技）
- 2人パーティのターン制バトルと選択肢によるダンジョン進行
- ギフトやイベントで親密度が変化するローグライク要素

### 技術スタック＆アーキテクチャ
- **Rust** ≥1.88、**Bevy** 0.15 (ECS)
- **UI**: bevy_ui（必要に応じて bevy_egui）
- **アーキテクチャ**: DDD＋クリーンアーキテクチャ＋ECS（Domain、Application、Infrastructure、Presentation）

## プロジェクト構成

```text
./
├── docs/                  # 設計仕様・アーキテクチャ資料
├── negaboku-bevy/         # Rust+Bevy 実装（ソース、アセット、設定）
├── README.md              # プロジェクト概要とクイックスタート
├── CLAUDE.md              # AIエージェントガイドライン
├── .pre-commit-config.yaml # GDScript整形＆チェック設定
└── LICENSE                # ライセンス情報
```

詳細は `docs/architecture-design.md` を参照してください。

## ビルド・テスト・開発コマンド

> Rustツールチェーン（1.75+）とGNU Bashを前提とします。

```bash
# Bevyサブプロジェクトへ移動
cd negaboku-bevy

# ゲーム実行
cargo run

# 変更監視＋ホットリロード
cargo watch -x run

# 単体／統合テスト実行
cargo test

# 10秒間の動作確認
./test_run.sh

# コード整形＆Lint
cargo fmt                     # フォーマッタ
cargo clippy                  # Linter（clippy.toml設定）
pre-commit run --files "**/*.gd" # GDScript整形・構文チェック
```

## コーディングスタイル＆命名規則

- **Rust**: `rustfmt.toml`、`clippy.toml` に従う
- 関数／変数：`snake_case`、型：`CamelCase`、定数：`UPPER_CASE`
- **GDScript**: `gdformat` による自動整形、拡張子 `.gd`

## テストガイドライン

- テストは `src/` 内または `tests/` モジュールに配置し、`#[test]` を使用
- `cargo test` で全テストを実行

## コミット＆プルリクエスト

- Conventional Commits（`feat:`、`fix:`、`docs:`、`style:` など）を遵守
- コミットメッセージに関連Issue/PR番号（例：`#42`）を明記
- PR作成時:
  1. タイトルと説明を明確に記載し、関連Issueをリンク
  2. UI変更ならスクリーンショットやログを添付
  3. `cargo fmt`、`cargo clippy`、`pre-commit` が通っていること
  4. レビュワーをアサインし、レビュー依頼

## 参考資料

- アーキテクチャ詳細: `docs/architecture-design.md`
- システム仕様: `docs/game-systems.md`、`docs/implementation-guidelines.md`

ご協力ありがとうございます！
