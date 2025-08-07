//! プレゼンテーション層システム
//!
//! UI・入力・表示に関連するECSシステムを定義

use bevy::prelude::*;
use crate::application::scenario_system::MarkdownScenarioState;
use crate::presentation::ui_components::*;
use crate::presentation::ui_utils::{
    next_background, get_current_background,
    get_menu_button_hover_color, get_menu_button_normal_color,
    get_menu_button_text, get_button_text_by_index
};

/// メニュー入力システム
pub fn menu_input_system(
    keyboard_input: Res<ButtonInput<KeyCode>>,
    mut game_mode: ResMut<GameMode>,
    mut menu_cursor: ResMut<MenuCursor>,
    mut commands: Commands,
    mut background_query: Query<&mut BackgroundController>,
    mut scenario_state: ResMut<ScenarioState>,
    assets: Res<GameAssets>,
    title_elements_query: Query<Entity, With<TitleScreenElement>>,
    markdown_state: Res<MarkdownScenarioState>,
) {
    // デバッグ: 押されたキーを全て表示
    for key in keyboard_input.get_just_pressed() {
        println!(
            "キー押下検出: {:?} - 画面状態: {:?}",
            key, game_mode.current_screen
        );
    }

    // メニューナビゲーション（タイトル画面のみ）
    if game_mode.current_screen == GameScreen::Title {
        if keyboard_input.just_pressed(KeyCode::ArrowUp) {
            if menu_cursor.current_index > 0 {
                menu_cursor.current_index -= 1;
                let button_name = get_button_text_by_index(menu_cursor.current_index);
                println!(
                    "↑キー: メニューカーソル位置 {} ({})",
                    menu_cursor.current_index, button_name
                );
            }
        }

        if keyboard_input.just_pressed(KeyCode::ArrowDown) {
            if menu_cursor.current_index < menu_cursor.max_buttons - 1 {
                menu_cursor.current_index += 1;
                let button_name = get_button_text_by_index(menu_cursor.current_index);
                println!(
                    "↓キー: メニューカーソル位置 {} ({})",
                    menu_cursor.current_index, button_name
                );
            }
        }

        // 数字キー1-5で直接メニュー選択（タイトル画面でのみ）
        if keyboard_input.just_pressed(KeyCode::Digit1) {
            menu_cursor.current_index = 0;
            println!("1キー: はじめから を選択");
            handle_menu_selection(
                0,
                &mut game_mode,
                &mut commands,
                &assets,
                &title_elements_query,
            );
        } else if keyboard_input.just_pressed(KeyCode::Digit2) {
            menu_cursor.current_index = 1;
            println!("2キー: つづきから を選択");
            handle_menu_selection(
                1,
                &mut game_mode,
                &mut commands,
                &assets,
                &title_elements_query,
            );
        } else if keyboard_input.just_pressed(KeyCode::Digit3) {
            menu_cursor.current_index = 2;
            println!("3キー: 設定 を選択");
            handle_menu_selection(
                2,
                &mut game_mode,
                &mut commands,
                &assets,
                &title_elements_query,
            );
        } else if keyboard_input.just_pressed(KeyCode::Digit4) {
            menu_cursor.current_index = 3;
            println!("4キー: ギャラリー を選択");
            handle_menu_selection(
                3,
                &mut game_mode,
                &mut commands,
                &assets,
                &title_elements_query,
            );
        } else if keyboard_input.just_pressed(KeyCode::Digit5) {
            menu_cursor.current_index = 4;
            println!("5キー: ゲーム終了 を選択");
            handle_menu_selection(
                4,
                &mut game_mode,
                &mut commands,
                &assets,
                &title_elements_query,
            );
        }

        if keyboard_input.just_pressed(KeyCode::Space)
            || keyboard_input.just_pressed(KeyCode::Enter)
        {
            handle_menu_selection(
                menu_cursor.current_index,
                &mut game_mode,
                &mut commands,
                &assets,
                &title_elements_query,
            );
        }
    } else if game_mode.is_story_mode {
        // ストーリーモード中の処理（Spaceキー）
        // マークダウンシナリオがロードされている場合は、markdown_scenario_input_systemに委譲
        // そうでない場合のみ旧システムを使用
        if markdown_state.current_scenario.is_none() {
            if keyboard_input.just_pressed(KeyCode::Space) {
                // TODO: テキスト進行処理をシステム間で呼び出す適切な方法に変更
            }
        }
        // マークダウンシナリオがある場合は、markdown_scenario_input_systemが処理
    }

    if keyboard_input.just_pressed(KeyCode::Escape) {
        if game_mode.is_story_mode {
            println!("タイトルに戻ります");
            game_mode.is_story_mode = false;
            game_mode.current_screen = GameScreen::Title;
            // 実際の実装では、ストーリー要素をクリアする処理を追加
        } else {
            println!("ゲームを終了します");
            std::process::exit(0);
        }
    }

    if keyboard_input.just_pressed(KeyCode::KeyB) {
        // 背景切替（Bキー）
        for mut bg_controller in background_query.iter_mut() {
            let _new_color = next_background(&mut bg_controller);
            println!(
                "背景を切り替えました: インデックス {}",
                bg_controller.current_index
            );
        }
    }
}

