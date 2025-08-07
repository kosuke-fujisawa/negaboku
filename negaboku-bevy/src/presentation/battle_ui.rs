//! 戦闘UI - バトル画面のUI要素
//!
//! 戦闘中のHP表示、技選択、ダメージ表示など
//! バトルシーンに特化したUI要素を管理

use bevy::prelude::*;
use crate::presentation::ui_components::*;
use crate::domain::battle::{BattleParty, BattleSkill, BattleResult};
use crate::application::services::BattleService;

/// 戦闘画面の要素を示すマーカーコンポーネント
#[derive(Component)]
pub struct BattleUIElement;

/// HPバーのコンポーネント
#[derive(Component, Debug, Clone)]
pub struct HPBar {
    pub character_name: String,
    pub current_hp: u32,
    pub max_hp: u32,
    pub width: f32,
    pub height: f32,
}

/// 戦闘技選択ボタンのコンポーネント
#[derive(Component, Debug)]
pub struct SkillButton {
    pub skill: BattleSkill,
    pub is_usable: bool,
    pub is_selected: bool,
}

/// ダメージ表示テキスト
#[derive(Component, Debug)]
pub struct DamageText {
    pub damage: u32,
    pub timer: Timer,
    pub initial_position: Vec3,
}

/// 関係値表示UI
#[derive(Component, Debug)]
pub struct RelationshipDisplay {
    pub character_a: String,
    pub character_b: String,
    pub relationship_value: i32,
}

/// 戦闘ログ表示
#[derive(Component, Debug)]
pub struct BattleLogDisplay {
    pub log_entries: Vec<String>,
    pub max_entries: usize,
}

impl HPBar {
    pub fn new(character_name: String, current_hp: u32, max_hp: u32) -> Self {
        Self {
            character_name,
            current_hp,
            max_hp,
            width: 300.0,
            height: 20.0,
        }
    }

    /// HPバーの色を取得（HP割合に応じて変化）
    pub fn get_bar_color(&self) -> Color {
        let hp_ratio = self.current_hp as f32 / self.max_hp as f32;

        if hp_ratio > 0.7 {
            Color::srgb(0.2, 0.8, 0.2) // 緑色（健康）
        } else if hp_ratio > 0.3 {
            Color::srgb(0.8, 0.8, 0.2) // 黄色（注意）
        } else {
            Color::srgb(0.8, 0.2, 0.2) // 赤色（危険）
        }
    }

    /// HPバーのフィル幅を計算
    pub fn get_fill_width(&self) -> f32 {
        let hp_ratio = self.current_hp as f32 / self.max_hp as f32;
        self.width * hp_ratio
    }

    /// HPバーを spawn
    pub fn spawn_hp_bar(
        commands: &mut Commands,
        assets: &GameAssets,
        character_name: &str,
        current_hp: u32,
        max_hp: u32,
        position: Vec3,
    ) -> Entity {
        let hp_bar = HPBar::new(character_name.to_string(), current_hp, max_hp);

        // HPバー背景
        let background_entity = commands.spawn((
            Sprite::from_color(Color::srgba(0.3, 0.3, 0.3, 0.8), Vec2::new(hp_bar.width, hp_bar.height)),
            Transform::from_translation(position),
            BattleUIElement,
        )).id();

        // HPバーフィル
        let fill_entity = commands.spawn((
            Sprite::from_color(hp_bar.get_bar_color(), Vec2::new(hp_bar.get_fill_width(), hp_bar.height)),
            Transform::from_xyz(-hp_bar.width * 0.25, 0.0, 1.0), // 左寄せ
            hp_bar.clone(),
            BattleUIElement,
        )).id();

        // キャラクター名テキスト
        let name_entity = commands.spawn((
            Text2d::new(character_name),
            TextFont {
                font: assets.main_font.clone(),
                font_size: 16.0,
                ..default()
            },
            TextColor(Color::WHITE),
            Transform::from_xyz(0.0, hp_bar.height + 10.0, 1.0),
            BattleUIElement,
        )).id();

        // HP数値テキスト
        let hp_text = format!("{}/{}", current_hp, max_hp);
        let hp_text_entity = commands.spawn((
            Text2d::new(&hp_text),
            TextFont {
                font: assets.main_font.clone(),
                font_size: 14.0,
                ..default()
            },
            TextColor(Color::WHITE),
            Transform::from_xyz(0.0, -hp_bar.height - 10.0, 1.0),
            BattleUIElement,
        )).id();

        commands.entity(background_entity).add_children(&[fill_entity, name_entity, hp_text_entity]);
        background_entity
    }
}

