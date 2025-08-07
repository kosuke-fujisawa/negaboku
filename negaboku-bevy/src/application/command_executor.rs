//! コマンド実行システム - シーンコマンドの実行とビジュアル制御
//!
//! # 責務
//! - SceneCommandの実際の実行
//! - 背景・キャラクター・音声の制御
//! - 既存のBevy Componentとの統合

use bevy::prelude::*;
use crate::domain::scenario::{SceneCommand, CharacterPosition};
use crate::domain::character::{CharacterDisplay, CharacterDisplayPosition, CharacterRegistry};
// use std::collections::HashMap; // 将来使用予定

/// コマンド実行サービス
pub struct CommandExecutor;

impl CommandExecutor {
    /// シーンコマンドを実行
    pub fn execute_command(
        command: &SceneCommand,
        commands: &mut Commands,
        asset_server: &Res<AssetServer>,
        character_registry: &Res<CharacterRegistry>,
        background_query: &mut Query<&mut Sprite, (With<BackgroundImage>, Without<CharacterDisplay>)>,
        character_query: &mut Query<(Entity, &mut CharacterDisplay, &mut Transform, &mut Sprite)>,
    ) {
        match command {
            SceneCommand::Background { storage, time } => {
                Self::execute_background_change(commands, asset_server, background_query, storage, *time);
            }
            SceneCommand::CharacterShow { name, face, pos } => {
                Self::execute_character_show(
                    commands,
                    asset_server,
                    character_registry,
                    character_query,
                    name,
                    face.as_deref(),
                    pos.as_ref(),
                );
            }
            SceneCommand::CharacterHide { name } => {
                Self::execute_character_hide(character_query, name);
            }
            SceneCommand::Bgm { play, volume, loop_audio } => {
                Self::execute_bgm(commands, asset_server, play, *volume, *loop_audio);
            }
            SceneCommand::Se { play, volume } => {
                Self::execute_se(commands, asset_server, play, *volume);
            }
            SceneCommand::Wait { time } => {
                Self::execute_wait(*time);
            }
            SceneCommand::Choice { text } => {
                Self::execute_choice(commands, text);
            }
        }
    }

    /// 背景変更の実行
    fn execute_background_change(
        _commands: &mut Commands,
        asset_server: &Res<AssetServer>,
        background_query: &mut Query<&mut Sprite, (With<BackgroundImage>, Without<CharacterDisplay>)>,
        storage: &str,
        time: Option<u32>,
    ) {
        let image_path = format!("images/backgrounds/{}", storage);
        let image_handle = asset_server.load(&image_path);

        println!("🖼️ 背景変更: {} (時間: {:?}ms)", image_path, time);

        // 既存の背景を更新
        for mut sprite in background_query.iter_mut() {
            sprite.image = image_handle.clone();
            println!("✅ 背景スプライト更新完了");
        }

        // TODO: アニメーション時間の処理（future enhancement）
        if let Some(_duration) = time {
            // フェード等のアニメーション処理を将来実装
        }
    }

    /// キャラクター表示の実行
    fn execute_character_show(
        commands: &mut Commands,
        asset_server: &Res<AssetServer>,
        character_registry: &Res<CharacterRegistry>,
        character_query: &mut Query<(Entity, &mut CharacterDisplay, &mut Transform, &mut Sprite)>,
        name: &str,
        face: Option<&str>,
        pos: Option<&CharacterPosition>,
    ) {
        if let Some(character_info) = character_registry.get(name) {
            let display_face = face.unwrap_or(&character_info.default_face);
            let display_pos = pos.cloned().unwrap_or(CharacterPosition::Center);

            println!("👤 キャラクター表示: {} (表情: {}, 位置: {:?})",
                character_info.name, display_face, display_pos);

            // 既存のキャラクター表示を検索
            let mut found_existing = false;
            for (entity, mut char_display, mut transform, mut sprite) in character_query.iter_mut() {
                if char_display.character_id == name {
                    // 既存キャラクターを更新
                    char_display.current_face = display_face.to_string();
                    char_display.position = match display_pos {
                        CharacterPosition::Left => CharacterDisplayPosition::Left,
                        CharacterPosition::Center => CharacterDisplayPosition::Center,
                        CharacterPosition::Right => CharacterDisplayPosition::Right,
                        CharacterPosition::Custom { x, y } => CharacterDisplayPosition::Custom { x, y },
                    };
                    char_display.is_visible = true;

                    let (x, y) = char_display.position.to_screen_coords(1920.0);
                    transform.translation.x = x;
                    transform.translation.y = y;

                    sprite.color = Color::WHITE; // 表示状態
                    found_existing = true;
                    println!("✅ 既存キャラクター更新: {}", character_info.name);
                    break;
                }
            }

            if !found_existing {
                // 新規キャラクター作成
                let image_handle = asset_server.load(&character_info.image_path);
                let position = match display_pos {
                    CharacterPosition::Left => CharacterDisplayPosition::Left,
                    CharacterPosition::Center => CharacterDisplayPosition::Center,
                    CharacterPosition::Right => CharacterDisplayPosition::Right,
                    CharacterPosition::Custom { x, y } => CharacterDisplayPosition::Custom { x, y },
                };
                let (x, y) = position.to_screen_coords(1920.0);

                commands.spawn((
                    Sprite {
                        image: image_handle,
                        color: Color::WHITE,
                        ..default()
                    },
                    Transform::from_xyz(x, y, -5.0).with_scale(Vec3::splat(0.8)),
                    CharacterDisplay {
                        character_id: name.to_string(),
                        current_face: display_face.to_string(),
                        position,
                        is_visible: true,
                    },
                    StoryScreenElement,
                ));

                println!("✅ 新規キャラクター作成: {}", character_info.name);
            }
        } else {
            eprintln!("⚠️ 未登録キャラクター: {}", name);
        }
    }

