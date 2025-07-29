using System;
using System.Collections.Generic;
using UnityEngine;
using NegabokuRPG.Data;

namespace NegabokuRPG.Characters
{
    /// <summary>
    /// プレイヤーキャラクターのランタイム表現
    /// </summary>
    [Serializable]
    public class PlayerCharacter : MonoBehaviour
    {
        [Header("キャラクターデータ")]
        [SerializeField] private CharacterData characterData;
        
        [Header("現在のステータス")]
        [SerializeField] private int currentLevel = 1;
        [SerializeField] private int currentHP;
        [SerializeField] private int currentMP;
        [SerializeField] private int currentExp = 0;
        
        [Header("装備・アイテム")]
        [SerializeField] private List<SkillData> availableSkills = new List<SkillData>();
        [SerializeField] private List<StatusEffectInstance> activeStatusEffects = new List<StatusEffectInstance>();

        // プロパティ
        public CharacterData Data => characterData;
        public string CharacterId => characterData?.characterId ?? "";
        public string CharacterName => characterData?.characterName ?? "";
        public int Level => currentLevel;
        public int CurrentHP => currentHP;
        public int CurrentMP => currentMP;
        public int CurrentExp => currentExp;
        public CharacterStats CurrentStats => characterData?.CalculateStatsAtLevel(currentLevel) ?? default;
        public List<SkillData> AvailableSkills => availableSkills;
        public List<StatusEffectInstance> ActiveStatusEffects => activeStatusEffects;

        // イベント
        public event Action<int, int> OnHPChanged;
        public event Action<int, int> OnMPChanged;
        public event Action<int> OnLevelUp;
        public event Action<StatusEffectInstance> OnStatusEffectAdded;
        public event Action<StatusEffectInstance> OnStatusEffectRemoved;

        private void Awake()
        {
            InitializeCharacter();
        }

        /// <summary>
        /// キャラクターデータから初期化
        /// </summary>
        public void InitializeCharacter(CharacterData data = null)
        {
            if (data != null)
                characterData = data;

            if (characterData == null) return;

            // ステータス初期化
            var stats = characterData.CalculateStatsAtLevel(currentLevel);
            currentHP = stats.MaxHP;
            currentMP = stats.MaxMP;

            // 基本スキル追加
            availableSkills.Clear();
            availableSkills.AddRange(characterData.baseSkills);

            // ステータス変更イベント発火
            OnHPChanged?.Invoke(currentHP, stats.MaxHP);
            OnMPChanged?.Invoke(currentMP, stats.MaxMP);
        }

        /// <summary>
        /// HPを変更
        /// </summary>
        public void ModifyHP(int amount)
        {
            var stats = CurrentStats;
            var oldHP = currentHP;
            currentHP = Mathf.Clamp(currentHP + amount, 0, stats.MaxHP);
            
            if (oldHP != currentHP)
            {
                OnHPChanged?.Invoke(currentHP, stats.MaxHP);
            }
        }

        /// <summary>
        /// MPを変更
        /// </summary>
        public void ModifyMP(int amount)
        {
            var stats = CurrentStats;
            var oldMP = currentMP;
            currentMP = Mathf.Clamp(currentMP + amount, 0, stats.MaxMP);
            
            if (oldMP != currentMP)
            {
                OnMPChanged?.Invoke(currentMP, stats.MaxMP);
            }
        }

        /// <summary>
        /// 経験値を追加してレベルアップをチェック
        /// </summary>
        public void AddExperience(int exp)
        {
            currentExp += exp;
            CheckLevelUp();
        }

        /// <summary>
        /// レベルアップの判定と処理
        /// </summary>
        private void CheckLevelUp()
        {
            int expNeeded = CalculateExpNeededForLevel(currentLevel + 1);
            
            while (currentExp >= expNeeded && currentLevel < 99) // 最大レベル99
            {
                LevelUp();
                expNeeded = CalculateExpNeededForLevel(currentLevel + 1);
            }
        }

        /// <summary>
        /// レベルアップ処理
        /// </summary>
        private void LevelUp()
        {
            var oldStats = CurrentStats;
            currentLevel++;
            var newStats = CurrentStats;

            // HPとMPを回復（レベルアップボーナス）
            int hpIncrease = newStats.MaxHP - oldStats.MaxHP;
            int mpIncrease = newStats.MaxMP - oldStats.MaxMP;
            
            ModifyHP(hpIncrease);
            ModifyMP(mpIncrease);

            OnLevelUp?.Invoke(currentLevel);
        }

