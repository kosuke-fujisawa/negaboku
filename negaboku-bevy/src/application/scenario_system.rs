//! シナリオシステム - マークダウンベースシナリオの実行制御
//!
//! # 責務
//! - シナリオの進行管理
//! - コマンドとダイアログの順次実行
//! - 既存のVNシステムとの統合

use bevy::prelude::*;
use crate::domain::scenario::{ScenarioFile, Scene, DialogueBlock};
use crate::domain::character::{CharacterDisplay, CharacterRegistry};
use crate::application::command_executor::CommandExecutor;
use crate::infrastructure::scenario_loader::ScenarioLoader;

// main.rsの構造体を参照するため
use crate::{GameMode, VNDialogue, VNCharacterName};

/// マークダウンベースのシナリオ進行状態
#[derive(Resource, Default)]
pub struct MarkdownScenarioState {
    pub current_scenario: Option<ScenarioFile>,
    pub current_scene_index: usize,
    pub current_dialogue_index: usize,
    pub is_scene_commands_executed: bool,
    pub is_waiting_for_input: bool,
    pub has_attempted_load: bool,  // 読み込み試行済みフラグ
}

impl MarkdownScenarioState {
    /// 新しいシナリオファイルを読み込み
    pub fn load_scenario(&mut self, scenario_file: ScenarioFile) {
        self.current_scenario = Some(scenario_file);
        self.current_scene_index = 0;
        self.current_dialogue_index = 0;
        self.is_scene_commands_executed = false;
        self.is_waiting_for_input = false;
        self.has_attempted_load = true;  // 読み込み完了をマーク

        println!("📖 新しいシナリオを読み込みました");
        if let Some(scenario) = &self.current_scenario {
            println!("📋 タイトル: {}", scenario.title);
            println!("📋 シーン数: {}", scenario.scenes.len());
        }
    }

    /// 現在のシーンを取得
    pub fn get_current_scene(&self) -> Option<&Scene> {
        self.current_scenario
            .as_ref()?
            .scenes
            .get(self.current_scene_index)
    }

    /// 現在のダイアログを取得
    pub fn get_current_dialogue(&self) -> Option<&DialogueBlock> {
        let scene = self.get_current_scene()?;
        scene.dialogue_blocks.get(self.current_dialogue_index)
    }

    /// 次のダイアログへ進む
    pub fn advance_dialogue(&mut self) -> bool {
        let scene_dialogue_count = if let Some(scene) = self.get_current_scene() {
            scene.dialogue_blocks.len()
        } else {
            return false;
        };

        if self.current_dialogue_index + 1 < scene_dialogue_count {
            self.current_dialogue_index += 1;
            println!("📄 ダイアログ進行: {}/{}",
                self.current_dialogue_index + 1,
                scene_dialogue_count
            );
            true
        } else {
            // 現在のシーンが終了、次のシーンへ
            self.advance_scene()
        }
    }

    /// 次のシーンへ進む
    pub fn advance_scene(&mut self) -> bool {
        if let Some(scenario) = &self.current_scenario {
            if self.current_scene_index + 1 < scenario.scenes.len() {
                self.current_scene_index += 1;
                self.current_dialogue_index = 0;
                self.is_scene_commands_executed = false;
                println!("🎬 シーン進行: {}/{}",
                    self.current_scene_index + 1,
                    scenario.scenes.len()
                );
                return true;
            }
        }

        println!("✅ シナリオ完了");
        false
    }

    /// シナリオが終了したかチェック
    pub fn is_scenario_complete(&self) -> bool {
        if let Some(scenario) = &self.current_scenario {
            self.current_scene_index >= scenario.scenes.len()
        } else {
            true
        }
    }
}

