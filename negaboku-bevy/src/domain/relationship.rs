//! 関係値ドメイン - キャラクター間の関係性管理
//!
//! # 責務
//! - 関係値の定義と管理
//! - 関係レベルの判定
//! - 関係値変動の計算

// use bevy::prelude::*; // 将来使用予定

/// 関係値の定義
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum RelationshipLevel {
    /// 対立状態 (-100 ~ -1)
    Conflict,
    /// 通常状態 (0 ~ 49)
    Normal,
    /// 親密状態 (50 ~ 100)
    Intimate,
}

/// 関係値エンティティ
#[derive(Debug, Clone)]
pub struct Relationship {
    pub character_a: String,
    pub character_b: String,
    pub value: i32, // -100 ~ 100
}

impl Relationship {
    pub fn new(character_a: &str, character_b: &str) -> Self {
        Self {
            character_a: character_a.to_string(),
            character_b: character_b.to_string(),
            value: 0, // 初期は通常状態
        }
    }

    /// 関係値を変更
    pub fn modify(&mut self, delta: i32) {
        self.value = (self.value + delta).clamp(-100, 100);
    }

    /// 現在の関係値を取得
    pub fn value(&self) -> i32 {
        self.value
    }

    /// 現在の関係レベルを取得
    pub fn level(&self) -> RelationshipLevel {
        match self.value {
            -100..=-1 => RelationshipLevel::Conflict,
            0..=49 => RelationshipLevel::Normal,
            50..=100 => RelationshipLevel::Intimate,
            _ => RelationshipLevel::Normal, // 範囲外の場合は Normal とする
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_relationship_creation() {
        let rel = Relationship::new("souma", "yuzuki");
        assert_eq!(rel.character_a, "souma");
        assert_eq!(rel.character_b, "yuzuki");
        assert_eq!(rel.value, 0);
        assert_eq!(rel.level(), RelationshipLevel::Normal);
    }

    #[test]
    fn test_relationship_modification() {
        let mut rel = Relationship::new("souma", "yuzuki");

        // 親密に変更
        rel.modify(60);
        assert_eq!(rel.value(), 60);
        assert_eq!(rel.level(), RelationshipLevel::Intimate);

        // 対立に変更
        rel.modify(-80);
        assert_eq!(rel.value(), -20);
        assert_eq!(rel.level(), RelationshipLevel::Conflict);

        // 範囲外テスト
        rel.modify(-200);
        assert_eq!(rel.value(), -100); // クランプされる
    }
}
