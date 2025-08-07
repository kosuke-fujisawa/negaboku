//! 入力システム - キーボード・マウス入力処理
//!
//! UIとロジックを分離し、入力イベントのみを処理

use bevy::prelude::*;
use crate::presentation::ui_components::{GameMode, MenuCursor, GameScreen};

/// ボタン名を取得するヘルパー関数
pub fn get_button_name(index: usize) -> &'static str {
    match index {
        0 => "はじめから",
        1 => "つづきから",
        2 => "設定",
        3 => "ギャラリー",
        4 => "ゲーム終了",
        _ => "不明",
    }
}
