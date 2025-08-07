# LLM協働開発ガイドライン

## 概要

「願い石と僕たちの絆」プロジェクトにおけるLLM（Large Language Model）協働開発のためのガイドラインです。Claude Code、GitHub Copilot、その他のLLMツールとの効率的な開発を目指します。

## 基本原則

### 1. コードが唯一の真実（Code as Single Source of Truth）
- すべての仕様・ロジック・設計はコードで表現
- ドキュメントと実装の不整合を回避
- LLMが常に最新のコード状態を参照可能

### 2. 自動化優先（Automation First）
- 手作業の代わりに自動化スクリプト
- LLMが一貫したルールでコード生成
- CI/CD・pre-commitフックによる品質保証

### 3. 段階的実装（Progressive Implementation）
- MVP（Minimal Viable Product）から開始
- 機能を段階的に拡張
- 各段階でのテスト・検証を徹底

## 命名規則

### Rustコード命名

#### Module（モジュール）
```rust
// ✅ 推奨: snake_case、単語区切り
mod domain_logic;
mod presentation_layer;
mod scenario_system;

// ❌ 避ける: camelCase、省略形
mod domainLogic;
mod presenLayer;
```

#### Struct・Enum（構造体・列挙型）
```rust
// ✅ 推奨: PascalCase、明確な責務表現
pub struct MarkdownScenarioState;
pub struct CharacterDisplayPosition;
pub enum RelationshipLevel;

// ❌ 避ける: 責務不明・省略形
pub struct Data;
pub struct MdState;
```

#### Function・Method（関数・メソッド）
```rust
// ✅ 推奨: snake_case、動作を明確に表現
fn load_markdown_scenario();
fn advance_dialogue_to_next();
fn calculate_relationship_value();

// ❌ 避ける: 曖昧・動作不明
fn process();
fn handle();
```

#### Component・Resource（ECSコンポーネント・リソース）
```rust
// ✅ 推奨: 責務別プレフィックス + 具体的名称
#[derive(Component)]
struct VNDialogueText;           // ビジュアルノベル関連

#[derive(Component)]
struct CharacterDisplayState;    // キャラクター関連

#[derive(Resource)]
struct GameProgressState;        // ゲーム状態

// ❌ 避ける: 汎用的・曖昧な名称
struct Text;
struct State;
```

### ファイル・フォルダ命名
```
// ✅ 推奨: 責務明確・階層構造
src/
  domain/
    relationship.rs              # 関係値ドメイン
    character.rs                # キャラクタードメイン
  application/
    scenario_system.rs          # シナリオ実行システム
  infrastructure/
    scenario_loader.rs          # ファイルI/O

// ❌ 避ける: 曖昧・階層不明
src/
  utils.rs
  helpers.rs
  misc/
    stuff.rs
```

## 責務分割原則

### Layer別責務（DDD + Clean Architecture）

#### Domain層
**責務**: ビジネスロジックのみ
```rust
// ✅ Domain層の正しい実装
impl Relationship {
    pub fn modify_value(&mut self, delta: i32) {
        self.value = (self.value + delta).clamp(-100, 100);
    }

    pub fn current_level(&self) -> RelationshipLevel {
        match self.value {
            -100..=-1 => RelationshipLevel::Conflict,
            0..=49 => RelationshipLevel::Normal,
            50..=100 => RelationshipLevel::Intimate,
        }
    }
}

// ❌ Domain層でのNG実装（UI依存）
impl Relationship {
    pub fn display_on_screen(&self, commands: &mut Commands) {
        // UIロジックはDomainに含めない
    }
}
```

#### Application層
**責務**: ドメインとECSの統合
```rust
// ✅ Application層の正しい実装
pub fn relationship_update_system(
    mut relationship_query: Query<&mut RelationshipComponent>,
    events: EventReader<RelationshipChangeEvent>,
) {
    // ドメインロジックとECSシステムを統合
    for event in events.iter() {
        // Domainの純粋関数を呼び出し
        let new_value = calculate_relationship_change(event);
        // ECSコンポーネント更新
    }
}
```

#### Infrastructure層
**責務**: 外部システム連携
```rust
// ✅ Infrastructure層の正しい実装
impl ScenarioLoader {
    pub fn load_from_file(path: &Path) -> Result<ScenarioFile, IoError> {
        // ファイル読み込み・パース処理のみ
        let content = fs::read_to_string(path)?;
        Ok(Self::parse_markdown(&content))
    }
}
```

