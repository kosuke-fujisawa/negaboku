# ECS設計原則

## 概要

Bevy の**Entity-Component-System（ECS）**パターンに基づく設計原則とガイドラインです。

## ECS三要素の責務

### Entity（エンティティ）
**定義**: 純粋な識別子、データを一切持たない

```rust
// ✅ 正しい使用例
let entity = commands.spawn((
    DialogueText::new("こんにちは".to_string()),
    VNCharacterName { name: "ソウマ".to_string() },
)).id();

// ❌ 避けるべき: Entityに直接データを含める
// Entity自体はIDのみ
```

**原則**:
- Entity は単なる ID
- データの組み合わせを識別
- 複数の Component を組み合わせて意味を表現

### Component（コンポーネント）
**定義**: 純粋なデータ構造、ロジックを一切含まない

```rust
// ✅ 正しいComponent設計
#[derive(Component)]
struct VNDialogue {
    full_text: String,
    current_char: usize,
    timer: Timer,
    is_complete: bool,
}

// ❌ 避けるべき: メソッドを含むComponent
#[derive(Component)]
struct BadComponent {
    data: String,
    // fn update(&mut self) -> これはSystemで処理する
}
```

**設計原則**:
- **Single Responsibility**: 1 つの責務のみ
- **Data Only**: ロジックを含めない
- **Serializable**: 将来的なセーブ/ロード対応
- **Composable**: 他の Component と組み合わせ可能

### System（システム）
**定義**: Component や Resource に対する処理ロジック

```rust
// ✅ 正しいSystem設計
fn text_typing_system(
    mut query: Query<(&mut VNDialogue, &mut Text2d)>,
    time: Res<Time>,
) {
    for (mut dialogue, mut text) in query.iter_mut() {
        if !dialogue.is_complete {
            dialogue.timer.tick(time.delta());
            // タイピング処理...
        }
    }
}
```

**設計原則**:
- **Single Purpose**: 1 システム 1 機能
- **Pure Function**: 副作用を最小化
- **Query Driven**: 必要な Component のみクエリ
- **Resource Access**: グローバル状態へのアクセス

### Resource（リソース）
**定義**: グローバル状態管理

```rust
// ✅ 正しいResource設計
#[derive(Resource)]
struct GameMode {
    is_story_mode: bool,
    current_screen: GameScreen,
}

#[derive(Resource, Default)]
struct DialogueLog {
    entries: Vec<DialogueEntry>,
    is_visible: bool,
}
```

**原則**:
- **Global State**: アプリケーション全体の状態
- **Unique**: 1 つのタイプにつき 1 つのインスタンス
- **Managed**: System で Read/Write 制御

## アーキテクチャとECSの統合

### Domain層とECS
```rust
// Domain定義（ECS独立）
pub struct Relationship {
    pub character_a: String,
    pub character_b: String,
    pub value: i32,
}

// Application層でComponent化
#[derive(Component)]
pub struct RelationshipComponent(pub Relationship);
```

### Component命名規則

#### 1. 責務別プレフィックス
- **VN**: ビジュアルノベル関連 (`VNDialogue`, `VNTextBox`)
- **UI**: ユーザーインターフェース (`UIButton`, `UIPanel`)
- **Game**: ゲーム状態 (`GameState`, `GameMode`)
- **Character**: キャラクター関連 (`CharacterDisplay`)

#### 2. 状態表現
- **Controller**: 制御ロジック (`BackgroundController`)
- **Display**: 表示状態 (`CharacterDisplay`)
- **State**: 状態管理 (`ScenarioState`)

#### 3. UI要素
- **Element**: 画面要素マーカー (`TitleScreenElement`)
- **Button**: インタラクティブ要素 (`MenuButton`)
- **Container**: 複数要素のグループ (`LogScrollContainer`)

## System設計パターン

### 1. Input Processing Pattern
```rust
fn input_system(
    keyboard_input: Res<ButtonInput<KeyCode>>,
    mut game_state: ResMut<GameMode>,
) {
    if keyboard_input.just_pressed(KeyCode::Space) {
        // 入力処理のみ、状態変更は最小限
    }
}
```

### 2. State Update Pattern
```rust
fn dialogue_update_system(
    mut query: Query<&mut VNDialogue>,
    time: Res<Time>,
) {
    for mut dialogue in query.iter_mut() {
        // 状態更新ロジック
    }
}
```

### 3. UI Sync Pattern
```rust
fn ui_sync_system(
    dialogue_query: Query<&VNDialogue>,
    mut text_query: Query<&mut Text2d>,
) {
    // Component間の同期処理
}
```

## Query最適化原則

### 1. Minimal Query
```rust
// ✅ 必要なComponentのみクエリ
fn system(query: Query<&Transform, With<Player>>) {}

// ❌ 不要なComponentを含む
fn system(query: Query<(&Transform, &Sprite, &Handle<Image>), With<Player>>) {}
```

### 2. Filter活用
```rust
// ✅ Filterで対象を限定
fn system(
    query: Query<&mut Health, (With<Player>, Without<Enemy>)>
) {}
```

### 3. Change Detection
```rust
// ✅ 変更されたもののみ処理
fn system(
    query: Query<&Transform, Changed<Transform>>
) {}
```

## Performance Guidelines

### 1. System実行順序
```rust
// 依存関係を明確化
.add_systems(Update, (
    input_system,           // 1. 入力処理
    game_logic_system,      // 2. ゲームロジック
    ui_update_system,       // 3. UI更新
).chain())
```

### 2. Resource競合回避
```rust
// 同じResourceに同時アクセスしない
fn system_a(mut resource: ResMut<GameState>) {}
fn system_b(resource: Res<GameState>) {}  // 読み込み専用なら可能
```

## 実装チェックリスト

### Component作成時
- [ ] データのみ定義（メソッドなし）
- [ ] `#[derive(Component)]`付与
- [ ] 単一責務確認
- [ ] 適切な命名規則

### System作成時
- [ ] 1 つの機能のみ処理
- [ ] 必要最小限の Query
- [ ] 副作用を最小化
- [ ] エラーハンドリング

### Resource作成時
- [ ] グローバル状態として適切
- [ ] `#[derive(Resource)]`付与
- [ ] Default トレイト実装
- [ ] ドキュメント記載

この ECS 設計原則により、**拡張性・保守性・パフォーマンス**を兼ね備えたアーキテクチャを実現します。