impl SkillButton {
    pub fn new(skill: BattleSkill, is_usable: bool) -> Self {
        Self {
            skill,
            is_usable,
            is_selected: false,
        }
    }

    /// スキルボタンの色を取得
    pub fn get_button_color(&self) -> Color {
        if !self.is_usable {
            Color::srgba(0.4, 0.4, 0.4, 0.6) // 使用不可（グレーアウト）
        } else if self.is_selected {
            Color::srgba(0.9, 0.7, 0.3, 0.9) // 選択中（オレンジ）
        } else {
            match self.skill.skill_type {
                crate::domain::battle::SkillType::Normal => Color::srgba(0.4, 0.6, 0.8, 0.8), // 青系
                crate::domain::battle::SkillType::Cooperation => Color::srgba(0.6, 0.8, 0.4, 0.8), // 緑系
                crate::domain::battle::SkillType::Conflict => Color::srgba(0.8, 0.4, 0.4, 0.8), // 赤系
            }
        }
    }

    /// スキルボタンを spawn
    pub fn spawn_skill_buttons(
        commands: &mut Commands,
        assets: &GameAssets,
        skills: &[BattleSkill],
        usable_skills: &[bool],
    ) -> Vec<Entity> {
        let mut button_entities = Vec::new();

        for (index, (skill, &is_usable)) in skills.iter().zip(usable_skills.iter()).enumerate() {
            let skill_button = SkillButton::new(skill.clone(), is_usable);
            let x_pos = -300.0 + (index as f32 * 150.0); // 横並び
            let y_pos = -300.0; // 画面下部

            let button_entity = commands.spawn((
                Sprite::from_color(skill_button.get_button_color(), Vec2::new(140.0, 60.0)),
                Transform::from_xyz(x_pos, y_pos, 10.0),
                skill_button,
                BattleUIElement,
            )).id();

            // スキル名テキスト
            let name_entity = commands.spawn((
                Text2d::new(&skill.name),
                TextFont {
                    font: assets.main_font.clone(),
                    font_size: 14.0,
                    ..default()
                },
                TextLayout::new_with_justify(JustifyText::Center),
                TextColor(if is_usable { Color::WHITE } else { Color::srgba(0.6, 0.6, 0.6, 1.0) }),
                Transform::from_xyz(0.0, 10.0, 1.0),
                BattleUIElement,
            )).id();

            // 威力表示
            let power_text = format!("威力: {}", skill.base_power);
            let power_entity = commands.spawn((
                Text2d::new(&power_text),
                TextFont {
                    font: assets.main_font.clone(),
                    font_size: 10.0,
                    ..default()
                },
                TextLayout::new_with_justify(JustifyText::Center),
                TextColor(if is_usable { Color::srgba(0.9, 0.9, 0.9, 1.0) } else { Color::srgba(0.5, 0.5, 0.5, 1.0) }),
                Transform::from_xyz(0.0, -10.0, 1.0),
                BattleUIElement,
            )).id();

            commands.entity(button_entity).add_children(&[name_entity, power_entity]);
            button_entities.push(button_entity);
        }

        button_entities
    }
}

impl DamageText {
    pub fn new(damage: u32, position: Vec3) -> Self {
        Self {
            damage,
            timer: Timer::from_seconds(2.0, TimerMode::Once),
            initial_position: position,
        }
    }

    /// ダメージテキストを spawn
    pub fn spawn_damage_text(
        commands: &mut Commands,
        assets: &GameAssets,
        damage: u32,
        position: Vec3,
    ) -> Entity {
        let damage_text = DamageText::new(damage, position);
        let text_content = format!("-{}", damage);

        commands.spawn((
            Text2d::new(&text_content),
            TextFont {
                font: assets.main_font.clone(),
                font_size: 24.0,
                ..default()
            },
            TextColor(Color::srgb(1.0, 0.3, 0.3)), // 赤色
            Transform::from_translation(position),
            damage_text,
            BattleUIElement,
        )).id()
    }
}

impl RelationshipDisplay {
    pub fn new(character_a: String, character_b: String, relationship_value: i32) -> Self {
        Self {
            character_a,
            character_b,
            relationship_value,
        }
    }

