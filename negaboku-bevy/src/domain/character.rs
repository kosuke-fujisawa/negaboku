//! キャラクタードメイン - ゲームキャラクターの定義と管理

use bevy::prelude::*;
use std::collections::HashMap;

/// キャラクター情報の定義
#[derive(Debug, Clone)]
pub struct Character {
    pub id: String,
    pub name: String,
    pub default_face: String,
    pub available_faces: Vec<String>,
    pub image_path: String,
}

impl Character {
    pub fn new(id: &str, name: &str, default_face: &str, image_path: &str) -> Self {
        Self {
            id: id.to_string(),
            name: name.to_string(),
            default_face: default_face.to_string(),
            available_faces: vec![default_face.to_string()],
            image_path: image_path.to_string(),
        }
    }

    /// 表情が利用可能かチェック
    pub fn has_face(&self, face: &str) -> bool {
        self.available_faces.contains(&face.to_string())
    }
}

/// キャラクター表示状態（ECSコンポーネント）
#[derive(Component, Debug, Clone)]
pub struct CharacterDisplay {
    pub character_id: String,
    pub current_face: String,
    pub position: CharacterDisplayPosition,
    pub is_visible: bool,
}

/// キャラクターの画面上の位置
#[derive(Debug, Clone, PartialEq)]
pub enum CharacterDisplayPosition {
    Left,
    Center,
    Right,
    Custom { x: f32, y: f32 },
}

impl CharacterDisplayPosition {
    /// 位置を画面座標に変換
    pub fn to_screen_coords(&self, screen_width: f32) -> (f32, f32) {
        match self {
            CharacterDisplayPosition::Left => (-screen_width * 0.25, -200.0),
            CharacterDisplayPosition::Center => (0.0, -200.0),
            CharacterDisplayPosition::Right => (screen_width * 0.25, -200.0),
            CharacterDisplayPosition::Custom { x, y } => (*x, *y),
        }
    }
}

/// キャラクター管理リソース
#[derive(Resource, Default)]
#[derive(Debug)]
pub struct CharacterRegistry {
    characters: HashMap<String, Character>,
}

impl CharacterRegistry {
    pub fn new() -> Self {
        Self {
            characters: HashMap::new(),
        }
    }

    /// キャラクターを登録
    pub fn register(&mut self, character: Character) {
        self.characters.insert(character.id.clone(), character);
    }

    /// キャラクター情報を取得
    pub fn get(&self, id: &str) -> Option<&Character> {
        self.characters.get(id)
    }

    /// 初期キャラクターを一括登録
    pub fn register_default_characters(&mut self) {
        // ソウマ
        self.register(Character::new(
            "souma",
            "ソウマ",
            "normal",
            "images/characters/01_souma_kari.png"
        ));

        // ユズキ
        self.register(Character::new(
            "yuzuki",
            "ユズキ",
            "smile",
            "images/characters/03_yuzuki_kari.jpg"
        ));

        // レツジ
        self.register(Character::new(
            "retsuji",
            "レツジ",
            "normal",
            "images/characters/02_retsuji_kari.png"
        ));

        // カイ
        self.register(Character::new(
            "kai",
            "カイ",
            "normal",
            "images/characters/06_kai_kari.png"
        ));
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_character_creation() {
        let character = Character::new("souma", "ソウマ", "normal", "path/to/image.png");
        assert_eq!(character.id, "souma");
        assert_eq!(character.name, "ソウマ");
        assert_eq!(character.default_face, "normal");
        assert!(character.has_face("normal"));
    }

    #[test]
    fn test_character_display_position() {
        let left_pos = CharacterDisplayPosition::Left;
        let (x, y) = left_pos.to_screen_coords(1920.0);
        assert_eq!(x, -480.0); // -1920 * 0.25
        assert_eq!(y, -200.0);
    }

    #[test]
    fn test_character_registry() {
        let mut registry = CharacterRegistry::new();
        let character = Character::new("test", "テスト", "normal", "test.png");

        registry.register(character);

        assert!(registry.get("test").is_some());
        assert!(registry.get("nonexistent").is_none());
    }
}
