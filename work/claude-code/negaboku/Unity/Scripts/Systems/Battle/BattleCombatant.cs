using System;
using System.Collections.Generic;
using UnityEngine;
using NegabokuRPG.Data;
using NegabokuRPG.Characters;

namespace NegabokuRPG.Systems
{
    /// <summary>
    /// バトル戦闘参加者の基底クラス
    /// </summary>
    [Serializable]
    public abstract class BattleCombatant
    {
        [Header("基本ステータス")]
        [SerializeField] protected string characterId;
        [SerializeField] protected string characterName;
        [SerializeField] protected int currentHP;
        [SerializeField] protected int maxHP;
        [SerializeField] protected int currentMP;
        [SerializeField] protected int maxMP;
        [SerializeField] protected int attack;
        [SerializeField] protected int defense;
        [SerializeField] protected int speed;

        [Header("状態")]
        [SerializeField] protected List<BattleStatusEffect> statusEffects = new List<BattleStatusEffect>();

        // プロパティ
        public string CharacterId => characterId;
        public string CharacterName => characterName;
        public int CurrentHP => currentHP;
        public int MaxHP => maxHP;
        public int CurrentMP => currentMP;
        public int MaxMP => maxMP;
        public int Attack => GetModifiedStat("Attack");
        public int Defense => GetModifiedStat("Defense");
        public int Speed => GetModifiedStat("Speed");
        public bool IsDefeated => currentHP <= 0;
        public List<BattleStatusEffect> StatusEffects => statusEffects;

        // イベント
        public event Action<int, int> OnHPChanged;
        public event Action<int, int> OnMPChanged;
        public event Action<BattleStatusEffect> OnStatusEffectAdded;
        public event Action<BattleStatusEffect> OnStatusEffectRemoved;

        /// <summary>
        /// HPを変更
        /// </summary>
        public virtual void ModifyHP(int amount)
        {
            int oldHP = currentHP;
            currentHP = Mathf.Clamp(currentHP + amount, 0, maxHP);
            
            if (oldHP != currentHP)
            {
                OnHPChanged?.Invoke(currentHP, maxHP);
            }
        }

        /// <summary>
        /// MPを変更
        /// </summary>
        public virtual void ModifyMP(int amount)
        {
            int oldMP = currentMP;
            currentMP = Mathf.Clamp(currentMP + amount, 0, maxMP);
            
            if (oldMP != currentMP)
            {
                OnMPChanged?.Invoke(currentMP, maxMP);
            }
        }

        /// <summary>
        /// ステータス効果を追加
        /// </summary>
        public virtual void AddStatusEffect(StatusEffectType effectType, int value, int duration)
        {
            // 既存の同じ効果を探す
            var existingEffect = statusEffects.Find(e => e.effectType == effectType);
            
            if (existingEffect != null)
            {
                // 既存効果を更新（より強い効果、またはより長い持続時間を採用）
                if (value > existingEffect.value || duration > existingEffect.remainingTurns)
                {
                    existingEffect.value = Mathf.Max(existingEffect.value, value);
                    existingEffect.remainingTurns = Mathf.Max(existingEffect.remainingTurns, duration);
                }
            }
            else
            {
                // 新しい効果を追加
                var newEffect = new BattleStatusEffect
                {
                    effectType = effectType,
                    value = value,
                    duration = duration,
                    remainingTurns = duration
                };
                
                statusEffects.Add(newEffect);
                OnStatusEffectAdded?.Invoke(newEffect);
            }
        }

        /// <summary>
        /// ステータス効果を削除
        /// </summary>
        public virtual void RemoveStatusEffect(BattleStatusEffect effect)
        {
            if (statusEffects.Remove(effect))
            {
                OnStatusEffectRemoved?.Invoke(effect);
            }
        }

        /// <summary>
        /// ステータス効果のターン処理
        /// </summary>
        public virtual void ProcessStatusEffects()
        {
            for (int i = statusEffects.Count - 1; i >= 0; i--)
            {
                var effect = statusEffects[i];
                
                // 効果を適用
                ApplyStatusEffect(effect);
                
                // 持続ターンを減少
                effect.remainingTurns--;
                
                // 効果終了チェック
                if (effect.remainingTurns <= 0)
                {
                    RemoveStatusEffect(effect);
                }
            }
        }

