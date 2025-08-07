//! テキスト表示関連システム
//!
//! テキストタイピング効果、ダイアログ表示、ログ管理に関するECSシステム

use bevy::prelude::*;
use crate::presentation::ui_components::*;

/// VNDialogue用のタイピングシステム
pub fn vn_typing_system(mut query: Query<(&mut VNDialogue, &mut Text2d)>, time: Res<Time>) {
    for (mut dialogue, mut text) in query.iter_mut() {
        if !dialogue.is_complete {
            dialogue.timer.tick(time.delta());

            if dialogue.timer.just_finished() {
                let chars: Vec<char> = dialogue.full_text.chars().collect();
                if dialogue.current_char < chars.len() {
                    dialogue.current_char += 1;
                    let displayed_text: String = chars[..dialogue.current_char].iter().collect();
                    text.0 = displayed_text;
                } else {
                    dialogue.is_complete = true;
                }
            }
        }
    }
}

/// テキストタイピングシステム（旧システム互換用）
pub fn text_typing_system(
    mut query: Query<(&mut DialogueText, &mut Text2d)>,
    time: Res<Time>,
    game_mode: Res<GameMode>,
) {
    if !game_mode.is_story_mode {
        return;
    }

    for (mut dialogue, mut text) in query.iter_mut() {
        if !dialogue.is_complete {
            dialogue.timer.tick(time.delta());

            if dialogue.timer.just_finished() {
                dialogue.current_char += 1;

                if dialogue.current_char >= dialogue.full_text.len() {
                    dialogue.current_char = dialogue.full_text.len();
                    dialogue.is_complete = true;
                }

                // 現在の文字数まで表示
                let displayed_text: String = dialogue
                    .full_text
                    .chars()
                    .take(dialogue.current_char)
                    .collect();

                *text = Text2d::new(displayed_text);
            }
        }
    }
}

/// ダイアログ完了時にログに追加するシステム
pub fn dialogue_completion_system(
    mut dialogue_query: Query<(&VNDialogue, &mut Text2d), Changed<VNDialogue>>,
    character_query: Query<&VNCharacterName>,
    mut log: ResMut<DialogueLog>,
) {
    for (dialogue, _text) in dialogue_query.iter_mut() {
        if dialogue.is_complete && dialogue.current_char == dialogue.full_text.len() {
            // キャラクター名を取得
            let character_name = character_query
                .iter()
                .next()
                .map(|name| name.name.clone())
                .unwrap_or_else(|| "".to_string());

            // ログに追加（重複チェック）
            if log.entries.is_empty()
                || log.entries.last().unwrap().text != dialogue.full_text {
                log.entries.push(DialogueEntry {
                    character_name,
                    text: dialogue.full_text.clone(),
                });
                println!("ログに追加: {}", dialogue.full_text);
            }
        }
    }
}

