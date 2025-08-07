//! ダイアログUI - 会話・ストーリー表示システム
//!
//! テキスト表示、選択肢、キャラクター表示など
//! ビジュアルノベル部分のUI要素を管理

use bevy::prelude::*;
use crate::presentation::ui_components::*;
use crate::application::scenario_system::MarkdownScenarioState;

/// ダイアログボックスのコンポーネント
#[derive(Component, Debug)]
pub struct DialogueBox {
    pub width: f32,
    pub height: f32,
    pub background_color: Color,
    pub border_color: Color,
    pub is_visible: bool,
}

/// 話者名表示のコンポーネント
#[derive(Component, Debug)]
pub struct SpeakerNameBox {
    pub speaker_name: String,
    pub background_color: Color,
}

/// 選択肢ボタンのコンポーネント
#[derive(Component, Debug)]
pub struct ChoiceButton {
    pub choice_index: usize,
    pub choice_text: String,
    pub is_selected: bool,
}

/// キャラクター立ち絵のコンポーネント
#[derive(Component, Debug)]
pub struct CharacterSprite {
    pub character_name: String,
    pub expression: String,
    pub position: CharacterSpritePosition,
    pub scale: f32,
    pub alpha: f32,
}

/// キャラクター立ち絵の位置
#[derive(Debug, Clone, PartialEq)]
pub enum CharacterSpritePosition {
    Left,
    Center,
    Right,
    Custom(f32, f32),
}

impl DialogueBox {
    pub fn new(width: f32, height: f32) -> Self {
        Self {
            width,
            height,
            background_color: Color::srgba(0.0, 0.0, 0.0, 0.8),
            border_color: Color::srgba(1.0, 1.0, 1.0, 0.9),
            is_visible: true,
        }
    }

    /// ダイアログボックスを画面下部に配置
    pub fn spawn_dialogue_box(commands: &mut Commands, assets: &GameAssets) -> Entity {
        let dialogue_box = DialogueBox::new(1800.0, 200.0);

        commands.spawn((
            // 背景
            Sprite::from_color(dialogue_box.background_color, Vec2::new(dialogue_box.width, dialogue_box.height)),
            Transform::from_xyz(0.0, -400.0, 10.0), // 画面下部
            dialogue_box,
            VisualNovelElement,
        )).id()
    }
}

impl SpeakerNameBox {
    pub fn new(speaker_name: String) -> Self {
        Self {
            speaker_name,
            background_color: Color::srgba(0.2, 0.4, 0.8, 0.9),
        }
    }

    /// 話者名ボックスを spawn
    pub fn spawn_speaker_box(commands: &mut Commands, assets: &GameAssets, speaker_name: &str) -> Entity {
        let speaker_box = SpeakerNameBox::new(speaker_name.to_string());

        let parent_entity = commands.spawn((
            Sprite::from_color(speaker_box.background_color, Vec2::new(200.0, 50.0)),
            Transform::from_xyz(-750.0, -280.0, 15.0), // ダイアログボックス左上
            speaker_box,
            VisualNovelElement,
        )).id();

        // 話者名テキスト
        let text_entity = commands.spawn((
            Text2d::new(speaker_name),
            TextFont {
                font: assets.main_font.clone(),
                font_size: 18.0,
                ..default()
            },
            TextLayout::new_with_justify(JustifyText::Center),
            TextColor(Color::WHITE),
            Transform::from_xyz(0.0, 0.0, 1.0),
            VisualNovelElement,
        )).id();

        commands.entity(parent_entity).add_child(text_entity);
        parent_entity
    }
}

impl ChoiceButton {
    pub fn new(choice_index: usize, choice_text: String) -> Self {
        Self {
            choice_index,
            choice_text,
            is_selected: false,
        }
    }

    /// 選択肢ボタンの色を取得
    pub fn get_button_color(&self) -> Color {
        if self.is_selected {
            Color::srgba(0.9, 0.9, 0.3, 0.9) // 選択時は黄色
        } else {
            Color::srgba(0.3, 0.3, 0.7, 0.8) // 通常時は青
        }
    }