    /// 関係値の表示色を取得
    pub fn get_relationship_color(&self) -> Color {
        if self.relationship_value >= 50 {
            Color::srgb(0.3, 0.8, 0.3) // 親密（緑）
        } else if self.relationship_value <= -50 {
            Color::srgb(0.8, 0.3, 0.3) // 対立（赤）
        } else {
            Color::srgb(0.7, 0.7, 0.7) // 通常（グレー）
        }
    }

    /// 関係値表示をspawn
    pub fn spawn_relationship_display(
        commands: &mut Commands,
        assets: &GameAssets,
        character_a: &str,
        character_b: &str,
        relationship_value: i32,
    ) -> Entity {
        let rel_display = RelationshipDisplay::new(
            character_a.to_string(),
            character_b.to_string(),
            relationship_value,
        );

        let relationship_text = format!("{}⇔{}: {}", character_a, character_b, relationship_value);

        commands.spawn((
            Text2d::new(&relationship_text),
            TextFont {
                font: assets.main_font.clone(),
                font_size: 16.0,
                ..default()
            },
            TextColor(rel_display.get_relationship_color()),
            Transform::from_xyz(0.0, 400.0, 10.0), // 画面上部
            rel_display,
            BattleUIElement,
        )).id()
    }
}

/// 戦闘UI更新システム
pub fn battle_ui_update_system(
    mut hp_bar_query: Query<(&mut HPBar, &mut Sprite), With<HPBar>>,
    mut skill_button_query: Query<(&mut SkillButton, &mut Sprite), (With<SkillButton>, Without<HPBar>)>,
    mut relationship_query: Query<(&mut RelationshipDisplay, &mut Text2d)>,
) {
    // HPバーの更新
    for (hp_bar, mut sprite) in hp_bar_query.iter_mut() {
        sprite.color = hp_bar.get_bar_color();
        // HPバーのサイズも更新
        if let Some(size) = sprite.custom_size {
            sprite.custom_size = Some(Vec2::new(hp_bar.get_fill_width(), size.y));
        }
    }

    // スキルボタンの色更新
    for (skill_button, mut sprite) in skill_button_query.iter_mut() {
        sprite.color = skill_button.get_button_color();
    }

    // 関係値表示の色更新
    for (relationship_display, mut text) in relationship_query.iter_mut() {
        // テキストの内容更新
        let new_text = format!("{}⇔{}: {}",
            relationship_display.character_a,
            relationship_display.character_b,
            relationship_display.relationship_value
        );
        **text = new_text;
    }
}

/// ダメージテキスト アニメーション システム
pub fn damage_text_animation_system(
    mut commands: Commands,
    mut damage_text_query: Query<(Entity, &mut DamageText, &mut Transform)>,
    time: Res<Time>,
) {
    for (entity, mut damage_text, mut transform) in damage_text_query.iter_mut() {
        damage_text.timer.tick(time.delta());

        // 上に移動しながらフェードアウト
        let elapsed = damage_text.timer.elapsed_secs();
        let progress = elapsed / damage_text.timer.duration().as_secs_f32();

        // Y座標を上に移動
        transform.translation.y = damage_text.initial_position.y + (progress * 50.0);

        // 透明度を徐々に下げる（スプライトではなくテキストの場合）
        // TODO: テキストの透明度を変更する実装

        // 時間が経ったら削除
        if damage_text.timer.finished() {
            commands.entity(entity).despawn_recursive();
        }
    }
}

/// 戦闘スキル選択システム
pub fn battle_skill_input_system(
    keyboard_input: Res<ButtonInput<KeyCode>>,
    mut skill_button_query: Query<&mut SkillButton>,
    mut commands: Commands,
) {
    let mut skills: Vec<_> = skill_button_query.iter_mut().collect();
    if skills.is_empty() {
        return;
    }

    // 数字キーでスキル選択
    for key_code in keyboard_input.get_just_pressed() {
        let skill_index = match key_code {
            KeyCode::Digit1 => Some(0),
            KeyCode::Digit2 => Some(1),
            KeyCode::Digit3 => Some(2),
            KeyCode::Digit4 => Some(3),
            _ => None,
        };

        if let Some(index) = skill_index {
            if index < skills.len() && skills[index].is_usable {
                // 全てのスキルボタンの選択状態をリセット
                for skill_button in skills.iter_mut() {
                    skill_button.is_selected = false;
                }

                // 選択されたスキルをマーク
                skills[index].is_selected = true;

                info!("スキル「{}」を選択しました", skills[index].skill.name);

                // TODO: 戦闘処理の実行
                break;
            }
        }
    }
}

