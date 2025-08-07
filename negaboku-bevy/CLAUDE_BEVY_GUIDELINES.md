# Claude Code + Rust + Bevy 開発ガイドライン

## 概要
本ドキュメントは、「願い石と僕たちの絆」のRust + Bevy版開発において、Claude Code（claude.ai/code）とのLLM協働開発を効率化するためのガイドラインです。

## アーキテクチャ原則

### Domain-Driven Design (DDD) + Clean Architecture
```
src/
├── domain/              # ドメイン層（ビジネスロジック）
│   ├── character.rs    # キャラクターエンティティ
│   ├── relationship.rs # 関係値システム
│   ├── scenario.rs     # シナリオモデル
│   └── story_state.rs  # ストーリー状態
├── application/         # アプリケーション層（ユースケース）
│   ├── scenario_service.rs      # シナリオ処理サービス
│   ├── relationship_service.rs  # 関係値管理サービス
│   └── story_progression_service.rs # ストーリー進行サービス
├── infrastructure/     # インフラ層（外部システム連携）
│   ├── file_loader.rs  # ファイル読み込み
│   └── save_system.rs  # セーブ・ロード
├── systems/            # ECSシステム（Bevy固有）
│   ├── input_system.rs           # 入力処理
│   ├── text_display_system.rs    # テキスト表示
│   ├── background_system.rs      # 背景管理
│   └── scenario_progression_system.rs # シナリオ進行
└── ui/                 # UI層（コンポーネント・リソース）
    ├── components.rs   # Bevyコンポーネント定義
    └── resources.rs    # Bevyリソース定義
```

### ECS (Entity-Component-System) 設計原則
- **Entity**: ゲームオブジェクトのID（テキストボックス、キャラクター、背景等）
- **Component**: データのみ保持（DialogueText, BackgroundImage, CharacterSprite等）
- **System**: ロジック処理（input_system, text_display_system等）
- **Resource**: グローバルデータ（CurrentScenario, GameState等）

## コーディング規約

### 命名規則
- **構造体・列挙型**: PascalCase (`DialogueText`, `ScenarioBlock`)
- **関数・変数**: snake_case (`current_scene`, `modify_relationship`)
- **定数**: UPPER_SNAKE_CASE (`MAX_RELATIONSHIP`, `DEFAULT_TYPING_SPEED`)
- **ファイル・モジュール**: snake_case (`scenario_service.rs`, `text_display_system.rs`)

### Rust固有のベストプラクティス
```rust
// ✅ 推奨: Result型を使用したエラーハンドリング
pub fn load_scenario(path: &str) -> Result<ScenarioData, Box<dyn std::error::Error>> {
    let content = std::fs::read_to_string(path)?;
    parse_markdown_content(&content)
}

// ✅ 推奨: 借用とライフタイムの適切な使用
pub fn get_relationship(&self, char1: &str, char2: &str) -> i32 {
    let key = self.normalize_key(char1, char2);
    *self.relationships.get(&key).unwrap_or(&0)
}

// ✅ 推奨: パターンマッチングの活用
match scenario_block {
    ScenarioBlock::Text { speaker, content } => {
        spawn_dialogue_text(&mut commands, speaker, content);
    }
    ScenarioBlock::Background { path } => {
        spawn_background(&mut commands, &asset_server, path);
    }
    _ => {}
}
```

### Bevy固有の実装パターン
```rust
// ✅ 推奨: Componentの定義
#[derive(Component)]
pub struct DialogueText {
    pub text: String,
    pub char_index: usize,
    pub is_complete: bool,
}

// ✅ 推奨: Systemの定義
pub fn text_display_system(
    mut query: Query<(&mut DialogueText, &mut Text)>,
    time: Res<Time>,
) {
    for (mut dialogue, mut text) in query.iter_mut() {
        // システムロジック
    }
}

// ✅ 推奨: Resourceの定義
#[derive(Resource)]
pub struct CurrentScenario {
    pub data: ScenarioData,
    pub current_block_index: usize,
}
```

## 責務分離方針

### Domain層（ビジネスロジック）
- **責務**: ゲームの核となるルール・データモデル・計算処理
- **禁止事項**: UI、ファイルI/O、Bevy固有APIへの依存
- **例**: 関係値計算、シナリオデータ構造、キャラクター定義

### Application層（ユースケース）
- **責務**: Domain層の機能を組み合わせた業務フロー
- **許可事項**: Domain層とInfrastructure層の呼び出し
- **例**: シナリオファイルの読み込み〜パース〜保存の一連の流れ

### Infrastructure層（外部システム連携）
- **責務**: ファイルシステム、ネットワーク、データベース等の外部I/O
- **実装**: Domain層で定義されたインターフェースの具象化
- **例**: MarkdownファイルのI/O、セーブデータの永続化

