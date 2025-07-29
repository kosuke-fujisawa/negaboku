using System;
using System.Collections.Generic;
using UnityEngine;
using NegabokuRPG.Data;

namespace NegabokuRPG.Systems
{
    /// <summary>
    /// 関係値システム - シングルトン
    /// </summary>
    public class RelationshipSystem : MonoBehaviour
    {
        private static RelationshipSystem instance;
        public static RelationshipSystem Instance
        {
            get
            {
                if (instance == null)
                {
                    instance = FindObjectOfType<RelationshipSystem>();
                    if (instance == null)
                    {
                        var go = new GameObject("RelationshipSystem");
                        instance = go.AddComponent<RelationshipSystem>();
                        DontDestroyOnLoad(go);
                    }
                }
                return instance;
            }
        }

        [Header("関係値設定")]
        [SerializeField] private int minRelationshipValue = 0;
        [SerializeField] private int maxRelationshipValue = 100;
        [SerializeField] private int defaultRelationshipValue = 50;

        // 関係値データ [キャラクターID][対象キャラクターID] = 関係値
        private Dictionary<string, Dictionary<string, int>> relationships = new Dictionary<string, Dictionary<string, int>>();

        // イベント
        public event Action<string, string, int, int> OnRelationshipChanged; // (character1, character2, oldValue, newValue)
        public event Action<string, string, RelationshipLevel> OnRelationshipLevelChanged;

        private void Awake()
        {
            if (instance == null)
            {
                instance = this;
                DontDestroyOnLoad(gameObject);
            }
            else if (instance != this)
            {
                Destroy(gameObject);
            }
        }

        /// <summary>
        /// キャラクターデータから関係値を初期化
        /// </summary>
        public void InitializeRelationships(List<CharacterData> characters)
        {
            relationships.Clear();

            foreach (var character in characters)
            {
                if (!relationships.ContainsKey(character.characterId))
                {
                    relationships[character.characterId] = new Dictionary<string, int>();
                }

                // 他の全キャラクターとの関係値を設定
                foreach (var otherCharacter in characters)
                {
                    if (character.characterId != otherCharacter.characterId)
                    {
                        int defaultValue = character.GetDefaultRelationshipWith(otherCharacter.characterId);
                        relationships[character.characterId][otherCharacter.characterId] = defaultValue;
                    }
                }
            }
        }

        /// <summary>
        /// 関係値を取得
        /// </summary>
        public int GetRelationshipValue(string character1Id, string character2Id)
        {
            if (relationships.ContainsKey(character1Id) && 
                relationships[character1Id].ContainsKey(character2Id))
            {
                return relationships[character1Id][character2Id];
            }
            return defaultRelationshipValue;
        }

        /// <summary>
        /// 関係値を設定
        /// </summary>
        public void SetRelationshipValue(string character1Id, string character2Id, int value)
        {
            int oldValue = GetRelationshipValue(character1Id, character2Id);
            int newValue = Mathf.Clamp(value, minRelationshipValue, maxRelationshipValue);

            if (!relationships.ContainsKey(character1Id))
            {
                relationships[character1Id] = new Dictionary<string, int>();
            }

            relationships[character1Id][character2Id] = newValue;

            if (oldValue != newValue)
            {
                OnRelationshipChanged?.Invoke(character1Id, character2Id, oldValue, newValue);

                // レベル変化もチェック
                var oldLevel = GetRelationshipLevel(oldValue);
                var newLevel = GetRelationshipLevel(newValue);
                if (oldLevel != newLevel)
                {
                    OnRelationshipLevelChanged?.Invoke(character1Id, character2Id, newLevel);
                }
            }
        }

        /// <summary>
        /// 関係値を変更（相対値）
        /// </summary>
        public void ModifyRelationshipValue(string character1Id, string character2Id, int change)
        {
            int currentValue = GetRelationshipValue(character1Id, character2Id);
            SetRelationshipValue(character1Id, character2Id, currentValue + change);
        }

        /// <summary>
        /// 双方向の関係値を変更
        /// </summary>
        public void ModifyMutualRelationship(string character1Id, string character2Id, int change)
        {
            ModifyRelationshipValue(character1Id, character2Id, change);
            ModifyRelationshipValue(character2Id, character1Id, change);
        }

        /// <summary>
        /// 関係値レベルを取得
        /// </summary>
        public RelationshipLevel GetRelationshipLevel(int relationshipValue)
        {
            if (relationshipValue >= 80) return RelationshipLevel.Intimate;
            if (relationshipValue >= 60) return RelationshipLevel.Friendly;
            if (relationshipValue >= 40) return RelationshipLevel.Neutral;
            if (relationshipValue >= 20) return RelationshipLevel.Cold;
            return RelationshipLevel.Hostile;
        }