/// マウス入力システム
pub fn mouse_input_system(
    mouse_input: Res<ButtonInput<MouseButton>>,
    mut game_mode: ResMut<GameMode>,
    mut menu_cursor: ResMut<MenuCursor>,
    mut commands: Commands,
    windows: Query<&Window>,
    camera_query: Query<(&Camera, &GlobalTransform)>,
    mut button_query: Query<(&mut MenuButton, &Transform)>,
    assets: Res<GameAssets>,
    title_elements_query: Query<Entity, With<TitleScreenElement>>,
) {
    if !mouse_input.just_pressed(MouseButton::Left) {
        return;
    }

    // タイトル画面でのクリック処理のみ
    if game_mode.current_screen != GameScreen::Title {
        return;
    }

    if let Ok(window) = windows.get_single() {
        if let Some(cursor_position) = window.cursor_position() {
            if let Ok((camera, camera_transform)) = camera_query.get_single() {
                // カーソル位置をワールド座標に変換
                if let Ok(world_position) =
                    camera.viewport_to_world_2d(camera_transform, cursor_position)
                {
                    println!(
                        "マウスクリック検出: ({}, {})",
                        world_position.x, world_position.y
                    );

                    // ボタンとの当たり判定
                    for (button, transform) in button_query.iter_mut() {
                        let bounds = &button.bounds;
                        let button_x = transform.translation.x;
                        let button_y = transform.translation.y;

                        // ボタンの境界内かチェック
                        if world_position.x >= button_x - bounds.width / 2.0
                            && world_position.x <= button_x + bounds.width / 2.0
                            && world_position.y >= button_y - bounds.height / 2.0
                            && world_position.y <= button_y + bounds.height / 2.0
                        {
                            println!("ボタンクリック: {:?}", button.button_type);

                            // ボタンインデックスを設定
                            let button_index = match button.button_type {
                                MenuButtonType::NewGame => 0,
                                MenuButtonType::Continue => 1,
                                MenuButtonType::Settings => 2,
                                MenuButtonType::Gallery => 3,
                                MenuButtonType::Exit => 4,
                            };

                            menu_cursor.current_index = button_index;
                            handle_menu_selection(
                                button_index,
                                &mut game_mode,
                                &mut commands,
                                &assets,
                                &title_elements_query,
                            );
                            return;
                        }
                    }
                }
            }
        }
    }
}

/// ボタン名取得ヘルパー関数

/// メニュー選択処理
pub fn handle_menu_selection(
    index: usize,
    game_mode: &mut ResMut<GameMode>,
    commands: &mut Commands,
    assets: &Res<GameAssets>,
    title_elements_query: &Query<Entity, With<TitleScreenElement>>,
) {
    let button_types = vec![
        MenuButtonType::NewGame,
        MenuButtonType::Continue,
        MenuButtonType::Settings,
        MenuButtonType::Gallery,
        MenuButtonType::Exit,
    ];

    if let Some(button_type) = button_types.get(index) {
        match button_type {
            MenuButtonType::NewGame => {
                println!("「はじめから」が選択されました - ゲーム開始！");
                game_mode.is_story_mode = true;
                game_mode.current_screen = GameScreen::Story;

                // タイトル画面要素をすべてクリア
                for entity in title_elements_query.iter() {
                    commands.entity(entity).despawn_recursive();
                }
                println!("タイトル画面要素をクリアしました");

                // ビジュアルノベル風UIを構築
                super::screen_systems::setup_visual_novel_ui(commands, &assets);
            }
            MenuButtonType::Continue => {
                println!("「つづきから」が選択されました - 継続データ読み込み（未実装）");
            }
            MenuButtonType::Settings => {
                println!("「設定」が選択されました - 設定画面（未実装）");
                game_mode.current_screen = GameScreen::Settings;
            }
            MenuButtonType::Gallery => {
                println!("「ギャラリー」が選択されました - ギャラリー画面（未実装）");
                game_mode.current_screen = GameScreen::Gallery;
            }
            MenuButtonType::Exit => {
                println!("「ゲーム終了」が選択されました - ゲームを終了します");
                std::process::exit(0);
            }
        }
    }
}