/// ログ入力システム（ログボタン・Lキー・ログウィンドウ内の操作）
pub fn log_input_system(
    keyboard_input: Res<ButtonInput<KeyCode>>,
    mouse_input: Res<ButtonInput<MouseButton>>,
    mut log: ResMut<DialogueLog>,
    windows: Query<&Window>,
    camera_query: Query<(&Camera, &GlobalTransform)>,
    log_button_query: Query<&Transform, (With<LogButton>, Without<LogCloseButton>)>,
    close_button_query: Query<&Transform, (With<LogCloseButton>, Without<LogButton>)>,
    game_mode: Res<GameMode>,
) {
    if !game_mode.is_story_mode {
        return;
    }

    // Lキーでログ表示切り替え
    if keyboard_input.just_pressed(KeyCode::KeyL) {
        log.is_visible = !log.is_visible;
        println!("Lキー: ログ表示切り替え -> {}", log.is_visible);
    }

    // マウスクリック処理
    if mouse_input.just_pressed(MouseButton::Left) {
        if let Ok(window) = windows.get_single() {
            if let Some(cursor_position) = window.cursor_position() {
                if let Ok((camera, camera_transform)) = camera_query.get_single() {
                    if let Ok(world_position) =
                        camera.viewport_to_world_2d(camera_transform, cursor_position) {

                        // ログボタンクリック判定
                        for button_transform in log_button_query.iter() {
                            let button_pos = button_transform.translation.truncate();
                            let button_size = Vec2::new(80.0, 40.0);

                            if world_position.x >= button_pos.x - button_size.x / 2.0
                                && world_position.x <= button_pos.x + button_size.x / 2.0
                                && world_position.y >= button_pos.y - button_size.y / 2.0
                                && world_position.y <= button_pos.y + button_size.y / 2.0 {
                                log.is_visible = !log.is_visible;
                                println!("ログボタンクリック: ログ表示切り替え -> {}", log.is_visible);
                                return;
                            }
                        }

                        // 閉じるボタンクリック判定（ログ表示中のみ）
                        if log.is_visible {
                            for close_transform in close_button_query.iter() {
                                let button_pos = close_transform.translation.truncate();
                                let button_size = Vec2::new(80.0, 40.0);

                                if world_position.x >= button_pos.x - button_size.x / 2.0
                                    && world_position.x <= button_pos.x + button_size.x / 2.0
                                    && world_position.y >= button_pos.y - button_size.y / 2.0
                                    && world_position.y <= button_pos.y + button_size.y / 2.0 {
                                    log.is_visible = false;
                                    println!("ログ閉じるボタンクリック");
                                    return;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Escapeキーでログウィンドウを閉じる
    if keyboard_input.just_pressed(KeyCode::Escape) && log.is_visible {
        log.is_visible = false;
        println!("Escapeキー: ログウィンドウを閉じる");
    }
}

/// ログUI表示システム
pub fn log_ui_system(
    mut commands: Commands,
    log: Res<DialogueLog>,
    assets: Option<Res<GameAssets>>,
    log_window_query: Query<Entity, With<LogWindow>>,
    log_entry_query: Query<Entity, With<LogEntry>>,
    game_mode: Res<GameMode>,
) {
    if !game_mode.is_story_mode {
        return;
    }

    let Some(assets) = assets else { return; };

    // ログウィンドウの表示・非表示を管理
    if log.is_visible {
        // ログウィンドウが存在しない場合は作成
        if log_window_query.is_empty() {
            create_log_window(&mut commands, &assets, &log);
        } else {
            // 既存のログエントリをクリアして再作成
            for entity in log_entry_query.iter() {
                commands.entity(entity).despawn();
            }
            create_log_entries(&mut commands, &assets, &log);
        }
    } else {
        // ログウィンドウを削除
        for entity in log_window_query.iter() {
            commands.entity(entity).despawn_recursive();
        }
    }
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

/// ストーリーモード専用マウス入力システム
pub fn story_mouse_input_system(
    mouse_input: Res<ButtonInput<MouseButton>>,
    windows: Query<&Window>,
    camera_query: Query<(&Camera, &GlobalTransform)>,
    log_button_query: Query<&Transform, With<LogButton>>,
    mut log: ResMut<DialogueLog>,
    game_mode: Res<GameMode>,
    markdown_state: Res<crate::application::scenario_system::MarkdownScenarioState>,
) {
    // マークダウンシナリオがアクティブな場合は、このシステムを無効化
    if !game_mode.is_story_mode || !mouse_input.just_pressed(MouseButton::Left) || markdown_state.current_scenario.is_some() {
        return;
    }

    if let Ok(window) = windows.get_single() {
        if let Some(cursor_position) = window.cursor_position() {
            if let Ok((camera, camera_transform)) = camera_query.get_single() {
                if let Ok(world_position) =
                    camera.viewport_to_world_2d(camera_transform, cursor_position)
                {
                    // ログボタンクリック判定を優先
                    for button_transform in log_button_query.iter() {
                        let button_pos = button_transform.translation.truncate();
                        let button_size = Vec2::new(80.0, 40.0);

                        if world_position.x >= button_pos.x - button_size.x / 2.0
                            && world_position.x <= button_pos.x + button_size.x / 2.0
                            && world_position.y >= button_pos.y - button_size.y / 2.0
                            && world_position.y <= button_pos.y + button_size.y / 2.0 {
                            log.is_visible = !log.is_visible;
                            println!("ストーリーモード: ログボタンクリック -> {}", log.is_visible);
                            return;
                        }
                    }

                    // ログウィンドウ表示中はテキスト進行を無効化
                    if log.is_visible {
                        return;
                    }

                    // テキスト進行処理（TODO: 適切なシステム間通信に変更）
                    println!("ストーリーモード: マウスクリックでテキスト進行");
                }
            }
        }
    }
}
