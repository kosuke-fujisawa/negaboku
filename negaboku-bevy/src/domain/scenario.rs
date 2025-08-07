//! シナリオドメイン - マークダウンベースのシナリオ管理
//!
//! # 責務
//! - シナリオファイルの構造定義
//! - シーンコマンドの定義と解析
//! - シナリオ進行状態管理

use bevy::prelude::*;
// use serde::{Deserialize, Serialize}; // 将来使用予定
use std::collections::HashMap;

/// シナリオファイル全体の構造
#[derive(Debug, Clone, Resource)]
pub struct ScenarioFile {
    pub title: String,
    pub scenes: Vec<Scene>,
    pub current_scene_index: usize,
}

impl Default for ScenarioFile {
    fn default() -> Self {
        Self {
            title: "デフォルトシナリオ".to_string(),
            scenes: vec![],
            current_scene_index: 0,
        }
    }
}

/// 1つのシーンの情報
#[derive(Debug, Clone)]
pub struct Scene {
    pub commands: Vec<SceneCommand>,
    pub dialogue_blocks: Vec<DialogueBlock>,
}

/// シーンコマンド（[bg], [chara_show]等）
#[derive(Debug, Clone, PartialEq)]
pub enum SceneCommand {
    /// 背景変更 [bg storage=filename time=duration]
    Background {
        storage: String,
        time: Option<u32>,
    },
    /// キャラクター表示 [chara_show name=character face=expression pos=position]
    CharacterShow {
        name: String,
        face: Option<String>,
        pos: Option<CharacterPosition>,
    },
    /// キャラクター非表示 [chara_hide name=character]
    CharacterHide {
        name: String,
    },
    /// BGM再生 [bgm play=filename volume=volume loop=bool]
    Bgm {
        play: String,
        volume: Option<f32>,
        loop_audio: Option<bool>,
    },
    /// SE再生 [se play=filename volume=volume]
    Se {
        play: String,
        volume: Option<f32>,
    },
    /// 待機 [wait time=duration]
    Wait {
        time: u32,
    },
    /// 選択肢 [choice text="選択肢1|選択肢2|選択肢3"]
    Choice {
        text: String,
    },
}

/// キャラクター位置
#[derive(Debug, Clone, PartialEq)]
pub enum CharacterPosition {
    Left,
    Center,
    Right,
    /// カスタム座標
    Custom { x: f32, y: f32 },
}

impl From<&str> for CharacterPosition {
    fn from(s: &str) -> Self {
        match s.to_lowercase().as_str() {
            "left" => CharacterPosition::Left,
            "center" => CharacterPosition::Center,
            "right" => CharacterPosition::Right,
            _ => CharacterPosition::Center, // デフォルト
        }
    }
}

/// 1つのダイアログブロック
#[derive(Debug, Clone)]
pub struct DialogueBlock {
    pub speaker: Option<String>, // None = 地の文
    pub text: String,
}

/// シナリオ解析結果（パースエラー含む）
#[derive(Debug)]
pub struct ParseResult {
    pub scene: Option<Scene>,
    pub errors: Vec<ParseError>,
}

/// パースエラー情報
#[derive(Debug)]
pub struct ParseError {
    pub line_number: usize,
    pub message: String,
}

impl SceneCommand {
    /// コマンド文字列をパース
    ///
    /// # 例
    /// ```
    /// let cmd = SceneCommand::parse("[bg storage=forest_day.jpg time=500]");
    /// ```
    pub fn parse(command_str: &str) -> Result<Self, ParseError> {
        let trimmed = command_str.trim();

        // [cmd param1=value1 param2=value2] 形式をパース
        if !trimmed.starts_with('[') || !trimmed.ends_with(']') {
            return Err(ParseError {
                line_number: 0,
                message: format!("コマンド形式が無効: {}", command_str),
            });
        }

        let inner = &trimmed[1..trimmed.len()-1]; // [ ] を除去
        let parts: Vec<&str> = inner.split_whitespace().collect();

        if parts.is_empty() {
            return Err(ParseError {
                line_number: 0,
                message: "空のコマンド".to_string(),
            });
        }

        let command_name = parts[0];
        let params = Self::parse_parameters(&parts[1..])?;

        match command_name {
            "bg" => {
                let storage = params.get("storage")
                    .ok_or_else(|| ParseError {
                        line_number: 0,
                        message: "bg コマンドには storage パラメータが必要".to_string(),
                    })?
                    .clone();
                let time = params.get("time")
                    .and_then(|t| t.parse().ok());

                Ok(SceneCommand::Background { storage, time })
            }
            "chara_show" => {
                let name = params.get("name")
                    .ok_or_else(|| ParseError {
                        line_number: 0,
                        message: "chara_show コマンドには name パラメータが必要".to_string(),
                    })?
                    .clone();
                let face = params.get("face").cloned();
                let pos = params.get("pos").map(|p| CharacterPosition::from(p.as_str()));

                Ok(SceneCommand::CharacterShow { name, face, pos })
            }
            "chara_hide" => {
                let name = params.get("name")
                    .ok_or_else(|| ParseError {
                        line_number: 0,
                        message: "chara_hide コマンドには name パラメータが必要".to_string(),
                    })?
                    .clone();

                Ok(SceneCommand::CharacterHide { name })
            }
            "bgm" => {
                let play = params.get("play")
                    .ok_or_else(|| ParseError {
                        line_number: 0,
                        message: "bgm コマンドには play パラメータが必要".to_string(),
                    })?
                    .clone();
                let volume = params.get("volume").and_then(|v| v.parse().ok());
                let loop_audio = params.get("loop").and_then(|l| l.parse().ok());

                Ok(SceneCommand::Bgm { play, volume, loop_audio })
            }
            "se" => {
                let play = params.get("play")
                    .ok_or_else(|| ParseError {
                        line_number: 0,
                        message: "se コマンドには play パラメータが必要".to_string(),
                    })?
                    .clone();
                let volume = params.get("volume").and_then(|v| v.parse().ok());

                Ok(SceneCommand::Se { play, volume })
            }
            "wait" => {
                let time = params.get("time")
                    .ok_or_else(|| ParseError {
                        line_number: 0,
                        message: "wait コマンドには time パラメータが必要".to_string(),
                    })?
                    .parse()
                    .map_err(|_| ParseError {
                        line_number: 0,
                        message: "wait の time パラメータは数値である必要があります".to_string(),
                    })?;

                Ok(SceneCommand::Wait { time })
            }
            "choice" => {
                let text = params.get("text")
                    .ok_or_else(|| ParseError {
                        line_number: 0,
                        message: "choice コマンドには text パラメータが必要".to_string(),
                    })?
                    .clone();

                Ok(SceneCommand::Choice { text })
            }
            _ => Err(ParseError {
                line_number: 0,
                message: format!("未対応のコマンド: {}", command_name),
            }),
        }
    }

