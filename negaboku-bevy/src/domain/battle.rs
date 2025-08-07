//! 戦闘システムのドメインロジック
//!
//! 関係値に基づく技・効果の計算やダメージ処理など、
//! 戦闘の核となるビジネスロジックを定義

use crate::domain::relationship::{Relationship, RelationshipLevel};

/// 戦闘技の種類
#[derive(Debug, Clone, PartialEq)]
pub enum SkillType {
    /// 通常技（関係値に関係なく使用可能）
    Normal,
    /// 共闘技（親密状態でのみ使用可能）
    Cooperation,
    /// 対立技（対立状態でのみ使用可能、主にソウマ限定）
    Conflict,
}

/// 戦闘技
#[derive(Debug, Clone)]
pub struct BattleSkill {
    pub name: String,
    pub skill_type: SkillType,
    pub base_power: u32,
    pub description: String,
    /// この技を使える関係値の範囲
    pub required_level: Option<RelationshipLevel>,
}

/// 戦闘パーティ（2人固定）
#[derive(Debug, Clone)]
pub struct BattleParty {
    pub character_a: String,
    pub character_b: String,
    pub relationship: Relationship,
}

/// 戦闘計算結果
#[derive(Debug, Clone)]
pub struct BattleResult {
    pub skill_used: BattleSkill,
    pub final_damage: u32,
    pub relationship_bonus: f32,
    pub is_cooperative_attack: bool,
}

impl BattleSkill {
    pub fn new(name: &str, skill_type: SkillType, base_power: u32, description: &str) -> Self {
        let required_level = match skill_type {
            SkillType::Normal => None,
            SkillType::Cooperation => Some(RelationshipLevel::Intimate),
            SkillType::Conflict => Some(RelationshipLevel::Conflict),
        };

        Self {
            name: name.to_string(),
            skill_type,
            base_power,
            description: description.to_string(),
            required_level,
        }
    }

    /// この技が現在の関係値で使用可能かチェック
    pub fn can_use(&self, relationship_level: RelationshipLevel) -> bool {
        match self.required_level {
            None => true,
            Some(required) => required == relationship_level,
        }
    }
}

impl BattleParty {
    pub fn new(character_a: &str, character_b: &str) -> Self {
        Self {
            character_a: character_a.to_string(),
            character_b: character_b.to_string(),
            relationship: Relationship::new(character_a, character_b),
        }
    }

    /// 現在の関係値で使用可能な技一覧を取得
    pub fn available_skills(&self) -> Vec<BattleSkill> {
        let mut skills = vec![
            // 通常技（常時使用可能）
            BattleSkill::new("基本攻撃", SkillType::Normal, 100, "基本的な攻撃技"),
            BattleSkill::new("防御", SkillType::Normal, 50, "防御態勢を取る"),
        ];

        let current_level = self.relationship.level();

        match current_level {
            RelationshipLevel::Intimate => {
                skills.push(BattleSkill::new(
                    "コンビネーション・アタック",
                    SkillType::Cooperation,
                    200,
                    "息の合った連携攻撃"
                ));
                skills.push(BattleSkill::new(
                    "ダブル・ストライク",
                    SkillType::Cooperation,
                    180,
                    "同時攻撃による強力な一撃"
                ));
            }
            RelationshipLevel::Conflict => {
                // 対立技は主にソウマ（character_a）限定
                if self.character_a.to_lowercase().contains("souma") {
                    skills.push(BattleSkill::new(
                        "怒りの一撃",
                        SkillType::Conflict,
                        150,
                        "怒りの力で繰り出す強力な攻撃"
                    ));
                }
            }
            RelationshipLevel::Normal => {
                // 通常状態では追加技なし
            }
        }

        skills
    }

    /// 技を使用して戦闘結果を計算
    pub fn execute_skill(&self, skill: &BattleSkill) -> Result<BattleResult, String> {
        let relationship_level = self.relationship.level();

        if !skill.can_use(relationship_level) {
            return Err(format!(
                "技「{}」は現在の関係値（{:?}）では使用できません",
                skill.name, relationship_level
            ));
        }

        // 関係値ボーナスを計算
        let relationship_bonus = self.calculate_relationship_bonus(&skill.skill_type);
        let final_damage = (skill.base_power as f32 * (1.0 + relationship_bonus)) as u32;

        let is_cooperative_attack = skill.skill_type == SkillType::Cooperation;

        Ok(BattleResult {
            skill_used: skill.clone(),
            final_damage,
            relationship_bonus,
            is_cooperative_attack,
        })
    }