### ECSコンポーネント責務分離

#### Data-Onlyコンポーネント
```rust
// ✅ 正しいComponent設計（データのみ）
#[derive(Component)]
pub struct VNDialogue {
    pub full_text: String,
    pub current_char: usize,
    pub is_complete: bool,
    pub timer: Timer,
}

// ❌ NG Component設計（ロジック含む）
#[derive(Component)]
pub struct VNDialogue {
    pub text: String,

    // これはSystemで処理すべき
    pub fn update(&mut self, delta_time: f32) {
        // ロジックはComponentに含めない
    }
}
```

#### System責務分離
```rust
// ✅ 単一責務System
pub fn text_typing_system(
    mut query: Query<(&mut VNDialogue, &mut Text2d)>,
    time: Res<Time>,
) {
    // テキストタイピング処理のみ
    for (mut dialogue, mut text) in query.iter_mut() {
        if !dialogue.is_complete {
            // タイピング進行処理
        }
    }
}

// ✅ 別の単一責務System
pub fn dialogue_completion_system(
    dialogue_query: Query<&VNDialogue, Changed<VNDialogue>>,
    mut log: ResMut<DialogueLog>,
) {
    // ダイアログ完了時のログ追加のみ
}
```

## テスト戦略

### TDD（Test-Driven Development）推奨フロー

#### 1. Red - 失敗テストを先に作成
```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_relationship_level_calculation() {
        let mut relationship = Relationship::new("souma", "yuzuki");

        // まだ実装されていないメソッドをテスト
        relationship.modify_value(60);
        assert_eq!(relationship.current_level(), RelationshipLevel::Intimate);

        relationship.modify_value(-80);
        assert_eq!(relationship.current_level(), RelationshipLevel::Conflict);
    }
}
```

#### 2. Green - テストを通す最小実装
```rust
impl Relationship {
    pub fn modify_value(&mut self, delta: i32) {
        self.value += delta; // まずは最小実装
    }

    pub fn current_level(&self) -> RelationshipLevel {
        if self.value >= 50 {
            RelationshipLevel::Intimate
        } else if self.value < 0 {
            RelationshipLevel::Conflict
        } else {
            RelationshipLevel::Normal
        }
    }
}
```

#### 3. Refactor - テスト通過後にリファクタリング
```rust
impl Relationship {
    pub fn modify_value(&mut self, delta: i32) {
        // 範囲制限を追加
        self.value = (self.value + delta).clamp(-100, 100);
    }

    pub fn current_level(&self) -> RelationshipLevel {
        // マッチ式で可読性向上
        match self.value {
            -100..=-1 => RelationshipLevel::Conflict,
            0..=49 => RelationshipLevel::Normal,
            50..=100 => RelationshipLevel::Intimate,
        }
    }
}
```

### テスト命名・構成

#### テスト関数命名
```rust
// ✅ 推奨: test_対象_条件_期待結果
#[test]
fn test_relationship_modify_value_positive_increases_correctly() {}

#[test]
fn test_relationship_modify_value_exceeds_limit_clamps_to_max() {}

#[test]
fn test_scenario_parser_invalid_command_returns_error() {}

// ❌ 避ける: 曖昧・汎用的
#[test]
fn test_basic_functionality() {}

#[test]
fn test_edge_cases() {}
```

#### テスト分類
```rust
// Unit Tests（単体テスト）
mod unit_tests {
    // 個々のDomain関数テスト
}

// Integration Tests（統合テスト）
mod integration_tests {
    // SystemとComponentの連携テスト
}

// E2E Tests（エンドツーエンドテスト）
mod e2e_tests {
    // シナリオ全体の動作テスト
}
```

## LLM向けコメント・ドキュメント

### コメントガイドライン

#### 1. Intent Comment（意図説明）
```rust
// ✅ なぜその実装なのかを説明
pub fn advance_dialogue(&mut self) -> bool {
    // シーンの最後のダイアログに到達した場合、次のシーンに自動進行
    // これはVN標準的なUX動作に従う
    if self.current_dialogue_index + 1 >= self.get_current_scene()?.dialogue_blocks.len() {
        return self.advance_scene();
    }
    // ...
}

// ❌ what（何を）の説明は不要
pub fn advance_dialogue(&mut self) -> bool {
    // dialogue_indexを1増やす
    self.current_dialogue_index += 1;
}
```