    /// パラメータ部分をHashMapに変換
    /// param1=value1 param2=value2 形式をパース
    fn parse_parameters(param_strs: &[&str]) -> Result<HashMap<String, String>, ParseError> {
        let mut params = HashMap::new();

        for param_str in param_strs {
            if let Some(eq_pos) = param_str.find('=') {
                let key = param_str[..eq_pos].trim().to_string();
                let value = param_str[eq_pos + 1..].trim().to_string();
                params.insert(key, value);
            } else {
                return Err(ParseError {
                    line_number: 0,
                    message: format!("無効なパラメータ形式: {}", param_str),
                });
            }
        }

        Ok(params)
    }
}

impl DialogueBlock {
    /// マークダウン行からダイアログブロックをパース
    ///
    /// # 対応形式
    /// - `**スピーカー名**「セリフ」` → スピーカー付きダイアログ（括弧形式）
    /// - `**スピーカー名**: セリフ` → スピーカー付きダイアログ（コロン形式）
    /// - `地の文` → スピーカーなしダイアログ
    pub fn parse(line: &str) -> Option<Self> {
        let trimmed = line.trim();

        if trimmed.is_empty() {
            return None;
        }

        // **スピーカー名**形式を検出
        if let Some(bold_end) = trimmed.find("**") {
            if let Some(second_bold_start) = trimmed[bold_end + 2..].find("**") {
                let speaker_name = trimmed[bold_end + 2..bold_end + 2 + second_bold_start].trim();
                let after_speaker = &trimmed[bold_end + 4 + second_bold_start..].trim();

                // 「」で囲まれたセリフを抽出（括弧形式）
                if after_speaker.starts_with('「') && after_speaker.ends_with('」') {
                    let dialogue_text = &after_speaker[3..after_speaker.len() - 3]; // 「」を除去

                    return Some(DialogueBlock {
                        speaker: Some(speaker_name.to_string()),
                        text: dialogue_text.to_string(),
                    });
                }
                // コロン形式の検出（**スピーカー名**: セリフ）
                else if after_speaker.starts_with(':') {
                    let dialogue_text = after_speaker[1..].trim(); // コロンを除去

                    return Some(DialogueBlock {
                        speaker: Some(speaker_name.to_string()),
                        text: dialogue_text.to_string(),
                    });
                } else {
                    // その他の形式でも、**name**の後のテキストをセリフとして扱う
                    return Some(DialogueBlock {
                        speaker: Some(speaker_name.to_string()),
                        text: after_speaker.to_string(),
                    });
                }
            }
        }

        // 地の文として扱う
        Some(DialogueBlock {
            speaker: None,
            text: trimmed.to_string(),
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_scene_command_parse_bg() {
        let cmd = SceneCommand::parse("[bg storage=forest_day.jpg time=500]").unwrap();
        match cmd {
            SceneCommand::Background { storage, time } => {
                assert_eq!(storage, "forest_day.jpg");
                assert_eq!(time, Some(500));
            }
            _ => panic!("期待していたBackgroundコマンドではありません"),
        }
    }

    #[test]
    fn test_scene_command_parse_chara_show() {
        let cmd = SceneCommand::parse("[chara_show name=souma face=normal pos=left]").unwrap();
        match cmd {
            SceneCommand::CharacterShow { name, face, pos } => {
                assert_eq!(name, "souma");
                assert_eq!(face, Some("normal".to_string()));
                assert_eq!(pos, Some(CharacterPosition::Left));
            }
            _ => panic!("期待していたCharacterShowコマンドではありません"),
        }
    }

    #[test]
    fn test_dialogue_block_parse_with_speaker() {
        let block = DialogueBlock::parse("**ソウマ**「こんにちは」").unwrap();
        assert_eq!(block.speaker, Some("ソウマ".to_string()));
        assert_eq!(block.text, "こんにちは");
    }

    #[test]
    fn test_dialogue_block_parse_narration() {
        let block = DialogueBlock::parse("遺跡の古い石造りの扉が、二人の前に立ちはだかっていた。").unwrap();
        assert_eq!(block.speaker, None);
        assert_eq!(block.text, "遺跡の古い石造りの扉が、二人の前に立ちはだかっていた。");
    }
}
