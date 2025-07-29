using System;
using System.Collections.Generic;
using UnityEngine;

namespace NegabokuRPG.Data
{
    [CreateAssetMenu(fileName = "New Character", menuName = "NegabokuRPG/Character Data")]
    [Serializable]
    public class CharacterData : ScriptableObject
    {
        [Header("基本情報")]
        public string characterId;
        public string characterName;
        public string description;
        public Sprite portrait;
        public GameObject characterModel;
        public bool isDLC = false;

        [Header("ステータス")]
        public int baseLevel = 1;
        public int baseHP = 100;
        public int baseMP = 30;
        public int baseAttack = 15;
        public int baseDefense = 10;
        public int baseSpeed = 10;

        [Header("成長率")]
        public float hpGrowthRate = 1.2f;
        public float mpGrowthRate = 1.1f;
        public float attackGrowthRate = 1.15f;
        public float defenseGrowthRate = 1.1f;
        public float speedGrowthRate = 1.05f;

        [Header("初期関係値")]
        public List<RelationshipDefault> defaultRelationships = new List<RelationshipDefault>();

        [Header("初期スキル")]
        public List<SkillData> baseSkills = new List<SkillData>();

        [Header("アニメーション")]
        public RuntimeAnimatorController animatorController;
        
        [Header("音声")]
        public List<AudioClip> voiceClips = new List<AudioClip>();

        /// <summary>
        /// レベルに応じたステータスを計算
        /// </summary>
        public CharacterStats CalculateStatsAtLevel(int level)
        {
            return new CharacterStats
            {
                Level = level,
                MaxHP = Mathf.RoundToInt(baseHP * Mathf.Pow(hpGrowthRate, level - 1)),
                MaxMP = Mathf.RoundToInt(baseMP * Mathf.Pow(mpGrowthRate, level - 1)),
                Attack = Mathf.RoundToInt(baseAttack * Mathf.Pow(attackGrowthRate, level - 1)),
                Defense = Mathf.RoundToInt(baseDefense * Mathf.Pow(defenseGrowthRate, level - 1)),
                Speed = Mathf.RoundToInt(baseSpeed * Mathf.Pow(speedGrowthRate, level - 1))
            };
        }

        /// <summary>
        /// 指定したキャラクターとの初期関係値を取得
        /// </summary>
        public int GetDefaultRelationshipWith(string targetCharacterId)
        {
            var relationship = defaultRelationships.Find(r => r.targetCharacterId == targetCharacterId);
            return relationship?.value ?? 50; // デフォルト値は50
        }

        private void OnValidate()
        {
            // エディタでの検証
            if (string.IsNullOrEmpty(characterId))
                characterId = name.ToLower().Replace(" ", "_");
        }
    }

    [Serializable]
    public class RelationshipDefault
    {
        public string targetCharacterId;
        [Range(-25, 100)]
        public int value = 50;
    }

    [Serializable]
    public struct CharacterStats
    {
        public int Level;
        public int MaxHP;
        public int MaxMP;
        public int Attack;
        public int Defense;
        public int Speed;
    }
}