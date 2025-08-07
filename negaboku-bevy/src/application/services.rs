//! アプリケーションサービス層
//!
//! ドメインロジックを統合し、ユースケースを実現するサービス

use crate::domain::relationship::Relationship;
use crate::domain::battle::{BattleParty, BattleSkill, BattleResult, SkillType};
use crate::domain::character::{Character, CharacterRegistry};

/// 関係値管理サービス
#[derive(Debug)]
pub struct RelationshipService {
    relationships: std::collections::HashMap<String, Relationship>,
}

/// 戦闘管理サービス
#[derive(Debug)]
pub struct BattleService {
    relationship_service: RelationshipService,
}

/// ゲーム進行管理サービス
#[derive(Debug)]
pub struct GameProgressService {
    pub relationship_service: RelationshipService,
    pub battle_service: BattleService,
    pub character_registry: CharacterRegistry,
}

impl RelationshipService {
    pub fn new() -> Self {
        Self {
            relationships: std::collections::HashMap::new(),
        }
    }

    /// 関係値を取得（存在しない場合は新規作成）
    pub fn get_relationship(&mut self, character_a: &str, character_b: &str) -> &mut Relationship {
        let key = self.create_relationship_key(character_a, character_b);

        self.relationships.entry(key.clone()).or_insert_with(|| {
            Relationship::new(character_a, character_b)
        })
    }

    /// 関係値を変更
    pub fn modify_relationship(&mut self, character_a: &str, character_b: &str, delta: i32) -> i32 {
        let relationship = self.get_relationship(character_a, character_b);
        relationship.modify(delta);
        relationship.value()
    }

    /// 現在の関係値を参照
    pub fn get_relationship_value(&self, character_a: &str, character_b: &str) -> i32 {
        let key = self.create_relationship_key(character_a, character_b);
        self.relationships.get(&key)
            .map(|r| r.value())
            .unwrap_or(0)
    }

    /// 関係値キーを生成（順序を正規化）
    fn create_relationship_key(&self, character_a: &str, character_b: &str) -> String {
        let mut chars = vec![character_a, character_b];
        chars.sort();
        format!("{}_{}", chars[0], chars[1])
    }

    /// 全関係値の状況を取得
    pub fn get_all_relationships(&self) -> Vec<(String, i32)> {
        self.relationships.iter()
            .map(|(key, relationship)| (key.clone(), relationship.value()))
            .collect()
    }
}

impl BattleService {
    pub fn new(relationship_service: RelationshipService) -> Self {
        Self { relationship_service }
    }

    /// 戦闘を開始し、パーティを作成
    pub fn start_battle(&mut self, character_a: &str, character_b: &str) -> BattleParty {
        let mut party = BattleParty::new(character_a, character_b);

        // 現在の関係値を取得してパーティに反映
        let current_value = self.relationship_service.get_relationship_value(character_a, character_b);
        party.relationship.modify(current_value);

        party
    }

    /// 技の実行と関係値への影響を処理
    pub fn execute_skill_with_relationship_impact(
        &mut self,
        party: &BattleParty,
        skill: &BattleSkill
    ) -> Result<BattleResult, String> {
        let result = party.execute_skill(skill)?;

        // 協力技の使用は関係値にポジティブな影響
        if result.is_cooperative_attack {
            self.relationship_service.modify_relationship(
                &party.character_a,
                &party.character_b,
                5
            );
        }

        Ok(result)
    }

    /// 推奨される戦闘戦術を提案
    pub fn suggest_battle_strategy(&self, party: &BattleParty) -> Vec<String> {
        let mut suggestions = Vec::new();
        let relationship_value = party.relationship.value();

        match party.relationship.level() {
            crate::domain::relationship::RelationshipLevel::Intimate => {
                suggestions.push("協力技を積極的に使用しましょう".to_string());
                suggestions.push("コンビネーション攻撃で大ダメージを狙えます".to_string());
            }
            crate::domain::relationship::RelationshipLevel::Conflict => {
                if party.character_a.to_lowercase().contains("souma") {
                    suggestions.push("ソウマの対立技「怒りの一撃」が使用可能です".to_string());
                }
                suggestions.push("関係修復を優先した方が良いかもしれません".to_string());
            }
            crate::domain::relationship::RelationshipLevel::Normal => {
                if relationship_value > 25 {
                    suggestions.push("もう少しで協力技が使えるようになります".to_string());
                } else if relationship_value < -25 {
                    suggestions.push("関係が悪化しています。注意が必要です".to_string());
                }
                suggestions.push("基本技で安定した戦闘を心がけましょう".to_string());
            }
        }

        suggestions
    }
}

impl GameProgressService {
    pub fn new() -> Self {
        Self {
            relationship_service: RelationshipService::new(),
            battle_service: BattleService::new(RelationshipService::new()),
            character_registry: CharacterRegistry::default(),
        }
    }

    /// ゲーム内イベントによる関係値変化を処理
    pub fn process_story_event(&mut self, event_type: &str, characters: (&str, &str), impact: i32) -> String {
        let (char_a, char_b) = characters;
        let new_value = self.relationship_service.modify_relationship(char_a, char_b, impact);
        let relationship = self.relationship_service.get_relationship(char_a, char_b);

        format!(
            "【{}】により、{}と{}の関係が{}しました (現在: {} / {:?})",
            event_type,
            char_a,
            char_b,
            if impact > 0 { "向上" } else { "悪化" },
            new_value,
            relationship.level()
        )
    }