        /// <summary>
        /// ステータス効果を適用
        /// </summary>
        protected virtual void ApplyStatusEffect(BattleStatusEffect effect)
        {
            switch (effect.effectType)
            {
                case StatusEffectType.Poison:
                    ModifyHP(-effect.value);
                    break;
                case StatusEffectType.Regeneration:
                    ModifyHP(effect.value);
                    break;
                // 他の効果はGetModifiedStatで処理
            }
        }

        /// <summary>
        /// ステータス効果を考慮したステータス値を取得
        /// </summary>
        protected virtual int GetModifiedStat(string statName)
        {
            int baseStat = 0;
            
            switch (statName)
            {
                case "Attack":
                    baseStat = attack;
                    break;
                case "Defense":
                    baseStat = defense;
                    break;
                case "Speed":
                    baseStat = speed;
                    break;
                default:
                    return 0;
            }

            float modifier = 1.0f;
            
            foreach (var effect in statusEffects)
            {
                switch (effect.effectType)
                {
                    case StatusEffectType.AttackUp when statName == "Attack":
                        modifier += effect.value * 0.01f;
                        break;
                    case StatusEffectType.AttackDown when statName == "Attack":
                        modifier -= effect.value * 0.01f;
                        break;
                    case StatusEffectType.DefenseUp when statName == "Defense":
                        modifier += effect.value * 0.01f;
                        break;
                    case StatusEffectType.DefenseDown when statName == "Defense":
                        modifier -= effect.value * 0.01f;
                        break;
                    case StatusEffectType.SpeedUp when statName == "Speed":
                        modifier += effect.value * 0.01f;
                        break;
                    case StatusEffectType.SpeedDown when statName == "Speed":
                        modifier -= effect.value * 0.01f;
                        break;
                }
            }

            return Mathf.RoundToInt(baseStat * modifier);
        }

        /// <summary>
        /// 特定のステータス効果を持っているかチェック
        /// </summary>
        public bool HasStatusEffect(StatusEffectType effectType)
        {
            return statusEffects.Exists(e => e.effectType == effectType);
        }

        /// <summary>
        /// 特定のステータス効果を取得
        /// </summary>
        public BattleStatusEffect GetStatusEffect(StatusEffectType effectType)
        {
            return statusEffects.Find(e => e.effectType == effectType);
        }

        /// <summary>
        /// 行動可能判定
        /// </summary>
        public virtual bool CanAct()
        {
            if (IsDefeated) return false;
            if (HasStatusEffect(StatusEffectType.Sleep)) return false;
            if (HasStatusEffect(StatusEffectType.Paralysis))
            {
                // 麻痺は確率で行動不能
                return UnityEngine.Random.value > 0.5f;
            }
            return true;
        }

        /// <summary>
        /// 完全回復
        /// </summary>
        public virtual void FullRecover()
        {
            currentHP = maxHP;
            currentMP = maxMP;
            statusEffects.Clear();
            
            OnHPChanged?.Invoke(currentHP, maxHP);
            OnMPChanged?.Invoke(currentMP, maxMP);
        }
    }

    /// <summary>
    /// プレイヤーキャラクターのバトル表現
    /// </summary>
    [Serializable]
    public class BattleCharacter : BattleCombatant
    {
        private PlayerCharacter sourceCharacter;
        private List<SkillData> availableSkills;

        public PlayerCharacter SourceCharacter => sourceCharacter;
        public List<SkillData> AvailableSkills => availableSkills;

        public BattleCharacter(PlayerCharacter character)
        {
            sourceCharacter = character;
            InitializeFromCharacter();
        }

        private void InitializeFromCharacter()
        {
            characterId = sourceCharacter.CharacterId;
            characterName = sourceCharacter.CharacterName;
            
            var stats = sourceCharacter.CurrentStats;
            maxHP = stats.MaxHP;
            maxMP = stats.MaxMP;
            currentHP = sourceCharacter.CurrentHP;
            currentMP = sourceCharacter.CurrentMP;
            attack = stats.Attack;
            defense = stats.Defense;
            speed = stats.Speed;

            availableSkills = new List<SkillData>(sourceCharacter.AvailableSkills);
        }

