//! 画面管理システム - 画面遷移・UI構築
//!
//! 各画面の構築と管理を担当

use bevy::prelude::*;
use super::ui_components::*;
use crate::domain::character::CharacterRegistry;
use crate::application::command_executor::BackgroundImage;

pub fn setup_assets(mut commands: Commands, asset_server: Res<AssetServer>) {
    // フォント設定（存在するNotoSansJPを使用）
    let font_path = "fonts/NotoSansJP-VariableFont_wght.ttf";
    let background_path = "images/backgrounds/souma_home.png";
    let character_path = "images/characters/01_souma_kari.png";

    // ファイル存在確認
    let font_full_path = format!("assets/{}", font_path);
    let bg_full_path = format!("assets/{}", background_path);
    let char_full_path = format!("assets/{}", character_path);

    if !std::path::Path::new(&font_full_path).exists() {
        eprintln!("❌ フォントファイルが見つかりません: {}", font_full_path);
        eprintln!("💡 以下のコマンドでフォントを配置してください:");
        eprintln!("   mkdir -p assets/fonts");
        eprintln!("   cp path/to/NotoSansJP-VariableFont_wght.ttf assets/fonts/");
    } else {
        println!("✅ フォントファイルを確認: {}", font_full_path);
    }

    if !std::path::Path::new(&bg_full_path).exists() {
        eprintln!("❌ 背景画像が見つかりません: {}", bg_full_path);
        eprintln!("💡 以下のコマンドで背景画像を配置してください:");
        eprintln!("   mkdir -p assets/images/backgrounds");
        eprintln!("   cp path/to/souma_home.png assets/images/backgrounds/");
    } else {
        println!("✅ 背景画像を確認: {}", bg_full_path);
    }

    if !std::path::Path::new(&char_full_path).exists() {
        eprintln!("❌ キャラクター画像が見つかりません: {}", char_full_path);
        eprintln!("💡 以下のコマンドでキャラクター画像を配置してください:");
        eprintln!("   mkdir -p assets/images/characters");
        eprintln!("   cp path/to/01_souma_kari.png assets/images/characters/");
    } else {
        println!("✅ キャラクター画像を確認: {}", char_full_path);
    }

    // アセット読み込み
    let main_font = asset_server.load(font_path);
    let background_souma_home = asset_server.load(background_path);
    let character_souma = asset_server.load(character_path);

    commands.insert_resource(GameAssets {
        main_font,
        background_souma_home,
        character_souma,
    });

    println!("🔄 アセット読み込み開始: フォント、背景、キャラクター");
}

pub fn setup_character_registry(mut character_registry: ResMut<CharacterRegistry>) {
    character_registry.register_default_characters();
    println!("👥 キャラクター登録完了");
}

