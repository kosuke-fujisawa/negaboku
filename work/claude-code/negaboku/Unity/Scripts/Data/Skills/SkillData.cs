using System;
using System.Collections.Generic;
using UnityEngine;

namespace NegabokuRPG.Data
{
    [CreateAssetMenu(fileName = "New Skill", menuName = "NegabokuRPG/Skill Data")]
    [Serializable]
    public class SkillData : ScriptableObject
    {
        [Header("基本情報")]
        public string skillId;
        public string skillName;
        public string description;
        public Sprite icon;
        public SkillType skillType = SkillType.Normal;

        [Header("効果")]
        public int basePower = 20;
        public int mpCost = 0;
        public TargetType targetType = TargetType.SingleEnemy;
        public List<StatusEffectData> statusEffects = new List<StatusEffectData>();

        [Header("使用条件")]
        public int requiredLevel = 1;
        public List<string> requiredCharacterIds = new List<string>();
        [Range(0, 100)]
        public int requiredRelationshipValue = 50;

        [Header("演出")]
        public GameObject skillEffect;
        public AudioClip skillSound;
        public AnimationClip skillAnimation;
        public float animationDuration = 1.0f;

        [Header("AI設定")]
        public int aiPriority = 1;
        public float aiUsageRate = 1.0f;

        /// <summary>
        /// スキルが使用可能かチェック
        /// </summary>
        public bool CanUse(CharacterData caster, List<CharacterData> party, Dictionary<string, Dictionary<string, int>> relationships)
        {
            // レベル条件チェック
            if (caster.baseLevel < requiredLevel)
                return false;

            // MP条件チェック（実際のMPは実行時にチェック）

            // 通常スキルは常に使用可能
            if (skillType == SkillType.Normal)
                return true;

            // 必要キャラクターがパーティにいるかチェック
            if (requiredCharacterIds.Count > 0)
            {
                foreach (var requiredCharId in requiredCharacterIds)
                {
                    if (!party.Exists(c => c.characterId == requiredCharId))
                        return false;
                }
            }

            // 関係値条件チェック
            if (requiredCharacterIds.Count >= 2 && relationships != null)
            {
                var char1 = requiredCharacterIds[0];
                var char2 = requiredCharacterIds[1];

                if (relationships.ContainsKey(char1) && relationships[char1].ContainsKey(char2))
                {
                    var relationshipValue = relationships[char1][char2];

                    switch (skillType)
                    {
                        case SkillType.Cooperation:
                            return relationshipValue >= requiredRelationshipValue;
                        case SkillType.Conflict:
                            return relationshipValue <= requiredRelationshipValue;
                    }
                }
            }

            return true;
        }

        /// <summary>
        /// 関係値による威力修正を計算
        /// </summary>
        public float CalculatePowerModifier(Dictionary<string, Dictionary<string, int>> relationships)
        {
            float modifier = 1.0f;

            if (requiredCharacterIds.Count >= 2 && relationships != null)
            {
                var char1 = requiredCharacterIds[0];
                var char2 = requiredCharacterIds[1];

                if (relationships.ContainsKey(char1) && relationships[char1].ContainsKey(char2))
                {
                    var relationshipValue = relationships[char1][char2];

                    switch (skillType)
                    {
                        case SkillType.Cooperation:
                            modifier = 1.0f + (relationshipValue - 70) * 0.01f;
                            modifier = Mathf.Clamp(modifier, 1.0f, 1.5f);
                            break;
                        case SkillType.Conflict:
                            modifier = 1.0f + (30 - relationshipValue) * 0.015f;
                            modifier = Mathf.Clamp(modifier, 1.0f, 1.4f);
                            break;
                    }
                }
            }

            return modifier;
        }

        private void OnValidate()
        {
            if (string.IsNullOrEmpty(skillId))
                skillId = name.ToLower().Replace(" ", "_");
        }
    }

    [Serializable]
    public enum SkillType
    {
        Normal,      // 通常技
        Cooperation, // 共闘技
        Conflict     // 対立技
    }

    [Serializable]
    public enum TargetType
    {
        Self,           // 自分
        SingleAlly,     // 味方単体
        AllAllies,      // 味方全体
        SingleEnemy,    // 敵単体
        AllEnemies,     // 敵全体
        Random,         // ランダム
        All             // 全体
    }

    [Serializable]
    public class StatusEffectData
    {
        public StatusEffectType effectType;
        public int value;
        public int duration;
        public string description;
    }

    [Serializable]
    public enum StatusEffectType
    {
        None,
        Poison,
        Paralysis,
        Sleep,
        Confusion,
        AttackUp,
        DefenseUp,
        SpeedUp,
        AttackDown,
        DefenseDown,
        SpeedDown,
        Regeneration,
        Barrier
    }
}