    /// 選択肢ボタンを spawn
    pub fn spawn_choice_buttons(
        commands: &mut Commands,
        assets: &GameAssets,
        choices: &[String]
    ) -> Vec<Entity> {
        let mut button_entities = Vec::new();

        for (index, choice_text) in choices.iter().enumerate() {
            let choice_button = ChoiceButton::new(index, choice_text.clone());
            let y_pos = 100.0 - (index as f32 * 60.0); // 選択肢間隔

            let button_entity = commands.spawn((
                Sprite::from_color(choice_button.get_button_color(), Vec2::new(600.0, 45.0)),
                Transform::from_xyz(0.0, y_pos, 12.0),
                choice_button,
                VisualNovelElement,
            )).id();

            // 選択肢テキスト
            let text_entity = commands.spawn((
                Text2d::new(&format!("{}. {}", index + 1, choice_text)),
                TextFont {
                    font: assets.main_font.clone(),
                    font_size: 16.0,
                    ..default()
                },
                TextLayout::new_with_justify(JustifyText::Center),
                TextColor(Color::WHITE),
                Transform::from_xyz(0.0, 0.0, 1.0),
                VisualNovelElement,
            )).id();

            commands.entity(button_entity).add_child(text_entity);
            button_entities.push(button_entity);
        }

        button_entities
    }
}

impl CharacterSprite {
    pub fn new(character_name: String, expression: String, position: CharacterSpritePosition) -> Self {
        Self {
            character_name,
            expression,
            position,
            scale: 1.0,
            alpha: 1.0,
        }
    }

    /// 位置から座標を取得
    pub fn get_world_position(&self) -> Vec3 {
        match &self.position {
            CharacterSpritePosition::Left => Vec3::new(-400.0, -100.0, 5.0),
            CharacterSpritePosition::Center => Vec3::new(0.0, -100.0, 5.0),
            CharacterSpritePosition::Right => Vec3::new(400.0, -100.0, 5.0),
            CharacterSpritePosition::Custom(x, y) => Vec3::new(*x, *y, 5.0),
        }
    }

    /// キャラクター立ち絵を spawn
    pub fn spawn_character_sprite(
        commands: &mut Commands,
        assets: &GameAssets,
        character_name: &str,
        expression: &str,
        position: CharacterSpritePosition,
    ) -> Entity {
        let character_sprite = CharacterSprite::new(
            character_name.to_string(),
            expression.to_string(),
            position
        );

        // キャラクター画像のハンドルを取得（仮実装）
        let character_handle = match character_name.to_lowercase().as_str() {
            "souma" => assets.character_souma.clone(),
            "yuzuki" => assets.character_souma.clone(), // TODO: 適切なハンドルに変更
            "retsuji" => assets.character_souma.clone(), // TODO: 適切なハンドルに変更
            "kai" => assets.character_souma.clone(), // TODO: 適切なハンドルに変更
            _ => assets.character_souma.clone(),
        };

        commands.spawn((
            Sprite::from_image(character_handle),
            Transform::from_translation(character_sprite.get_world_position())
                .with_scale(Vec3::splat(character_sprite.scale)),
            character_sprite,
            VisualNovelElement,
        )).id()
    }
}

/// ダイアログUI管理システム
pub fn dialogue_ui_system(
    mut commands: Commands,
    assets: Res<GameAssets>,
    markdown_state: Res<MarkdownScenarioState>,
    dialogue_query: Query<Entity, With<DialogueBox>>,
    speaker_query: Query<Entity, With<SpeakerNameBox>>,
    choice_query: Query<Entity, With<ChoiceButton>>,
    mut vn_dialogue_query: Query<&mut VNDialogue>,
    game_mode: Res<GameMode>,
) {
    // ストーリーモード以外では何もしない
    if !game_mode.is_story_mode {
        return;
    }

    // マークダウンシナリオが有効な場合の処理（簡略化版）
    if let Some(scenario) = &markdown_state.current_scenario {
        if let Some(current_scene) = scenario.scenes.get(markdown_state.current_scene_index) {
            // dialogue_blocksから現在のダイアログを取得
            if let Some(dialogue_block) = current_scene.dialogue_blocks.get(markdown_state.current_dialogue_index) {
                // 話者名ボックスの更新（仮実装）
                if speaker_query.is_empty() {
                    SpeakerNameBox::spawn_speaker_box(&mut commands, &assets, "Speaker");
                }

                // VNDialogue コンポーネントの更新（dialogue_blockから文字列を構築）
                for mut vn_dialogue in vn_dialogue_query.iter_mut() {
                    let dialogue_text = format!("{:?}", dialogue_block); // 仮実装
                    if vn_dialogue.full_text != dialogue_text {
                        vn_dialogue.full_text = dialogue_text;
                        vn_dialogue.current_char = 0;
                        vn_dialogue.is_complete = false;
                        vn_dialogue.timer.reset();
                    }
                }
            }

            // 選択肢の表示（簡略化 - 実際のchoicesフィールドがないため仮実装）
            // TODO: 実際のSceneからchoice情報を取得する実装に変更
        }
    }
}

