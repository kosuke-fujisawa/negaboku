# 願い石と僕たちの絆 - Rust + Bevy版

## 概要
「願い石と僕たちの絆」のRust言語 + Bevyエンジンによる実装です。ECSアーキテクチャを採用し、型安全性と保守性を重視した設計となっています。

## 技術スタック
- **言語**: Rust 1.88.0+
- **ゲームエンジン**: Bevy 0.15
- **アーキテクチャ**: ECS (Entity-Component-System)
- **設計原則**: DDD (Domain-Driven Design) + Clean Architecture

## プロジェクト構造
```
src/
├── domain/              # ドメイン層（ビジネスロジック）
├── application/         # アプリケーション層（ユースケース）
├── infrastructure/     # インフラ層（外部システム連携）
├── systems/            # ECSシステム（Bevy固有）
├── ui/                 # UI層（コンポーネント・リソース）
├── main.rs             # エントリーポイント
└── lib.rs              # ライブラリインターフェース
```

## 主要機能
- ✅ Rust + Bevy開発環境のセットアップ
- ✅ Domain/Application/Infrastructure分離アーキテクチャ
- ✅ ECS基盤設計（Component/System/Resource）
- ✅ Markdownシナリオパーサー
- ✅ テキスト表示・背景切替システム基盤
- ✅ Claude Code連携用開発ガイドライン

## 開発環境セットアップ

### 前提条件
- Rust 1.88.0以上
- macOS/Windows/Linux

### インストール
```bash
# Rustのインストール（未インストールの場合）
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# プロジェクトクローン
git clone <repository-url>
cd negaboku-bevy

# 依存関係のインストールと動作確認
cargo check
```

### 実行
```bash
# 基本動作確認（簡易版）
cargo run

# テスト実行
cargo test

# ライブラリテスト
cargo test --lib
```

## 設計思想

### ECS (Entity-Component-System) アーキテクチャ
- **Entity**: ゲームオブジェクトの識別子（テキストボックス、キャラクター等）
- **Component**: データのみ保持（状態、座標、テキスト内容等）
- **System**: データを処理するロジック（入力処理、レンダリング等）
- **Resource**: グローバルに共有されるデータ（現在のシナリオ、ゲーム設定等）

### レイヤードアーキテクチャ
1. **Domain層**: ゲームの核となるビジネスルール（関係値計算、シナリオデータ等）
2. **Application層**: ユースケース実装（シナリオ読み込み、進行管理等）
3. **Infrastructure層**: 外部システム連携（ファイルI/O、セーブ・ロード等）
4. **Systems層**: Bevyシステム実装（レンダリング、入力処理等）
5. **UI層**: Bevyコンポーネント・リソース定義

## 開発ガイドライン
詳細な開発規約・コーディング標準については `CLAUDE_BEVY_GUIDELINES.md` を参照してください。

## Godotからの移行理由
- **型安全性**: Rustの強力な型システムによる実行時エラーの削減
- **パフォーマンス**: システム言語による高速実行
- **保守性**: DDD/Clean Architectureによる長期保守の容易さ
- **LLM協働**: 明確な責務分離によるClaude Codeとの効率的な開発

## 今後の開発予定
1. **UI実装の完成**: テキスト表示、背景・キャラクター表示の完全実装
2. **関係値システム**: 3段階関係値（対立/通常/親密）の完全実装
3. **シナリオエンジン**: Markdownベースシナリオの完全対応
4. **セーブ・ロード**: ゲーム進行状況の永続化
5. **エフェクト・演出**: パーティクル・アニメーション・音声対応

## ライセンス
このプロジェクトは非商用ライセンスの下で提供されています。詳細は LICENSE ファイルを参照してください。

## 貢献
本プロジェクトはClaude Code (claude.ai/code) との協働開発を前提としています。コントリビューション時は `CLAUDE_BEVY_GUIDELINES.md` の開発原則に従ってください。