    /// キャラクター非表示の実行
    fn execute_character_hide(
        character_query: &mut Query<(Entity, &mut CharacterDisplay, &mut Transform, &mut Sprite)>,
        name: &str,
    ) {
        println!("🫥 キャラクター非表示: {}", name);

        for (entity, mut char_display, mut transform, mut sprite) in character_query.iter_mut() {
            if char_display.character_id == name {
                char_display.is_visible = false;
                sprite.color = Color::NONE; // 透明化
                println!("✅ キャラクター非表示完了: {}", name);
                break;
            }
        }
    }

    /// BGM再生の実行
    fn execute_bgm(
        _commands: &mut Commands,
        _asset_server: &Res<AssetServer>,
        play: &str,
        volume: Option<f32>,
        loop_audio: Option<bool>,
    ) {
        let audio_path = format!("sounds/bgm/{}", play);
        let final_volume = volume.unwrap_or(1.0);
        let should_loop = loop_audio.unwrap_or(true);

        println!("🎵 BGM再生: {} (音量: {}, ループ: {})", audio_path, final_volume, should_loop);

        // TODO: Bevy Audio システムとの統合（future enhancement）
        // let audio_handle: Handle<AudioSource> = asset_server.load(&audio_path);
        // commands.spawn(AudioBundle {
        //     source: audio_handle,
        //     settings: PlaybackSettings::LOOP.with_volume(Volume::new(final_volume)),
        // });
    }

    /// SE再生の実行
    fn execute_se(
        _commands: &mut Commands,
        _asset_server: &Res<AssetServer>,
        play: &str,
        volume: Option<f32>,
    ) {
        let audio_path = format!("sounds/se/{}", play);
        let final_volume = volume.unwrap_or(1.0);

        println!("🔊 SE再生: {} (音量: {})", audio_path, final_volume);

        // TODO: Bevy Audio システムとの統合（future enhancement）
        // let audio_handle: Handle<AudioSource> = asset_server.load(&audio_path);
        // commands.spawn(AudioBundle {
        //     source: audio_handle,
        //     settings: PlaybackSettings::ONCE.with_volume(Volume::new(final_volume)),
        // });
    }

    /// 待機の実行
    fn execute_wait(time: u32) {
        println!("⏳ 待機: {}ms", time);

        // TODO: Timer Component を使った実際の待機処理（future enhancement）
        // 現在はログ出力のみ
    }

    /// 選択肢の実行
    fn execute_choice(_commands: &mut Commands, text: &str) {
        let choices: Vec<&str> = text.split('|').collect();

        println!("🎯 選択肢表示: {:?}", choices);

        // TODO: 選択肢UI生成（future enhancement）
        // 現在はログ出力のみ
    }
}

/// 背景画像マーカーコンポーネント（既存のBackgroundImageと統合）
#[derive(Component)]
pub struct BackgroundImage;

/// ストーリー画面要素マーカーコンポーネント（既存と統合）
#[derive(Component)]
pub struct StoryScreenElement;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_command_execution_logging() {
        // コマンド実行のログが正しく出力されることをテスト
        // 実際のBevy環境なしでのテストのため、ログ出力の確認のみ

        let bg_command = SceneCommand::Background {
            storage: "test_bg.jpg".to_string(),
            time: Some(1000),
        };

        // 実際の実行はBevyコンテキストが必要なため、
        // ここではコマンドの構造確認のみ行う
        match bg_command {
            SceneCommand::Background { storage, time } => {
                assert_eq!(storage, "test_bg.jpg");
                assert_eq!(time, Some(1000));
            }
            _ => panic!("期待していたBackgroundコマンドではありません"),
        }
    }
}
