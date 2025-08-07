//! UI用ユーティリティ関数
//!
//! ComponentからSystem層に移動したロジック関数群

use bevy::prelude::*;
use crate::presentation::ui_components::{MenuButtonType, BackgroundController, GameAssets, DialogueLog, DialogueEntry, LogWindow, LogEntry, LogCloseButton};


/// インデックスをMenuButtonTypeに変換
pub fn index_to_menu_button_type(index: usize) -> MenuButtonType {
    match index {
        0 => MenuButtonType::NewGame,
        1 => MenuButtonType::Continue,
        2 => MenuButtonType::Settings,
        3 => MenuButtonType::Gallery,
        4 => MenuButtonType::Exit,
        _ => MenuButtonType::NewGame, // フォールバック
    }
}

/// メニューボタンのテキストを取得
pub fn get_menu_button_text(button_type: &MenuButtonType) -> &'static str {
    match button_type {
        MenuButtonType::NewGame => "はじめから",
        MenuButtonType::Continue => "つづきから",
        MenuButtonType::Settings => "設定",
        MenuButtonType::Gallery => "ギャラリー",
        MenuButtonType::Exit => "ゲーム終了",
    }
}

/// インデックスから直接ボタン名を取得（便利関数）
pub fn get_button_text_by_index(index: usize) -> &'static str {
    let button_type = index_to_menu_button_type(index);
    get_menu_button_text(&button_type)
}

/// メニューボタンの通常色を取得
pub fn get_menu_button_normal_color() -> Color {
    Color::srgba(0.2, 0.2, 0.3, 0.8)
}

/// メニューボタンのホバー色を取得
pub fn get_menu_button_hover_color() -> Color {
    Color::srgba(0.4, 0.4, 0.5, 0.9)
}

/// メニューボタンの押下色を取得
pub fn get_menu_button_pressed_color() -> Color {
    Color::srgba(0.6, 0.6, 0.7, 1.0)
}

/// 背景色を次に進める
pub fn next_background(controller: &mut BackgroundController) -> Color {
    controller.current_index = (controller.current_index + 1) % controller.backgrounds.len();
    controller.backgrounds[controller.current_index]
}

/// 現在の背景色を取得
pub fn get_current_background(controller: &BackgroundController) -> Color {
    controller.backgrounds[controller.current_index]
}

/// ログウィンドウ作成関数
pub fn create_log_window(commands: &mut Commands, assets: &GameAssets, log: &DialogueLog) {
    // 半透明背景オーバーレイ
    commands.spawn((
        Sprite::from_color(
            Color::srgba(0.0, 0.0, 0.0, 0.7),
            Vec2::new(1920.0, 1080.0),
        ),
        Transform::from_xyz(0.0, 0.0, 50.0),
        LogWindow,
    ));

    // ログパネル背景
    commands.spawn((
        Sprite::from_color(
            Color::srgba(0.1, 0.1, 0.2, 0.95),
            Vec2::new(1200.0, 800.0),
        ),
        Transform::from_xyz(0.0, 0.0, 51.0),
        LogWindow,
    ));

    // タイトル
    commands.spawn((
        Text2d::new("会話ログ"),
        TextFont {
            font: assets.main_font.clone(),
            font_size: 32.0,
            ..default()
        },
        TextLayout::new_with_justify(JustifyText::Center),
        TextColor(Color::srgb(1.0, 1.0, 1.0)),
        Transform::from_xyz(0.0, 350.0, 52.0),
        LogWindow,
    ));

    // 閉じるボタン
    commands.spawn((
        Sprite::from_color(
            Color::srgba(0.8, 0.2, 0.2, 0.9),
            Vec2::new(80.0, 40.0),
        ),
        Transform::from_xyz(520.0, 350.0, 52.0),
        LogCloseButton,
        LogWindow,
    ));

    commands.spawn((
        Text2d::new("閉じる"),
        TextFont {
            font: assets.main_font.clone(),
            font_size: 16.0,
            ..default()
        },
        TextLayout::new_with_justify(JustifyText::Center),
        TextColor(Color::srgb(1.0, 1.0, 1.0)),
        Transform::from_xyz(520.0, 350.0, 53.0),
        LogWindow,
    ));

    create_log_entries(commands, assets, log);
}

/// ログエントリ作成関数
pub fn create_log_entries(commands: &mut Commands, assets: &GameAssets, log: &DialogueLog) {
    let start_y = 280.0;
    let entry_height = 80.0;
    let max_entries = 8; // 最大表示数

    let visible_entries = if log.entries.len() > max_entries {
        &log.entries[log.entries.len() - max_entries..]
    } else {
        &log.entries
    };

    for (index, entry) in visible_entries.iter().enumerate() {
        let y_pos = start_y - (index as f32 * entry_height);

        // キャラクター名（太字）
        if !entry.character_name.is_empty() {
            commands.spawn((
                Text2d::new(&entry.character_name),
                TextFont {
                    font: assets.main_font.clone(),
                    font_size: 20.0,
                    ..default()
                },
                TextLayout::new_with_justify(JustifyText::Left),
                TextColor(Color::srgb(1.0, 0.8, 0.6)),
                Transform::from_xyz(-550.0, y_pos, 52.0),
                LogEntry,
                LogWindow,
            ));
        }

        // 会話テキスト
        commands.spawn((
            Text2d::new(&entry.text),
            TextFont {
                font: assets.main_font.clone(),
                font_size: 18.0,
                ..default()
            },
            TextLayout::new_with_justify(JustifyText::Left),
            TextColor(Color::srgb(0.9, 0.9, 0.9)),
            Transform::from_xyz(-550.0, y_pos - 30.0, 52.0),
            LogEntry,
            LogWindow,
        ));

        // 区切り線
        commands.spawn((
            Sprite::from_color(
                Color::srgba(0.5, 0.5, 0.5, 0.3),
                Vec2::new(1100.0, 1.0),
            ),
            Transform::from_xyz(0.0, y_pos - 50.0, 52.0),
            LogEntry,
            LogWindow,
        ));
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_menu_button_text() {
        assert_eq!(get_menu_button_text(&MenuButtonType::NewGame), "はじめから");
        assert_eq!(get_menu_button_text(&MenuButtonType::Continue), "つづきから");
        assert_eq!(get_menu_button_text(&MenuButtonType::Settings), "設定");
        assert_eq!(get_menu_button_text(&MenuButtonType::Gallery), "ギャラリー");
        assert_eq!(get_menu_button_text(&MenuButtonType::Exit), "ゲーム終了");
    }

    #[test]
    fn test_background_controller_utils() {
        let mut controller = BackgroundController::new();
        let first_color = get_current_background(&controller);
        let next_color = next_background(&mut controller);
        assert_eq!(controller.current_index, 1);
        assert_ne!(first_color, next_color);
    }

    #[test]
    fn test_menu_button_colors() {
        let normal = get_menu_button_normal_color();
        let hover = get_menu_button_hover_color();
        let pressed = get_menu_button_pressed_color();

        // 異なる色であることを確認
        assert_ne!(normal, hover);
        assert_ne!(hover, pressed);
        assert_ne!(normal, pressed);
    }
}
