# アーキテクチャ設計書

## 概要

「願い石と僕たちの絆」は**DDD（ドメイン駆動設計）+ クリーンアーキテクチャ + ECS**を採用した Rust + Bevy ベースのビジュアルノベル/RPG です。

## アーキテクチャ原則

### 1. 依存方向の制御
```
Presentation -> Application -> Domain
Infrastructure -> Application -> Domain
```

- **Domain**: 外部への依存なし（純粋なビジネスロジック）
- **Application**: Domain に依存、システム統合を担当
- **Infrastructure**: ファイル IO・外部 API・Bevy アセット管理
- **Presentation**: UI・入力処理（main.rs に集約）

### 2. ECS設計原則

#### Entity
- 純粋な識別子のみ（データを持たない）
- Bevy 標準の Entity システムを活用

#### Component
- 純粋なデータ構造（ロジックを持たない）
- 単一責任の原則を徹底

#### System
- Component 間のロジック処理
- 状態変更は System でのみ実行

#### Resource
- グローバル状態管理
- シナリオ進行、関係値テーブル等

## プロジェクト構造

```
src/
├── main.rs                    # エントリポイント・UI層
├── domain/                    # ドメイン層（ビジネスロジック）
│   ├── mod.rs
│   ├── relationship.rs        # 関係値エンティティ・計算ロジック
│   ├── scenario.rs           # シナリオ構造・コマンドパーサー
│   └── character.rs          # キャラクター定義・表示状態
├── application/              # アプリケーション層（システム統合）
│   ├── mod.rs
│   ├── scenario_system.rs    # シナリオ実行システム
│   └── command_executor.rs   # コマンド実行システム
├── infrastructure/           # インフラストラクチャ層
│   ├── mod.rs
│   └── scenario_loader.rs    # Markdownファイル読み込み
└── presentation/            # プレゼンテーション層（将来実装）
    ├── mod.rs
    ├── dialogue_ui.rs        # テキスト表示UI
    └── battle_ui.rs          # 戦闘UI
```

## レイヤー別責務

### Domain層（ドメイン層）
**責務**: ビジネスルールの実装
- 関係値システム（3 段階：対立/通常/親密）
- シナリオコマンド定義（背景切替、キャラ表示等）
- キャラクター情報管理
- **外部依存なし**: pure Rust、最小限の serde 使用

### Application層（アプリケーション層）
**責務**: ドメインロジックと ECS の統合
- シナリオ実行システム（マークダウンパーサー統合）
- コマンド実行システム（背景・キャラクター制御）
- 状態遷移管理
- **依存**: Domain 層のみ

### Infrastructure層（インフラストラクチャ層）
**責務**: 外部システム連携
- ファイル IO（シナリオ・セーブデータ）
- Bevy アセット読み込み
- 音声・画像リソース管理
- **依存**: Domain、Application 層

### Presentation層（プレゼンテーション層）
**責務**: UI・入力処理
- 現在は main.rs に集約
- 将来的には module 分割
- テキスト表示、ボタン処理
- **依存**: Application 層

## ECSコンポーネント設計

### 主要コンポーネント

#### GameState関連
```rust
#[derive(Resource)]
struct GameMode {
    is_story_mode: bool,
    current_screen: GameScreen,
}

#[derive(Resource)]
struct ScenarioState {
    lines: Vec<String>,
    current_index: usize,
    is_complete: bool,
}
```

#### UI関連
```rust
#[derive(Component)]
struct VNDialogue {
    full_text: String,
    current_char: usize,
    is_complete: bool,
    timer: Timer,
}

#[derive(Component)]
struct CharacterDisplay {
    character_id: String,
    current_face: String,
    position: CharacterDisplayPosition,
    is_visible: bool,
}
```

#### 背景・演出
```rust
#[derive(Component)]
struct BackgroundController {
    backgrounds: Vec<Color>,
    current_index: usize,
}
```

## システム実装方針

### 1. テスト駆動開発（TDD）
- 各ドメインロジックに対応するテストを必須実装
- `cargo test`で全テスト実行可能
- Red -> Green -> Refactor サイクル

### 2. 単一責任システム
- 1 システム 1 機能を徹底
- 複雑なシステムは複数の小さなシステムに分割
- システム間の依存関係を最小化

### 3. データ駆動設計
- 設定値のハードコーディング禁止
- Markdown シナリオによる宣言的記述
- コンポーネントは純粋なデータ構造

## 開発フロー

### 1. ドメイン実装
```bash
# ドメインロジック実装
cd src/domain/
# テスト先行で実装
cargo test
```

### 2. アプリケーション層実装
```bash
# システム実装
cd src/application/
# ECSシステムとドメインロジックを統合
```

### 3. 統合テスト
```bash
# 全レイヤー統合テスト
cargo test
cargo run
```

## 品質保証

### 静的解析
```bash
cargo fmt --check    # フォーマットチェック
cargo clippy -- -D warnings  # lint（警告をエラー扱い）
```

### 自動化
- pre-commit フック（コミット前品質チェック）
- GitHub Actions CI/CD（マルチプラットフォームテスト）

## マルチプラットフォーム対応

### サポート予定
- **Windows** (優先実装)
- **macOS** (標準対応)
- **Linux** (標準対応)

### ビルド設定
```bash
# プラットフォーム別ビルド
cargo build --release                               # 現在のプラットフォーム
cargo build --release --target x86_64-pc-windows-gnu     # Windows
cargo build --release --target x86_64-apple-darwin       # macOS
cargo build --release --target x86_64-unknown-linux-gnu  # Linux
```

---

## 実装優先順位

1. **Phase 1**: ドメイン層完成（関係値・シナリオ・キャラクター）
2. **Phase 2**: マークダウンパーサー統合・シナリオ実行
3. **Phase 3**: UI 層分離・プレゼンテーション層モジュール化
4. **Phase 4**: 戦闘システム・関係値連動機能
5. **Phase 5**: セーブシステム・設定管理

このアーキテクチャにより、**保守性・テスト容易性・拡張性**を確保し、LLM 協働開発に最適化された構造を実現します。