    /// 関係値に基づくダメージボーナスを計算
    fn calculate_relationship_bonus(&self, skill_type: &SkillType) -> f32 {
        let relationship_value = self.relationship.value();

        match skill_type {
            SkillType::Cooperation => {
                // 親密度が高いほど協力技のボーナスが大きい
                if relationship_value >= 75 {
                    0.5 // +50%
                } else if relationship_value >= 50 {
                    0.3 // +30%
                } else {
                    0.0
                }
            }
            SkillType::Conflict => {
                // 対立値が高いほど対立技のボーナスが大きい
                if relationship_value <= -75 {
                    0.4 // +40%
                } else if relationship_value <= -50 {
                    0.2 // +20%
                } else {
                    0.0
                }
            }
            SkillType::Normal => {
                // 通常技は関係値の影響を受けにくい
                (relationship_value.abs() as f32) * 0.001 // 微弱な影響のみ
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn skill_creation_and_usage() {
        let skill = BattleSkill::new("テスト技", SkillType::Normal, 100, "テスト用の技");
        assert_eq!(skill.name, "テスト技");
        assert_eq!(skill.base_power, 100);
        assert_eq!(skill.skill_type, SkillType::Normal);
        assert!(skill.can_use(RelationshipLevel::Normal));
    }

    #[test]
    fn cooperation_skill_requirements() {
        let coop_skill = BattleSkill::new(
            "協力技",
            SkillType::Cooperation,
            200,
            "協力が必要な技"
        );

        assert!(!coop_skill.can_use(RelationshipLevel::Normal));
        assert!(!coop_skill.can_use(RelationshipLevel::Conflict));
        assert!(coop_skill.can_use(RelationshipLevel::Intimate));
    }

    #[test]
    fn battle_party_creation() {
        let party = BattleParty::new("souma", "yuzuki");
        assert_eq!(party.character_a, "souma");
        assert_eq!(party.character_b, "yuzuki");
        assert_eq!(party.relationship.value(), 0);
    }

    #[test]
    fn available_skills_normal_relationship() {
        let party = BattleParty::new("souma", "yuzuki");
        let skills = party.available_skills();

        // 通常状態では基本技のみ
        assert_eq!(skills.len(), 2);
        assert!(skills.iter().any(|s| s.name == "基本攻撃"));
        assert!(skills.iter().any(|s| s.name == "防御"));
    }

    #[test]
    fn skill_execution_success() {
        let party = BattleParty::new("souma", "yuzuki");
        let skill = BattleSkill::new("テスト技", SkillType::Normal, 100, "テスト");

        let result = party.execute_skill(&skill);
        assert!(result.is_ok());

        let battle_result = result.unwrap();
        assert_eq!(battle_result.skill_used.name, "テスト技");
        assert!(battle_result.final_damage >= 100); // ボーナス込み
    }

    #[test]
    fn skill_execution_failure() {
        let party = BattleParty::new("souma", "yuzuki");
        let coop_skill = BattleSkill::new("協力技", SkillType::Cooperation, 200, "親密時限定");

        let result = party.execute_skill(&coop_skill);
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("使用できません"));
    }

    #[test]
    fn relationship_bonus_calculation() {
        let mut party = BattleParty::new("souma", "yuzuki");

        // 関係値を親密レベルまで上げる
        party.relationship.modify(75);
        assert_eq!(party.relationship.level(), RelationshipLevel::Intimate);

        let coop_skill = BattleSkill::new("協力技", SkillType::Cooperation, 100, "協力技");
        let result = party.execute_skill(&coop_skill).unwrap();

        // ボーナスが適用されて150ダメージになることを確認
        assert_eq!(result.final_damage, 150);
        assert_eq!(result.relationship_bonus, 0.5);
        assert!(result.is_cooperative_attack);
    }
}