        /// <summary>
        /// 使用可能なスキルを取得
        /// </summary>
        public List<SkillData> GetUsableSkills()
        {
            return availableSkills.FindAll(skill => 
                currentMP >= skill.mpCost && 
                sourceCharacter.Level >= skill.requiredLevel);
        }

        /// <summary>
        /// スキルが使用可能かチェック
        /// </summary>
        public bool CanUseSkill(SkillData skill)
        {
            return availableSkills.Contains(skill) && 
                   currentMP >= skill.mpCost && 
                   sourceCharacter.Level >= skill.requiredLevel;
        }
    }

    /// <summary>
    /// 敵キャラクターのバトル表現
    /// </summary>
    [Serializable]
    public class BattleEnemy : BattleCombatant
    {
        [Header("敵固有データ")]
        [SerializeField] private int expReward;
        [SerializeField] private int goldReward;
        [SerializeField] private List<string> itemRewards;
        [SerializeField] private List<SkillData> skills;

        public int ExpReward => expReward;
        public int GoldReward => goldReward;
        public List<string> ItemRewards => itemRewards;

        public BattleEnemy(BattleEnemyData enemyData)
        {
            InitializeFromData(enemyData);
        }

        private void InitializeFromData(BattleEnemyData enemyData)
        {
            characterId = enemyData.enemyId;
            characterName = enemyData.enemyName;
            maxHP = currentHP = enemyData.hp;
            maxMP = currentMP = enemyData.mp;
            attack = enemyData.attack;
            defense = enemyData.defense;
            speed = enemyData.speed;
            expReward = enemyData.expReward;
            goldReward = enemyData.goldReward;
            itemRewards = new List<string>(enemyData.itemRewards);
            skills = new List<SkillData>(enemyData.skills);
        }

        /// <summary>
        /// 使用可能なスキルを取得
        /// </summary>
        public List<SkillData> GetUsableSkills()
        {
            return skills.FindAll(skill => currentMP >= skill.mpCost);
        }
    }

    /// <summary>
    /// バトル用ステータス効果
    /// </summary>
    [Serializable]
    public class BattleStatusEffect
    {
        public StatusEffectType effectType;
        public int value;
        public int duration;
        public int remainingTurns;
        public string sourceSkillId;
    }

    /// <summary>
    /// 敵データ（ScriptableObject用）
    /// </summary>
    [CreateAssetMenu(fileName = "New Enemy", menuName = "NegabokuRPG/Battle Enemy Data")]
    [Serializable]
    public class BattleEnemyData : ScriptableObject
    {
        [Header("基本情報")]
        public string enemyId;
        public string enemyName;
        public string description;
        public Sprite enemySprite;
        public GameObject enemyModel;

        [Header("ステータス")]
        public int hp = 100;
        public int mp = 30;
        public int attack = 15;
        public int defense = 10;
        public int speed = 10;

        [Header("報酬")]
        public int expReward = 50;
        public int goldReward = 25;
        public List<string> itemRewards = new List<string>();

        [Header("スキル")]
        public List<SkillData> skills = new List<SkillData>();

        [Header("AI設定")]
        public float skillUsageRate = 0.3f;
        public List<AIBehavior> aiBehaviors = new List<AIBehavior>();

        private void OnValidate()
        {
            if (string.IsNullOrEmpty(enemyId))
                enemyId = name.ToLower().Replace(" ", "_");
        }
    }

    /// <summary>
    /// AI行動パターン
    /// </summary>
    [Serializable]
    public class AIBehavior
    {
        public AICondition condition;
        public SkillData skill;
        public float priority = 1.0f;
    }

    /// <summary>
    /// AI発動条件
    /// </summary>
    public enum AICondition
    {
        Always,
        LowHP,
        HighHP,
        LowMP,
        HighMP,
        FirstTurn,
        LastTurn,
        EnemyLowHP,
        EnemyHighHP
    }
}