### Systems層（ECS処理）
- **責務**: Bevyのシステムとして動作するゲームループ処理
- **連携**: Application層のサービスを呼び出し、UI層を更新
- **例**: 入力処理、レンダリング、物理シミュレーション

### UI層（プレゼンテーション）
- **責務**: BevyのComponent/Resourceとしてのデータ定義
- **制約**: 純粋なデータ構造のみ、ビジネスロジック禁止
- **例**: テキストボックスの座標・フォント、背景画像のハンドル

## テスト方針

### 単体テスト
```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_relationship_modification() {
        let mut system = RelationshipSystem::new();
        system.modify_relationship("souma", "yuzuki", 25);
        assert_eq!(system.get_relationship("souma", "yuzuki"), 25);
        assert_eq!(system.get_relationship_level("souma", "yuzuki"), RelationshipLevel::Normal);
    }

    #[test]
    fn test_scenario_parsing() {
        let markdown = "**ソウマ**: テストメッセージ";
        let result = ScenarioService::parse_markdown_content(markdown, "test");
        assert!(result.is_ok());
        let scenario = result.unwrap();
        assert_eq!(scenario.blocks.len(), 1);
    }
}
```

### 統合テスト
```rust
// tests/integration_test.rs
use negaboku_bevy::application::ScenarioService;

#[test]
fn test_scenario_file_loading() {
    let result = ScenarioService::parse_markdown_file("assets/scenarios/test_scene01.md");
    assert!(result.is_ok());
}
```

## Claude Code との協働開発ルール

### 1. タスク分割原則
- **単一責任**: 1つのタスクは1つのシステムまたは1つの層に集中
- **段階的実装**: 最小動作版 → 機能拡張 → 最適化の順序で進行
- **テスト駆動**: 新機能追加前に必ずテストケースを作成

### 2. コード生成指針
```rust
// ❌ 避けるべき: 複数の責務を持つ巨大な関数
fn handle_everything(commands: &mut Commands, /* 10+ parameters */) {
    // UI更新 + ビジネスロジック + ファイルI/O が混在
}

// ✅ 推奨: 責務を分離した小さな関数
fn spawn_dialogue_text(commands: &mut Commands, text: &str) {
    // UI生成のみに集中
}

fn calculate_relationship_effect(old_value: i32, delta: i32) -> i32 {
    // 計算ロジックのみに集中
}
```

### 3. エラーハンドリング戦略
```rust
// ✅ カスタムエラー型の定義
#[derive(Debug)]
pub enum ScenarioError {
    FileNotFound(String),
    ParseError(String),
    InvalidCommand(String),
}

// ✅ Result型によるエラー伝播
pub fn load_scenario(path: &str) -> Result<ScenarioData, ScenarioError> {
    let content = std::fs::read_to_string(path)
        .map_err(|_| ScenarioError::FileNotFound(path.to_string()))?;

    parse_markdown_content(&content)
        .map_err(|e| ScenarioError::ParseError(e.to_string()))
}
```

### 4. パフォーマンス考慮事項
- **メモリ効率**: 不要なクローンを避け、borrowing を活用
- **並行処理**: Bevyの並列システム実行を考慮した設計
- **アセット管理**: 画像・音声ファイルの遅延ロードとキャッシュ戦略

## 開発フロー

### Phase 1: ドメイン設計
1. ビジネスルールの抽出と構造体定義
2. ドメインモデルの単体テスト作成
3. インターフェース定義（trait）

### Phase 2: アプリケーション層実装
1. ユースケースの実装
2. ドメイン層との結合テスト
3. エラーハンドリングの実装

### Phase 3: ECS統合
1. BevyのComponent/Resource定義
2. System実装とイベントハンドリング
3. パフォーマンステスト

### Phase 4: UI/UX実装
1. レンダリング機能の実装
2. インタラクション処理
3. エフェクト・演出システム

## トラブルシューティング

### よくあるコンパイルエラー
1. **borrowed value does not live long enough**
   - 解決策: ライフタイムパラメータの明示的指定

2. **cannot borrow as mutable**
   - 解決策: `RefCell`の使用または設計の見直し

3. **trait bound not satisfied**
   - 解決策: 必要なtraitのderiveまたは手動実装

### Bevy固有の問題
1. **SystemParam conflicts**
   - 解決策: システム実行順序の調整（`.before()`, `.after()`）

2. **Resource not found**
   - 解決策: `insert_resource()`による初期化の確認

## まとめ
このガイドラインに従うことで、型安全性・保守性・テスト可能性を確保したRust + Bevy実装を、Claude Codeとの協働で効率的に開発できます。

**重要**: 実装時は常に「データ駆動設計」と「責務分離」の原則を念頭に置き、ビジネスロジックをUI/レンダリングから独立させることを最優先とします。