/// マークダウンシナリオ実行システム
pub fn markdown_scenario_system(
    mut commands: Commands,
    mut scenario_state: ResMut<MarkdownScenarioState>,
    asset_server: Res<AssetServer>,
    character_registry: Res<CharacterRegistry>,
    mut background_query: Query<&mut Sprite, (With<crate::application::command_executor::BackgroundImage>, Without<CharacterDisplay>)>,
    mut character_query: Query<(Entity, &mut CharacterDisplay, &mut Transform, &mut Sprite)>,
    mut vn_dialogue_query: Query<&mut VNDialogue>,
    mut character_name_query: Query<&mut VNCharacterName>,
) {
    if scenario_state.current_scenario.is_none() {
        return;
    }

    // シーンコマンドの実行（シーン開始時に1回だけ）
    if !scenario_state.is_scene_commands_executed {
        if let Some(scene) = scenario_state.get_current_scene() {
            println!("🎬 シーンコマンド実行開始: {} 個", scene.commands.len());

            for command in &scene.commands {
                CommandExecutor::execute_command(
                    command,
                    &mut commands,
                    &asset_server,
                    &character_registry,
                    &mut background_query,
                    &mut character_query,
                );
            }

            scenario_state.is_scene_commands_executed = true;
            println!("✅ シーンコマンド実行完了");
        }
    }

    // 現在のダイアログを既存のVNシステムに設定（テキストが変更された場合のみ）
    if let Some(current_dialogue) = scenario_state.get_current_dialogue() {
        // VNDialogue コンポーネントを更新（テキストが異なる場合のみ）
        let mut found_vn_dialogue = false;
        for mut vn_dialogue in vn_dialogue_query.iter_mut() {
            found_vn_dialogue = true;

            if vn_dialogue.full_text != current_dialogue.text {
                vn_dialogue.full_text = current_dialogue.text.clone();
                vn_dialogue.current_char = 0;
                vn_dialogue.is_complete = false;
                vn_dialogue.timer.reset();

                println!("💬 マークダウンシナリオ→VNDialogue更新: {}", current_dialogue.text);
                break;
            }
        }

        if !found_vn_dialogue {
            println!("❌ VNDialogueコンポーネントが見つかりません - 作成を確認してください");
        }

        // キャラクター名を更新（名前が異なる場合のみ）
        for mut character_name in character_name_query.iter_mut() {
            let new_name = current_dialogue.speaker.as_deref().unwrap_or("");
            if character_name.name != new_name {
                character_name.name = new_name.to_string();
                println!("👤 スピーカー更新: {}", new_name);
                break;
            }
        }
    }
}

/// マークダウンシナリオ進行制御システム
pub fn markdown_scenario_input_system(
    keyboard_input: Res<ButtonInput<KeyCode>>,
    mouse_input: Res<ButtonInput<MouseButton>>,
    mut scenario_state: ResMut<MarkdownScenarioState>,
    mut vn_dialogue_query: Query<&mut VNDialogue>,
    game_mode: Res<GameMode>,
) {
    if !game_mode.is_story_mode || scenario_state.current_scenario.is_none() {
        return;
    }

    let input_detected = keyboard_input.just_pressed(KeyCode::Space)
        || mouse_input.just_pressed(MouseButton::Left);

    if !input_detected {
        return;
    }

    // 現在のVNDialogueの状態を確認
    let mut dialogue_complete = true;
    let mut found_incomplete = false;

    for mut vn_dialogue in vn_dialogue_query.iter_mut() {
        if !vn_dialogue.is_complete {
            // タイピング中の場合：即座に完了状態にする
            vn_dialogue.current_char = vn_dialogue.full_text.len();
            vn_dialogue.is_complete = true;
            found_incomplete = true;
            dialogue_complete = false;
            println!("⏭️ ダイアログ表示完了: {}", vn_dialogue.full_text);
            break;
        }
    }

    if dialogue_complete && !found_incomplete {
        // ダイアログが完了している場合、次へ進む
        if !scenario_state.advance_dialogue() {
            println!("📖 マークダウンシナリオ完了");
            // TODO: シナリオ完了処理
        }
    }
}