/// ボタン視覚システム
pub fn button_visual_system(
    menu_cursor: Res<MenuCursor>,
    game_mode: Res<GameMode>,
    mut button_query: Query<(&mut Sprite, &MenuButton, Entity)>,
) {
    if game_mode.current_screen != GameScreen::Title {
        return;
    }

    for (mut sprite, menu_button, _entity) in button_query.iter_mut() {
        // エンティティのインデックスを計算（簡易的な方法）
        let button_index = match menu_button.button_type {
            MenuButtonType::NewGame => 0,
            MenuButtonType::Continue => 1,
            MenuButtonType::Settings => 2,
            MenuButtonType::Gallery => 3,
            MenuButtonType::Exit => 4,
        };

        // カーソル位置に基づいて色を変更
        if button_index == menu_cursor.current_index {
            sprite.color = get_menu_button_hover_color();
        } else {
            sprite.color = get_menu_button_normal_color();
        }
    }
}

/// 背景システム
pub fn background_system(
    mut background_query: Query<
        (&mut Sprite, &BackgroundController),
        Changed<BackgroundController>,
    >,
) {
    for (mut sprite, bg_controller) in background_query.iter_mut() {
        sprite.color = get_current_background(&bg_controller);
    }
}

/// アセット読み込み状態の監視システム
pub fn asset_loading_system(
    asset_server: Res<AssetServer>,
    assets: Option<Res<GameAssets>>,
    mut app_state: ResMut<AppState>,
) {
    if let Some(assets) = assets {
        if !app_state.font_load_checked {
            let font_state = asset_server.load_state(&assets.main_font);
            let bg_state = asset_server.load_state(&assets.background_souma_home);
            let char_state = asset_server.load_state(&assets.character_souma);

            match (font_state, bg_state, char_state) {
                (
                    bevy::asset::LoadState::Loaded,
                    bevy::asset::LoadState::Loaded,
                    bevy::asset::LoadState::Loaded,
                ) => {
                    println!("✅ 全アセット読み込み完了（フォント・背景・キャラクター）");
                    app_state.font_load_checked = true;
                    if app_state.init_state == InitState::LoadingFonts {
                        app_state.init_state = InitState::FontsReady;
                    }
                }
                (font_loading, bg_loading, char_loading) => {
                    if !matches!(font_loading, bevy::asset::LoadState::Loaded) {
                        match font_loading {
                            bevy::asset::LoadState::NotLoaded => {
                                println!("⏳ フォント読み込み待機中...")
                            }
                            bevy::asset::LoadState::Loading => println!("🔄 フォント読み込み中..."),
                            bevy::asset::LoadState::Failed(_) => {
                                eprintln!("❌ フォント読み込み失敗: assets/fonts/NotoSansJP-VariableFont_wght.ttf");
                                app_state.font_load_checked = true;
                            }
                            _ => {}
                        }
                    }
                    if !matches!(bg_loading, bevy::asset::LoadState::Loaded) {
                        match bg_loading {
                            bevy::asset::LoadState::Failed(_) => eprintln!(
                                "⚠️ 背景画像読み込み失敗: assets/images/backgrounds/souma_home.png"
                            ),
                            _ => {}
                        }
                    }
                    if !matches!(char_loading, bevy::asset::LoadState::Loaded) {
                        match char_loading {
                            bevy::asset::LoadState::Failed(_) => eprintln!("⚠️ キャラクター画像読み込み失敗: assets/images/characters/01_souma_kari.png"),
                            _ => {}
                        }
                    }
                }
            }
        }
    }
}