/// 選択肢入力処理システム
pub fn choice_input_system(
    keyboard_input: Res<ButtonInput<KeyCode>>,
    choice_query: Query<Entity, With<ChoiceButton>>,
    mut markdown_state: ResMut<MarkdownScenarioState>,
    mut commands: Commands,
) {
    let choice_count = choice_query.iter().count();
    if choice_count == 0 {
        return;
    }

    // 数字キーでの直接選択
    for key_code in keyboard_input.get_just_pressed() {
        let choice_index = match key_code {
            KeyCode::Digit1 => Some(0),
            KeyCode::Digit2 => Some(1),
            KeyCode::Digit3 => Some(2),
            KeyCode::Digit4 => Some(3),
            KeyCode::Digit5 => Some(4),
            _ => None,
        };

        if let Some(index) = choice_index {
            if index < choice_count {
                // 選択肢を選んで処理（仮実装）
                info!("選択肢 {} を選択しました", index + 1);

                // 選択肢UIを削除
                for entity in choice_query.into_iter() {
                    commands.entity(entity).despawn_recursive();
                }

                break;
            }
        }
    }
}

/// キャラクター表示管理システム
pub fn character_display_system(
    mut character_query: Query<(&mut CharacterSprite, &mut Transform, &mut Sprite)>,
    markdown_state: Res<MarkdownScenarioState>,
) {
    if let Some(scenario) = &markdown_state.current_scenario {
        if let Some(current_scene) = scenario.scenes.get(markdown_state.current_scene_index) {
            // シーンコマンドからキャラクター表示指示を処理
            for command in &current_scene.commands {
                // キャラクター表示コマンドの処理（実装例）
                match command {
                    crate::domain::scenario::SceneCommand::CharacterShow { name, face, pos } => {
                        for (mut character_sprite, mut transform, mut sprite) in character_query.iter_mut() {
                            // キャラクター表示の更新ロジック
                            // TODO: コマンドに応じてキャラクターの位置、表情、透明度を更新
                            character_sprite.character_name = name.clone();
                            if let Some(expression) = face {
                                character_sprite.expression = expression.clone();
                            }
                        }
                    }
                    _ => {} // その他のコマンドは無視
                }
            }
        }
    }
}

/// ダイアログUI要素のクリーンアップシステム
pub fn cleanup_dialogue_ui_system(
    mut commands: Commands,
    vn_elements: Query<Entity, With<VisualNovelElement>>,
    game_mode: Res<GameMode>,
) {
    // ストーリーモードを離れた時にVN要素をクリーンアップ
    if !game_mode.is_story_mode {
        for entity in vn_elements.iter() {
            commands.entity(entity).despawn_recursive();
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn dialogue_box_creation() {
        let dialogue_box = DialogueBox::new(800.0, 200.0);
        assert_eq!(dialogue_box.width, 800.0);
        assert_eq!(dialogue_box.height, 200.0);
        assert!(dialogue_box.is_visible);
    }

    #[test]
    fn speaker_name_box_creation() {
        let speaker_box = SpeakerNameBox::new("テストキャラクター".to_string());
        assert_eq!(speaker_box.speaker_name, "テストキャラクター");
    }

    #[test]
    fn choice_button_creation() {
        let choice_button = ChoiceButton::new(0, "選択肢1".to_string());
        assert_eq!(choice_button.choice_index, 0);
        assert_eq!(choice_button.choice_text, "選択肢1");
        assert!(!choice_button.is_selected);
    }

    #[test]
    fn choice_button_colors() {
        let mut choice_button = ChoiceButton::new(0, "テスト".to_string());

        // 通常時の色
        let normal_color = choice_button.get_button_color();
        assert_eq!(normal_color, Color::srgba(0.3, 0.3, 0.7, 0.8));

        // 選択時の色
        choice_button.is_selected = true;
        let selected_color = choice_button.get_button_color();
        assert_eq!(selected_color, Color::srgba(0.9, 0.9, 0.3, 0.9));
    }

    #[test]
    fn character_sprite_positions() {
        let left_sprite = CharacterSprite::new(
            "test".to_string(),
            "normal".to_string(),
            CharacterSpritePosition::Left
        );
        assert_eq!(left_sprite.get_world_position(), Vec3::new(-400.0, -100.0, 5.0));

        let center_sprite = CharacterSprite::new(
            "test".to_string(),
            "normal".to_string(),
            CharacterSpritePosition::Center
        );
        assert_eq!(center_sprite.get_world_position(), Vec3::new(0.0, -100.0, 5.0));

        let custom_sprite = CharacterSprite::new(
            "test".to_string(),
            "normal".to_string(),
            CharacterSpritePosition::Custom(100.0, 200.0)
        );
        assert_eq!(custom_sprite.get_world_position(), Vec3::new(100.0, 200.0, 5.0));
    }
}