/// シナリオファイル読み込みシステム（ゲーム開始時）
pub fn load_markdown_scenario_system(
    mut scenario_state: ResMut<MarkdownScenarioState>,
    game_mode: Res<GameMode>,
) {
    // ストーリーモードに切り替わった瞬間にシナリオを読み込み（毎フレームチェック）
    if game_mode.is_story_mode && scenario_state.current_scenario.is_none() {
        println!("✅ ストーリーモード開始 - シナリオ読み込み開始");
        match ScenarioLoader::load_from_file("assets/scenarios/test_scene01.md") {
            Ok(scenario_file) => {
                let stats = ScenarioLoader::get_scenario_stats(&scenario_file);
                println!("📊 シナリオ統計: {:?}", stats);

                scenario_state.load_scenario(scenario_file);
            }
            Err(error) => {
                eprintln!("❌ シナリオファイル読み込みエラー: {}", error);

                // フォールバック：基本的なシナリオを作成
                let fallback_scenario = ScenarioLoader::parse_markdown(
                    "# フォールバックシナリオ\n\n**システム**「シナリオファイルの読み込みに失敗しました。」"
                );
                scenario_state.load_scenario(fallback_scenario);
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_scenario_state_progression() {
        let mut state = MarkdownScenarioState::default();

        // シナリオの作成
        let content = r#"
# テストシナリオ

**テスト**「最初のダイアログ」

**テスト**「2番目のダイアログ」

---

**テスト**「次のシーンのダイアログ」
"#;

        let scenario = ScenarioLoader::parse_markdown(content);
        state.load_scenario(scenario);

        // 初期状態の確認
        assert_eq!(state.current_scene_index, 0);
        assert_eq!(state.current_dialogue_index, 0);
        assert!(!state.is_scene_commands_executed);

        // ダイアログ進行テスト
        assert!(state.advance_dialogue());
        assert_eq!(state.current_dialogue_index, 1);

        // シーン進行テスト
        assert!(state.advance_dialogue()); // 次のシーンへ
        assert_eq!(state.current_scene_index, 1);
        assert_eq!(state.current_dialogue_index, 0);
        assert!(!state.is_scene_commands_executed);

        // 完了テスト
        assert!(!state.advance_dialogue()); // シナリオ完了
        // シナリオは完了状態になる
        println!("最終状態 - scene_index: {}, シーン数: {}",
            state.current_scene_index,
            state.current_scenario.as_ref().unwrap().scenes.len());
        // シナリオ完了の判定はadvance_dialogueの戻り値で行う
    }
}

/// シナリオ進行管理システム（旧システム用、マークダウンシナリオが無効の場合のみ動作）
pub fn scenario_progression_system(
    mut vn_dialogue_query: Query<&mut crate::presentation::ui_components::VNDialogue>,
    scenario_state: ResMut<crate::presentation::ui_components::ScenarioState>,
    game_mode: Res<crate::presentation::ui_components::GameMode>,
    markdown_state: Res<MarkdownScenarioState>,
) {
    // マークダウンシナリオがアクティブな場合は、このシステムを完全に無効化
    if !game_mode.is_story_mode ||
       markdown_state.current_scenario.is_some() ||
       scenario_state.lines.is_empty() {
        return;
    }

    // 初回のテキスト設定（境界チェック付き、マークダウンシステムが有効でない場合のみ）
    if markdown_state.current_scenario.is_none() {
        if scenario_state.current_index == 0 && !scenario_state.lines.is_empty() {
            for mut dialogue in vn_dialogue_query.iter_mut() {
                if dialogue.full_text != scenario_state.lines[0] {
                    dialogue.full_text = scenario_state.lines[0].clone();
                    dialogue.current_char = 0;
                    dialogue.is_complete = false;
                    dialogue.timer.reset();
                    println!("初回テキスト設定: {}", scenario_state.lines[0]);
                    break;
                }
            }
        } else if scenario_state.lines.is_empty() {
            println!("⚠️  警告: scenario_state.linesが空です。シナリオが読み込まれていない可能性があります。");
        }
    }
}