/// デバッグ用アセット状態表示システム
pub fn debug_asset_system(
    assets: Option<Res<GameAssets>>,
    asset_server: Res<AssetServer>,
    app_state: Res<AppState>,
    keyboard_input: Res<ButtonInput<KeyCode>>,
) {
    if keyboard_input.just_pressed(KeyCode::F1) {
        println!("🔍 ===== デバッグ情報 ===== ");
        println!("📋 アプリ初期化状態: {:?}", app_state.init_state);
        println!(
            "🔍 アセット読み込み確認済み: {}",
            app_state.font_load_checked
        );

        if let Some(assets) = assets {
            println!("🎨 フォントハンドル: {:?}", assets.main_font);
            println!("🇿️ 背景ハンドル: {:?}", assets.background_souma_home);
            println!("👤 キャラクターハンドル: {:?}", assets.character_souma);

            // 各アセット状態表示
            match asset_server.load_state(&assets.main_font) {
                bevy::asset::LoadState::NotLoaded => println!("📋 フォント状態: 未読み込み"),
                bevy::asset::LoadState::Loading => println!("📋 フォント状態: 読み込み中"),
                bevy::asset::LoadState::Loaded => println!("📋 フォント状態: 読み込み完了 ✅"),
                bevy::asset::LoadState::Failed(_) => println!("📋 フォント状態: 読み込み失敗 ❌"),
            }
            match asset_server.load_state(&assets.background_souma_home) {
                bevy::asset::LoadState::NotLoaded => println!("📋 背景状態: 未読み込み"),
                bevy::asset::LoadState::Loading => println!("📋 背景状態: 読み込み中"),
                bevy::asset::LoadState::Loaded => println!("📋 背景状態: 読み込み完了 ✅"),
                bevy::asset::LoadState::Failed(_) => println!("📋 背景状態: 読み込み失敗 ❌"),
            }
            match asset_server.load_state(&assets.character_souma) {
                bevy::asset::LoadState::NotLoaded => println!("📋 キャラ状態: 未読み込み"),
                bevy::asset::LoadState::Loading => println!("📋 キャラ状態: 読み込み中"),
                bevy::asset::LoadState::Loaded => println!("📋 キャラ状態: 読み込み完了 ✅"),
                bevy::asset::LoadState::Failed(_) => println!("📋 キャラ状態: 読み込み失敗 ❌"),
            }
        } else {
            println!("❌ GameAssetsリソースが見つかりません");
        }

        // ファイル存在確認
        let paths = vec![
            "assets/fonts/NotoSansJP-VariableFont_wght.ttf",
            "assets/images/backgrounds/souma_home.png",
            "assets/images/characters/01_souma_kari.png",
        ];

        for path in paths {
            if std::path::Path::new(path).exists() {
                println!("📁 ファイル存在確認: ✅ {}", path);
            } else {
                println!("📁 ファイル存在確認: ❌ {}", path);
            }
        }
        println!("========================");
    }
}

/// 段階的初期化システム
pub fn initialization_system(
    mut app_state: ResMut<AppState>,
    assets: Option<Res<GameAssets>>,
    asset_server: Res<AssetServer>,
    mut commands: Commands,
) {
    match app_state.init_state {
        InitState::LoadingFonts => {
            if let Some(assets) = assets {
                if matches!(
                    asset_server.load_state(&assets.main_font),
                    bevy::asset::LoadState::Loaded
                ) {
                    println!("🎉 アセット読み込み完了 - UI初期化を開始します");
                    app_state.init_state = InitState::FontsReady;
                }
            }
        }
        InitState::FontsReady => {
            // アセット準備完了後にUIを初期化
            if let Some(assets) = assets {
                setup_ui_with_assets(&mut commands, &assets);
                app_state.init_state = InitState::UIReady;
                println!("🖼️  UI初期化が完了しました");
            }
        }
        InitState::UIReady => {
            // 通常のゲーム処理 - 何もしない
        }
    }
}