    /// 関係値に基づいたストーリー分岐の判定
    pub fn should_unlock_intimate_scene(&self, character_a: &str, character_b: &str) -> bool {
        let relationship_value = self.relationship_service.get_relationship_value(character_a, character_b);
        relationship_value >= 75 // 親密度75以上で親密シーン解放
    }

    /// エンディング判定
    pub fn determine_ending(&self, main_character: &str) -> String {
        let all_relationships = self.relationship_service.get_all_relationships();

        // 最も関係値の高いキャラクターを特定
        let best_relationship = all_relationships.iter()
            .filter(|(key, _)| key.contains(main_character))
            .max_by_key(|(_, value)| *value);

        match best_relationship {
            Some((key, value)) if *value >= 90 => {
                format!("True Ending - {}との深い絆エンディング", key)
            }
            Some((key, value)) if *value >= 50 => {
                format!("Good Ending - {}との友情エンディング", key)
            }
            Some((_, value)) if *value <= -50 => {
                "Bad Ending - 孤独エンディング".to_string()
            }
            _ => "Normal Ending - 平凡エンディング".to_string()
        }
    }

    /// ゲーム統計情報の取得
    pub fn get_game_stats(&self) -> GameStats {
        let relationships = self.relationship_service.get_all_relationships();
        let total_relationships = relationships.len();
        let positive_relationships = relationships.iter()
            .filter(|(_, value)| *value > 0)
            .count();
        let negative_relationships = relationships.iter()
            .filter(|(_, value)| *value < 0)
            .count();

        GameStats {
            total_relationships,
            positive_relationships,
            negative_relationships,
            highest_relationship: relationships.iter()
                .max_by_key(|(_, value)| *value)
                .map(|(key, value)| (key.clone(), *value)),
            lowest_relationship: relationships.iter()
                .min_by_key(|(_, value)| *value)
                .map(|(key, value)| (key.clone(), *value)),
        }
    }
}

/// ゲーム統計情報
#[derive(Debug, Clone)]
pub struct GameStats {
    pub total_relationships: usize,
    pub positive_relationships: usize,
    pub negative_relationships: usize,
    pub highest_relationship: Option<(String, i32)>,
    pub lowest_relationship: Option<(String, i32)>,
}

impl Default for RelationshipService {
    fn default() -> Self {
        Self::new()
    }
}

impl Default for GameProgressService {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn relationship_service_basic_operations() {
        let mut service = RelationshipService::new();

        // 初期値は0
        assert_eq!(service.get_relationship_value("souma", "yuzuki"), 0);

        // 関係値を変更
        let new_value = service.modify_relationship("souma", "yuzuki", 25);
        assert_eq!(new_value, 25);
        assert_eq!(service.get_relationship_value("souma", "yuzuki"), 25);

        // 順序が違っても同じ関係として扱われる
        assert_eq!(service.get_relationship_value("yuzuki", "souma"), 25);
    }

    #[test]
    fn battle_service_integration() {
        let mut service = BattleService::new(RelationshipService::new());
        let party = service.start_battle("souma", "yuzuki");

        assert_eq!(party.character_a, "souma");
        assert_eq!(party.character_b, "yuzuki");
        assert_eq!(party.relationship.value(), 0);
    }

    #[test]
    fn game_progress_service_story_events() {
        let mut service = GameProgressService::new();

        let result = service.process_story_event(
            "共同作業イベント",
            ("souma", "yuzuki"),
            10
        );

        assert!(result.contains("向上"));
        assert!(result.contains("souma"));
        assert!(result.contains("yuzuki"));
        assert_eq!(service.relationship_service.get_relationship_value("souma", "yuzuki"), 10);
    }

    #[test]
    fn intimate_scene_unlock_condition() {
        let mut service = GameProgressService::new();

        // 親密度が足りない場合
        assert!(!service.should_unlock_intimate_scene("souma", "yuzuki"));

        // 親密度を十分に上げる
        service.relationship_service.modify_relationship("souma", "yuzuki", 75);
        assert!(service.should_unlock_intimate_scene("souma", "yuzuki"));
    }

    #[test]
    fn ending_determination() {
        let mut service = GameProgressService::new();

        // 高い関係値を設定
        service.relationship_service.modify_relationship("souma", "yuzuki", 95);
        let ending = service.determine_ending("souma");
        assert!(ending.contains("True Ending"));

        // 低い関係値を設定
        service.relationship_service.modify_relationship("souma", "retsuji", -60);
        let bad_ending = service.determine_ending("retsuji");
        assert!(bad_ending.contains("Bad Ending"));
    }

    #[test]
    fn game_stats_calculation() {
        let mut service = GameProgressService::new();

        service.relationship_service.modify_relationship("souma", "yuzuki", 50);
        service.relationship_service.modify_relationship("souma", "kai", -30);
        service.relationship_service.modify_relationship("yuzuki", "kai", 20);

        let stats = service.get_game_stats();
        assert_eq!(stats.total_relationships, 3);
        assert_eq!(stats.positive_relationships, 2);
        assert_eq!(stats.negative_relationships, 1);

        assert!(stats.highest_relationship.is_some());
        assert!(stats.lowest_relationship.is_some());
    }
}