/// ビジュアルノベル風UI構築関数
pub fn setup_visual_novel_ui(commands: &mut Commands, assets: &Res<GameAssets>) {
    println!("🖼️ 背景画像スプライトを作成中...");

    // 0. 背景画像を最背面に全画面表示（Z座標: -10.0）
    let bg_entity = commands
        .spawn((
            Sprite {
                image: assets.background_souma_home.clone(),
                color: Color::WHITE,
                ..default()
            },
            Transform::from_xyz(0.0, 0.0, -10.0),
            BackgroundImage,
            StoryScreenElement,
        ))
        .id();

    println!("✅ 背景画像エンティティ作成完了: {:?}", bg_entity);

    println!("👤 キャラクター立ち絵スプライトを作成中...");

    // 1. キャラクター立ち絵を中央下寄りに表示（Z座標: -5.0）
    let char_entity = commands
        .spawn((
            Sprite {
                image: assets.character_souma.clone(),
                color: Color::WHITE,
                ..default()
            },
            Transform::from_xyz(0.0, -200.0, -5.0).with_scale(Vec3::splat(0.8)),
            crate::domain::character::CharacterDisplay {
                character_id: "souma".to_string(),
                current_face: "normal".to_string(),
                position: crate::domain::character::CharacterDisplayPosition::Center,
                is_visible: true,
            },
            StoryScreenElement,
        ))
        .id();

    println!("✅ キャラクターエンティティ作成完了: {:?}", char_entity);

    // 2. テキストボックスを半透明背景・角丸風にスタイリング（Z座標: 1.0）
    let textbox_height = 1080.0 * 0.25; // 270pxに増大（より見やすく）
    let textbox_y = -(1080.0 / 2.0) + (textbox_height / 2.0); // -405px

    commands.spawn((
        Sprite::from_color(
            Color::srgba(0.0, 0.0, 0.1, 0.85),
            Vec2::new(1800.0, textbox_height),
        ), // 幅を少し狭く、濃い背景
        Transform::from_xyz(0.0, textbox_y, 1.0),
        VNTextBox,
        StoryScreenElement,
    ));

    // 3. キャラクター名表示（白・太字・大きく右に移動）（Z座標: 2.0）
    commands.spawn((
        Text2d::new("ソウマ"),
        TextFont {
            font: assets.main_font.clone(),
            font_size: 32.0, // フォントサイズを少し大きく
            ..default()
        },
        TextLayout::new_with_justify(JustifyText::Left),
        TextColor(Color::srgb(1.0, 1.0, 1.0)),
        Transform::from_xyz(-500.0, textbox_y + 60.0, 2.0), // 大きく右に移動、下に移動
        VNCharacterName {
            name: "ソウマ".to_string(),
        },
        StoryScreenElement,
    ));

    // 4. 本文表示（白・標準・大きく右に移動、下に移動）（Z座標: 2.0）
    let vn_dialogue_entity = commands.spawn((
        Text2d::new(""),
        TextFont {
            font: assets.main_font.clone(),
            font_size: 22.0, // フォントサイズを少し大きく
            ..default()
        },
        TextLayout::new_with_justify(JustifyText::Left),
        TextColor(Color::srgb(1.0, 1.0, 1.0)),
        Transform::from_xyz(-480.0, textbox_y - 20.0, 2.0),  // 大きく右に移動（-780→-480）、下に移動（+10→-20）
        VNDialogue::new("願い石と僕たちの絆へようこそ！\nここは新しい冒険の始まりです。\nスペースキーで進めます。".to_string()),
        StoryScreenElement,
    )).id();

    println!("✅ VNDialogueコンポーネントを作成しました (Entity: {:?})", vn_dialogue_entity);

    // 5. ログボタンを左上に配置
    commands.spawn((
        Sprite::from_color(
            Color::srgba(0.3, 0.3, 0.4, 0.9),
            Vec2::new(80.0, 40.0),
        ),
        Transform::from_xyz(-900.0, 450.0, 3.0),
        LogButton,
        StoryScreenElement,
    ));

    commands.spawn((
        Text2d::new("ログ"),
        TextFont {
            font: assets.main_font.clone(),
            font_size: 18.0,
            ..default()
        },
        TextLayout::new_with_justify(JustifyText::Center),
        TextColor(Color::srgb(1.0, 1.0, 1.0)),
        Transform::from_xyz(-900.0, 450.0, 4.0),
        StoryScreenElement,
    ));

    // 4. UIボタン（スキップ・オート・セーブ・ロード）を右下に横並び
    let button_types = vec![
        VNButtonType::Skip,
        VNButtonType::Auto,
        VNButtonType::Save,
        VNButtonType::Load,
    ];

    let button_texts = vec!["スキップ", "オート", "セーブ", "ロード"];
    let button_width = 100.0; // 幅を少し大きく
    let button_height = 50.0; // 高さを少し大きく
    let button_spacing = 120.0; // 間隔を少し幅広く
    let start_x = 1920.0 / 2.0 - 480.0; // 右下にしっかり配置

    for (index, (button_type, button_text)) in
        button_types.into_iter().zip(button_texts).enumerate()
    {
        let x_pos = start_x + (index as f32 * button_spacing);
        let y_pos = textbox_y - 100.0; // テキストボックスの下、より遠くに

        // ボタン背景（半透明グレー）
        commands.spawn((
            Sprite::from_color(
                Color::srgba(0.2, 0.2, 0.3, 0.9),
                Vec2::new(button_width, button_height),
            ),
            Transform::from_xyz(x_pos, y_pos, 3.0),
            VNUIButton { button_type },
            StoryScreenElement,
        ));

        // ボタンテキスト
        commands.spawn((
            Text2d::new(button_text),
            TextFont {
                font: assets.main_font.clone(),
                font_size: 18.0, // フォントサイズを少し大きく
                ..default()
            },
            TextLayout::new_with_justify(JustifyText::Center),
            TextColor(Color::srgb(1.0, 1.0, 1.0)),
            Transform::from_xyz(x_pos, y_pos, 4.0),
            StoryScreenElement,
        ));
    }

    // 操作説明を画面下部に追加
    commands.spawn((
        Text2d::new("操作: Spaceキー = 次へ / Lキー or ログボタン = ログ表示 / Escキー = タイトルに戻る"),
        TextFont {
            font: assets.main_font.clone(),
            font_size: 16.0,
            ..default()
        },
        TextLayout::new_with_justify(JustifyText::Center),
        TextColor(Color::srgb(0.8, 0.8, 0.8)),
        Transform::from_xyz(0.0, -480.0, 2.0),
        StoryScreenElement,
    ));

    println!("🎨 ビジュアルノベル風UI構築完了（背景・立ち絵・テキストウィンドウ・操作ボタン）");
    println!("📖 テキストログ機能: Lキーまたはログボタンで表示/非表示切り替え");
    println!("💡 操作方法: Spaceキーでテキスト進行、完了後にログに自動追加");
}