/// アセット準備完了後のUI初期化
pub fn setup_ui_with_assets(commands: &mut Commands, assets: &Res<GameAssets>) {
    // カメラ設定
    commands.spawn(Camera2d);

    // 背景エンティティ（画面全体サイズ）
    commands.spawn((
        Sprite::from_color(Color::srgb(0.1, 0.2, 0.6), Vec2::new(1920.0, 1080.0)),
        Transform::from_xyz(0.0, 0.0, -10.0),
        BackgroundController::new(),
    ));

    // タイトルテキスト表示
    commands.spawn((
        Text2d::new("願い石と僕たちの絆"),
        TextFont {
            font: assets.main_font.clone(),
            font_size: 48.0,
            ..default()
        },
        TextLayout::new_with_justify(JustifyText::Center),
        TextColor(Color::srgb(1.0, 1.0, 1.0)),
        Transform::from_xyz(0.0, 200.0, 0.0),
        TitleScreenElement,
    ));

    // サブタイトル表示
    commands.spawn((
        Text2d::new("- Rust + Bevy版 -"),
        TextFont {
            font: assets.main_font.clone(),
            font_size: 24.0,
            ..default()
        },
        TextLayout::new_with_justify(JustifyText::Center),
        TextColor(Color::srgb(0.8, 0.8, 0.8)),
        Transform::from_xyz(0.0, 150.0, 0.0),
        TitleScreenElement,
    ));

    // メニューボタンを配置
    let button_types = vec![
        MenuButtonType::NewGame,
        MenuButtonType::Continue,
        MenuButtonType::Settings,
        MenuButtonType::Gallery,
        MenuButtonType::Exit,
    ];

    for (index, button_type) in button_types.into_iter().enumerate() {
        let y_pos = 50.0 - (index as f32 * 60.0); // ボタン間隔60px
        let button_width = 200.0;
        let button_height = 40.0;

        // ボタン背景を親エンティティとして作成
        let button_entity = commands
            .spawn((
                Sprite::from_color(
                    get_menu_button_normal_color(),
                    Vec2::new(button_width, button_height),
                ),
                Transform::from_xyz(0.0, y_pos, 1.0),
                MenuButton::new(button_type.clone(), 0.0, y_pos, button_width, button_height),
                TitleScreenElement,
            ))
            .id();

        // ボタンテキストを子エンティティとして作成（親子関係で正しく配置）
        let button_text = get_menu_button_text(&button_type);
        println!(
            "Creating button text: '{}' at position y={}",
            button_text, y_pos
        );

        let text_entity = commands
            .spawn((
                Text2d::new(button_text),
                TextFont {
                    font: assets.main_font.clone(),
                    font_size: 20.0,
                    ..default()
                },
                TextLayout::new_with_justify(JustifyText::Center),
                TextColor(Color::srgb(1.0, 1.0, 1.0)),
                Transform::from_xyz(0.0, 0.0, 1.0), // 親からの相対位置
                TitleScreenElement,
            ))
            .id();

        // 親子関係を設定
        commands.entity(button_entity).add_child(text_entity);
    }

    // ボタン説明表示（ボタンテキストの代替情報）
    commands.spawn((
        Text2d::new("1:はじめから 2:つづきから 3:設定 4:ギャラリー 5:ゲーム終了"),
        TextFont {
            font: assets.main_font.clone(),
            font_size: 16.0,
            ..default()
        },
        TextLayout::new_with_justify(JustifyText::Center),
        TextColor(Color::srgb(0.7, 0.7, 0.7)),
        Transform::from_xyz(0.0, -250.0, 0.0),
        TitleScreenElement,
    ));

    // 操作説明表示（下部に移動）
    commands.spawn((
        Text2d::new(
            "数字キー1-5で直接選択 / Spaceキー：選択 / Escキー：終了 / F1キー：デバッグ情報",
        ),
        TextFont {
            font: assets.main_font.clone(),
            font_size: 14.0,
            ..default()
        },
        TextLayout::new_with_justify(JustifyText::Center),
        TextColor(Color::srgb(0.6, 0.6, 0.6)),
        Transform::from_xyz(0.0, -300.0, 0.0),
        TitleScreenElement,
    ));

    println!("タイトル画面を表示しました（メニューボタン付き）");
    println!("操作方法: 1-5キーで直接選択、↑↓キーでカーソル移動、Spaceキー/Enterキーで決定、Escキーで終了、F1キーでデバッグ情報");
    println!("現在のメニューカーソル位置: 0 (はじめから)");
}