        /// <summary>
        /// 関係値レベルを取得（キャラクター指定）
        /// </summary>
        public RelationshipLevel GetRelationshipLevel(string character1Id, string character2Id)
        {
            int value = GetRelationshipValue(character1Id, character2Id);
            return GetRelationshipLevel(value);
        }

        /// <summary>
        /// 共闘技が使用可能かチェック
        /// </summary>
        public bool CanUseCooperationSkill(string character1Id, string character2Id, int requiredValue = 70)
        {
            return GetRelationshipValue(character1Id, character2Id) >= requiredValue;
        }

        /// <summary>
        /// 対立技が使用可能かチェック
        /// </summary>
        public bool CanUseConflictSkill(string character1Id, string character2Id, int requiredValue = 30)
        {
            return GetRelationshipValue(character1Id, character2Id) <= requiredValue;
        }

        /// <summary>
        /// バトルイベントを処理
        /// </summary>
        public void HandleBattleEvent(BattleEventType eventType, string character1Id, string character2Id = null)
        {
            if (string.IsNullOrEmpty(character2Id)) return;

            switch (eventType)
            {
                case BattleEventType.Cooperation:
                    ModifyMutualRelationship(character1Id, character2Id, 2);
                    break;
                case BattleEventType.FriendlyFire:
                    ModifyMutualRelationship(character1Id, character2Id, -3);
                    break;
                case BattleEventType.Protection:
                    ModifyRelationshipValue(character2Id, character1Id, 3); // 守られた側が守った側を好きになる
                    ModifyRelationshipValue(character1Id, character2Id, 1);  // 守った側も少し上がる
                    break;
                case BattleEventType.Rivalry:
                    ModifyMutualRelationship(character1Id, character2Id, -1);
                    break;
                case BattleEventType.Support:
                    ModifyMutualRelationship(character1Id, character2Id, 1);
                    break;
            }
        }

        /// <summary>
        /// パーティ全体の平均関係値を計算
        /// </summary>
        public float CalculateAverageRelationship(List<string> partyCharacterIds)
        {
            if (partyCharacterIds.Count < 2) return defaultRelationshipValue;

            int total = 0;
            int count = 0;

            for (int i = 0; i < partyCharacterIds.Count; i++)
            {
                for (int j = i + 1; j < partyCharacterIds.Count; j++)
                {
                    total += GetRelationshipValue(partyCharacterIds[i], partyCharacterIds[j]);
                    count++;
                }
            }

            return count > 0 ? (float)total / count : defaultRelationshipValue;
        }

        /// <summary>
        /// 指定キャラクターの全関係値を取得
        /// </summary>
        public Dictionary<string, int> GetAllRelationshipsFor(string characterId)
        {
            if (relationships.ContainsKey(characterId))
            {
                return new Dictionary<string, int>(relationships[characterId]);
            }
            return new Dictionary<string, int>();
        }

        /// <summary>
        /// 全関係値データを取得
        /// </summary>
        public Dictionary<string, Dictionary<string, int>> GetAllRelationships()
        {
            var result = new Dictionary<string, Dictionary<string, int>>();
            foreach (var kvp in relationships)
            {
                result[kvp.Key] = new Dictionary<string, int>(kvp.Value);
            }
            return result;
        }

        /// <summary>
        /// セーブデータから関係値を復元
        /// </summary>
        public void LoadRelationships(Dictionary<string, Dictionary<string, int>> savedRelationships)
        {
            relationships.Clear();
            foreach (var kvp in savedRelationships)
            {
                relationships[kvp.Key] = new Dictionary<string, int>(kvp.Value);
            }
        }

        /// <summary>
        /// デバッグ用：関係値を表示
        /// </summary>
        [ContextMenu("Debug Print Relationships")]
        public void DebugPrintRelationships()
        {
            foreach (var character1 in relationships.Keys)
            {
                foreach (var character2 in relationships[character1].Keys)
                {
                    int value = relationships[character1][character2];
                    var level = GetRelationshipLevel(value);
                    Debug.Log($"{character1} → {character2}: {value} ({level})");
                }
            }
        }
    }

    /// <summary>
    /// 関係値レベル
    /// </summary>
    public enum RelationshipLevel
    {
        Hostile,    // 敵対 (0-19)
        Cold,       // 冷淡 (20-39)
        Neutral,    // 普通 (40-59)
        Friendly,   // 友好 (60-79)
        Intimate    // 親密 (80-100)
    }

    /// <summary>
    /// バトルイベントタイプ
    /// </summary>
    public enum BattleEventType
    {
        Cooperation,    // 協力
        FriendlyFire,   // 誤射
        Protection,     // 庇う
        Rivalry,        // 対立
        Support         // 支援
    }
}