        /// <summary>
        /// 指定レベルに必要な経験値を計算
        /// </summary>
        private int CalculateExpNeededForLevel(int level)
        {
            return (int)(100 * Mathf.Pow(level, 1.5f));
        }

        /// <summary>
        /// スキルを追加
        /// </summary>
        public void AddSkill(SkillData skill)
        {
            if (!availableSkills.Contains(skill))
            {
                availableSkills.Add(skill);
            }
        }

        /// <summary>
        /// スキルを削除
        /// </summary>
        public void RemoveSkill(SkillData skill)
        {
            availableSkills.Remove(skill);
        }

        /// <summary>
        /// スキルが使用可能かチェック
        /// </summary>
        public bool CanUseSkill(SkillData skill)
        {
            if (!availableSkills.Contains(skill))
                return false;

            if (currentMP < skill.mpCost)
                return false;

            if (currentLevel < skill.requiredLevel)
                return false;

            return true;
        }

        /// <summary>
        /// ステータス効果を追加
        /// </summary>
        public void AddStatusEffect(StatusEffectType effectType, int value, int duration)
        {
            var effect = new StatusEffectInstance
            {
                effectType = effectType,
                value = value,
                duration = duration,
                remainingTurns = duration
            };

            activeStatusEffects.Add(effect);
            OnStatusEffectAdded?.Invoke(effect);
        }

        /// <summary>
        /// ステータス効果を削除
        /// </summary>
        public void RemoveStatusEffect(StatusEffectInstance effect)
        {
            if (activeStatusEffects.Remove(effect))
            {
                OnStatusEffectRemoved?.Invoke(effect);
            }
        }

        /// <summary>
        /// ステータス効果のターン処理
        /// </summary>
        public void ProcessStatusEffects()
        {
            for (int i = activeStatusEffects.Count - 1; i >= 0; i--)
            {
                var effect = activeStatusEffects[i];
                
                // 効果適用
                ApplyStatusEffect(effect);
                
                // 持続ターン減少
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
        private void ApplyStatusEffect(StatusEffectInstance effect)
        {
            switch (effect.effectType)
            {
                case StatusEffectType.Poison:
                    ModifyHP(-effect.value);
                    break;
                case StatusEffectType.Regeneration:
                    ModifyHP(effect.value);
                    break;
                // 他のステータス効果も追加可能
            }
        }

        /// <summary>
        /// 戦闘不能判定
        /// </summary>
        public bool IsDefeated()
        {
            return currentHP <= 0;
        }

        /// <summary>
        /// 完全回復
        /// </summary>
        public void FullRecover()
        {
            var stats = CurrentStats;
            currentHP = stats.MaxHP;
            currentMP = stats.MaxMP;
            activeStatusEffects.Clear();
            
            OnHPChanged?.Invoke(currentHP, stats.MaxHP);
            OnMPChanged?.Invoke(currentMP, stats.MaxMP);
        }

        /// <summary>
        /// セーブデータ用の情報を取得
        /// </summary>
        public CharacterSaveData GetSaveData()
        {
            return new CharacterSaveData
            {
                characterId = CharacterId,
                level = currentLevel,
                currentHP = currentHP,
                currentMP = currentMP,
                currentExp = currentExp,
                availableSkillIds = availableSkills.ConvertAll(s => s.skillId),
                statusEffects = new List<StatusEffectInstance>(activeStatusEffects)
            };
        }

        /// <summary>
        /// セーブデータから復元
        /// </summary>
        public void LoadFromSaveData(CharacterSaveData saveData)
        {
            currentLevel = saveData.level;
            currentHP = saveData.currentHP;
            currentMP = saveData.currentMP;
            currentExp = saveData.currentExp;
            
            // スキルの復元は外部で行う（SkillData参照が必要）
            activeStatusEffects = new List<StatusEffectInstance>(saveData.statusEffects);
        }
    }

    [Serializable]
    public class StatusEffectInstance
    {
        public StatusEffectType effectType;
        public int value;
        public int duration;
        public int remainingTurns;
        public string sourceSkillId;
    }

    [Serializable]
    public class CharacterSaveData
    {
        public string characterId;
        public int level;
        public int currentHP;
        public int currentMP;
        public int currentExp;
        public List<string> availableSkillIds;
        public List<StatusEffectInstance> statusEffects;
    }
}