#### 2. Context Comment（文脈説明）
```rust
// ✅ LLMがコードを理解しやすい文脈
/// マークダウンシナリオの実行制御システム
///
/// # 責務
/// - シナリオコマンドの順次実行（背景変更、キャラ表示等）
/// - ダイアログテキストのVNシステムへの統合
/// - 既存UIシステムとの互換性維持
///
/// # 使用例
/// ```
/// let mut state = MarkdownScenarioState::default();
/// state.load_scenario(scenario_file);
/// ```
pub struct MarkdownScenarioState {
    // ...
}
```

#### 3. Architecture Comment（アーキテクチャ説明）
```rust
/// ECS統合における注意点：
/// - このComponentは純粋なデータ構造（ECS原則）
/// - ロジックはtext_typing_systemで処理
/// - UIとの同期はui_sync_systemで管理
#[derive(Component)]
pub struct VNDialogue {
    pub full_text: String,
    // ...
}
```

### Markdown Docコメント
```rust
/// ## 実装例
///
/// ```rust
/// // Domain層の純粋関数
/// let relationship = Relationship::new("souma", "yuzuki");
///
/// // Application層でECS統合
/// fn relationship_system(query: Query<&mut RelationshipComponent>) {
///     // ...
/// }
/// ```
///
/// ## アーキテクチャ注意点
///
/// - **Domain層**: 外部依存なし、pure Rust
/// - **Application層**: Domainロジック + ECSシステム統合
/// - **Infrastructure層**: ファイルI/O・外部API連携
```

## プロジェクト管理・コラボレーション

### Issue・PR作成ガイドライン

#### Issue Template
```markdown
## 概要
[機能/バグの概要を1-2文で]

## 責務範囲
- [ ] Domain層の変更
- [ ] Application層の変更
- [ ] Infrastructure層の変更
- [ ] Presentation層の変更

## 実装方針
[DDDとECSの原則に従った実装計画]

## テスト計画
- [ ] 単体テスト（Domain関数）
- [ ] 統合テスト（ECSシステム）
- [ ] E2Eテスト（ユーザーシナリオ）

## 影響範囲
[既存機能への影響・互換性]
```

#### Commit Message Rules
```bash
# ✅ 推奨形式: type(scope): description
feat(domain): implement relationship calculation system
fix(application): resolve scenario loading race condition
refactor(presentation): extract UI components to separate module
test(infrastructure): add markdown parser unit tests

# ❌ 避ける形式
update files
bug fix
changes
```

### Code Review Checklist

#### Architecture Review
- [ ] 適切なLayerに実装されているか
- [ ] Single Responsibility原則に従っているか
- [ ] Domain層に外部依存が含まれていないか
- [ ] ECSコンポーネントがdata-onlyになっているか

#### Code Quality Review
- [ ] 命名規則に従っているか
- [ ] テストが十分に書かれているか
- [ ] パフォーマンスに問題がないか
- [ ] ドキュメント・コメントが適切か

## LLMプロンプト・テンプレート

### 新機能実装時
```
このプロジェクトのアーキテクチャ（DDD + Clean Architecture + ECS）に従って、
[機能名]を実装してください。

要件：
- Domain層に純粋なビジネスロジック
- Application層でECSシステム統合
- 責務分離の原則を遵守
- TDDでテストファースト実装

ファイル構成：
- src/domain/[機能名].rs: ドメインロジック
- src/application/[機能名]_system.rs: ECSシステム
- tests/[機能名]_test.rs: テストケース
```

### バグ修正時
```
以下のバグを、アーキテクチャ原則を維持しながら修正してください：

バグ内容: [バグの詳細]

修正方針：
1. 根本原因の特定（責務分離の問題？）
2. 適切なLayerでの修正
3. 既存テストの確認・追加
4. 回帰テスト実行
```

### リファクタリング時
```
以下のコードを、現在のアーキテクチャに適合するようリファクタリングしてください：

[対象コード]

リファクタリング目標：
- Single Responsibility原則の適用
- 適切なLayer配置
- ECS原則の遵守
- テスト保証の維持
```

---

このガイドラインにより、LLMとの協働開発において**一貫性・保守性・品質**を確保し、効率的な「願い石と僕たちの絆」の開発を実現します。
