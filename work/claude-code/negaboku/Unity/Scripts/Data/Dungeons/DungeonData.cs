using System;
using System.Collections.Generic;
using UnityEngine;
using NegabokuRPG.Systems;

namespace NegabokuRPG.Data
{
    [CreateAssetMenu(fileName = "New Dungeon", menuName = "NegabokuRPG/Dungeon Data")]
    [Serializable]
    public class DungeonData : ScriptableObject
    {
        [Header("基本情報")]
        public string dungeonId;
        public string dungeonName;
        public string description;
        public Sprite dungeonIcon;
        public Texture2D mapTexture;

        [Header("解放条件")]
        public int requiredOrbs = 0;
        public List<string> requiredClearedDungeons = new List<string>();
        public bool isUnlockedByDefault = false;

        [Header("ダンジョン設定")]
        public DungeonDifficulty difficulty = DungeonDifficulty.Normal;
        public int maxFloors = 5;
        public List<DungeonFloorData> floors = new List<DungeonFloorData>();

        [Header("報酬")]
        public List<DungeonReward> clearRewards = new List<DungeonReward>();
        public string unlockedDungeonId; // クリア時に解放されるダンジョン

        [Header("音楽・演出")]
        public AudioClip bgmClip;
        public GameObject dungeonEnvironment;
        public Material skyboxMaterial;

        /// <summary>
        /// 指定フロアのデータを取得
        /// </summary>
        public DungeonFloorData GetFloorData(int floorNumber)
        {
            return floors.Find(f => f.floorNumber == floorNumber);
        }

        /// <summary>
        /// ダンジョンが解放可能かチェック
        /// </summary>
        public bool CanUnlock(List<string> clearedDungeons, int currentOrbs)
        {
            if (isUnlockedByDefault) return true;
            if (currentOrbs < requiredOrbs) return false;

            foreach (var requiredDungeon in requiredClearedDungeons)
            {
                if (!clearedDungeons.Contains(requiredDungeon))
                    return false;
            }

            return true;
        }

        private void OnValidate()
        {
            if (string.IsNullOrEmpty(dungeonId))
                dungeonId = name.ToLower().Replace(" ", "_");

            // フロアデータの整合性チェック
            for (int i = 0; i < floors.Count; i++)
            {
                if (floors[i].floorNumber != i + 1)
                    floors[i].floorNumber = i + 1;
            }
        }
    }

    [Serializable]
    public class DungeonFloorData
    {
        [Header("フロア情報")]
        public int floorNumber = 1;
        public string floorName;
        public string description;
        
        [Header("イベント")]
        public List<DungeonEventData> events = new List<DungeonEventData>();
        
        [Header("戦闘")]
        public List<EnemyEncounter> enemyEncounters = new List<EnemyEncounter>();
        public bool isBossFloor = false;
        public BossEncounter bossEncounter;
        
        [Header("宝箱")]
        public List<TreasureChest> treasures = new List<TreasureChest>();

        [Header("環境")]
        public GameObject floorPrefab;
        public AudioClip floorBGM;
    }

    [Serializable]
    public class DungeonEventData
    {
        [Header("イベント情報")]
        public string eventId;
        public string eventTitle;
        [TextArea(3, 5)]
        public string eventDescription;
        public DungeonEventType eventType = DungeonEventType.Choice;
        
        [Header("発生条件")]
        public List<EventCondition> conditions = new List<EventCondition>();
        
        [Header("選択肢")]
        public List<DungeonChoice> choices = new List<DungeonChoice>();

        [Header("演出")]
        public Sprite eventImage;
        public AudioClip eventSound;
    }

    [Serializable]
    public class DungeonChoice
    {
        public string choiceId;
        [TextArea(2, 3)]
        public string choiceText;
        public string description;
        
        [Header("使用条件")]
        public List<ChoiceRequirement> requirements = new List<ChoiceRequirement>();
        
        [Header("結果")]
        public List<ChoiceConsequence> consequences = new List<ChoiceConsequence>();
    }

    [Serializable]
    public class EventCondition
    {
        public ConditionType conditionType;
        public string targetId;
        public int value;
        public ComparisonType comparison = ComparisonType.GreaterOrEqual;
    }

    [Serializable]
    public class ChoiceRequirement
    {
        public RequirementType requirementType;
        public string targetId;
        public int value;
        public ComparisonType comparison = ComparisonType.GreaterOrEqual;
    }

    [Serializable]
    public class ChoiceConsequence
    {
        public ConsequenceType consequenceType;
        public string targetId;
        public int value;
        public string description;
    }

    [Serializable]
    public class EnemyEncounter
    {
        public string encounterId;
        public List<BattleEnemyData> enemies = new List<BattleEnemyData>();
        [Range(0f, 1f)]
        public float encounterRate = 0.3f;
        public bool canEscape = true;
        [Range(0f, 1f)]
        public float ambushChance = 0.1f;
    }

    [Serializable]
    public class BossEncounter
    {
        public string bossId;
        public BattleEnemyData bossData;
        [TextArea(2, 4)]
        public string preDialogue;
        [TextArea(2, 4)]
        public string postDialogue;
        public List<DungeonReward> specialRewards = new List<DungeonReward>();
        public bool isRequired = true;
    }

    [Serializable]
    public class TreasureChest
    {
        public string treasureId;
        public List<TreasureContent> contents = new List<TreasureContent>();
        public bool isHidden = false;
        public string requiredKeyId;
        [Range(0f, 1f)]
        public float trapChance = 0f;
        public TrapType trapType = TrapType.Damage;
        public int trapValue = 10;
    }

    [Serializable]
    public class TreasureContent
    {
        public string itemId;
        public int quantity = 1;
        [Range(0f, 1f)]
        public float dropRate = 1f;
        public TreasureRarity rarity = TreasureRarity.Common;
    }

    [Serializable]
    public class DungeonReward
    {
        public string itemId;
        public int quantity = 1;
        public bool isGuaranteed = true;
        [Range(0f, 1f)]
        public float dropRate = 1f;
    }

    // 列挙型定義
    [Serializable]
    public enum DungeonDifficulty
    {
        Easy,
        Normal,
        Hard,
        Nightmare
    }

    [Serializable]
    public enum DungeonEventType
    {
        Story,
        Choice,
        Relationship,
        Treasure,
        Trap,
        Rest,
        Merchant,
        Battle
    }

    [Serializable]
    public enum ConditionType
    {
        CharacterLevel,
        RelationshipValue,
        ItemPossession,
        GoldAmount,
        PartyMember,
        StoryFlag,
        Random
    }

    [Serializable]
    public enum RequirementType
    {
        CharacterLevel,
        RelationshipValue,
        ItemPossession,
        GoldAmount,
        PartyMember,
        StoryFlag,
        SkillKnown
    }

    [Serializable]
    public enum ConsequenceType
    {
        HPChange,
        MPChange,
        RelationshipChange,
        GoldChange,
        ItemGain,
        ItemLoss,
        ExperienceGain,
        StatusEffect,
        UnlockSkill,
        SetFlag,
        StartBattle
    }

    [Serializable]
    public enum ComparisonType
    {
        Equal,
        NotEqual,
        Greater,
        GreaterOrEqual,
        Less,
        LessOrEqual
    }

    [Serializable]
    public enum TreasureRarity
    {
        Common,
        Uncommon,
        Rare,
        Epic,
        Legendary
    }

    [Serializable]
    public enum TrapType
    {
        Damage,
        StatusEffect,
        ItemLoss,
        GoldLoss,
        Teleport
    }
}