/// 戦闘UI要素のクリーンアップシステム
pub fn cleanup_battle_ui_system(
    mut commands: Commands,
    battle_ui_elements: Query<Entity, With<BattleUIElement>>,
    game_mode: Res<GameMode>,
) {
    // 戦闘モードを離れた時にバトルUI要素をクリーンアップ
    if game_mode.current_screen != GameScreen::Battle {
        for entity in battle_ui_elements.iter() {
            commands.entity(entity).despawn_recursive();
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::battle::SkillType;

    #[test]
    fn hp_bar_creation() {
        let hp_bar = HPBar::new("TestCharacter".to_string(), 80, 100);
        assert_eq!(hp_bar.character_name, "TestCharacter");
        assert_eq!(hp_bar.current_hp, 80);
        assert_eq!(hp_bar.max_hp, 100);
    }

    #[test]
    fn hp_bar_colors() {
        let full_hp = HPBar::new("Test".to_string(), 100, 100);
        assert_eq!(full_hp.get_bar_color(), Color::srgb(0.2, 0.8, 0.2)); // 緑

        let medium_hp = HPBar::new("Test".to_string(), 50, 100);
        assert_eq!(medium_hp.get_bar_color(), Color::srgb(0.8, 0.8, 0.2)); // 黄

        let low_hp = HPBar::new("Test".to_string(), 20, 100);
        assert_eq!(low_hp.get_bar_color(), Color::srgb(0.8, 0.2, 0.2)); // 赤
    }

    #[test]
    fn hp_bar_fill_width() {
        let hp_bar = HPBar::new("Test".to_string(), 75, 100);
        assert_eq!(hp_bar.get_fill_width(), 225.0); // 300.0 * 0.75
    }

    #[test]
    fn skill_button_creation() {
        let skill = BattleSkill::new("Test Skill", SkillType::Normal, 100, "Test skill");
        let skill_button = SkillButton::new(skill, true);
        assert_eq!(skill_button.skill.name, "Test Skill");
        assert!(skill_button.is_usable);
        assert!(!skill_button.is_selected);
    }

    #[test]
    fn skill_button_colors() {
        let skill = BattleSkill::new("Test", SkillType::Normal, 100, "Test");

        // 使用不可の場合
        let unusable_button = SkillButton::new(skill.clone(), false);
        assert_eq!(unusable_button.get_button_color(), Color::srgba(0.4, 0.4, 0.4, 0.6));

        // 選択中の場合
        let mut selected_button = SkillButton::new(skill.clone(), true);
        selected_button.is_selected = true;
        assert_eq!(selected_button.get_button_color(), Color::srgba(0.9, 0.7, 0.3, 0.9));

        // 通常の場合
        let normal_button = SkillButton::new(skill, true);
        assert_eq!(normal_button.get_button_color(), Color::srgba(0.4, 0.6, 0.8, 0.8));
    }

    #[test]
    fn damage_text_creation() {
        let damage_text = DamageText::new(150, Vec3::new(0.0, 0.0, 0.0));
        assert_eq!(damage_text.damage, 150);
        assert_eq!(damage_text.initial_position, Vec3::ZERO);
        assert_eq!(damage_text.timer.duration().as_secs_f32(), 2.0);
    }

    #[test]
    fn relationship_display_colors() {
        let intimate_rel = RelationshipDisplay::new("A".to_string(), "B".to_string(), 75);
        assert_eq!(intimate_rel.get_relationship_color(), Color::srgb(0.3, 0.8, 0.3)); // 緑

        let conflict_rel = RelationshipDisplay::new("A".to_string(), "B".to_string(), -60);
        assert_eq!(conflict_rel.get_relationship_color(), Color::srgb(0.8, 0.3, 0.3)); // 赤

        let normal_rel = RelationshipDisplay::new("A".to_string(), "B".to_string(), 25);
        assert_eq!(normal_rel.get_relationship_color(), Color::srgb(0.7, 0.7, 0.7)); // グレー
    }
}
