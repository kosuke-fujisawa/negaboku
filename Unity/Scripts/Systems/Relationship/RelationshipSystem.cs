using System;
using System.Collections.Generic;
using UnityEngine;
using NegabokuRPG.Data;
using NegabokuRPG.Utilities;

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

        [Header("関係値設定 - 5段階システム")]
        [SerializeField] private int minRelationshipValue = RelationshipConstants.MIN_VALUE;
        [SerializeField] private int maxRelationshipValue = RelationshipConstants.MAX_VALUE;
        [SerializeField] private int defaultRelationshipValue = RelationshipConstants.DEFAULT_VALUE;
        [SerializeField] private int relationshipStep = RelationshipConstants.STEP_SIZE;

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
        /// 関係値を取得（パフォーマンス最適化版）
        /// </summary>
        public int GetRelationshipValue(string character1Id, string character2Id)
        {
            if (relationships.TryGetValue(character1Id, out var char1Relations) &&
                char1Relations.TryGetValue(character2Id, out var value))
            {
                return value;
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
        /// 関係値を25刻みで変更（1段階または半段階の変動）
        /// </summary>
        public void ModifyRelationshipByStep(string character1Id, string character2Id, float steps)
        {
            int change = Mathf.RoundToInt(relationshipStep * steps);
            ModifyRelationshipValue(character1Id, character2Id, change);
        }

        /// <summary>
        /// 双方向の関係値を25刻みで変更
        /// </summary>
        public void ModifyMutualRelationshipByStep(string character1Id, string character2Id, float steps)
        {
            ModifyRelationshipByStep(character1Id, character2Id, steps);
            ModifyRelationshipByStep(character2Id, character1Id, steps);
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
        /// 関係値レベルを取得（5段階システム: -25～100を25刻み）
        /// </summary>
        public RelationshipLevel GetRelationshipLevel(int relationshipValue)
        {
            if (relationshipValue >= RelationshipConstants.INTIMATE_THRESHOLD) return RelationshipLevel.Intimate;
            if (relationshipValue >= RelationshipConstants.FRIENDLY_THRESHOLD) return RelationshipLevel.Friendly;
            if (relationshipValue >= RelationshipConstants.NEUTRAL_THRESHOLD) return RelationshipLevel.Neutral;
            if (relationshipValue >= RelationshipConstants.COLD_THRESHOLD) return RelationshipLevel.Cold;
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
        /// 共闘技が使用可能かチェック（親密レベル: 76以上で発動）
        /// </summary>
        public bool CanUseCooperationSkill(string character1Id, string character2Id)
        {
            return GetRelationshipValue(character1Id, character2Id) >= RelationshipConstants.COOPERATION_THRESHOLD;
        }

        /// <summary>
        /// 対立技が使用可能かチェック（敵対レベル: 0以下で発動）
        /// </summary>
        public bool CanUseConflictSkill(string character1Id, string character2Id)
        {
            return GetRelationshipValue(character1Id, character2Id) <= RelationshipConstants.CONFLICT_THRESHOLD;
        }

        /// <summary>
        /// バトルイベントを処理（25刻みシステムに対応）
        /// </summary>
        public void HandleBattleEvent(BattleEventType eventType, string character1Id, string character2Id = null)
        {
            if (string.IsNullOrEmpty(character2Id)) return;

            switch (eventType)
            {
                case BattleEventType.Cooperation:
                    // 大きな協力: +25 (1段階アップ)
                    ModifyMutualRelationship(character1Id, character2Id, RelationshipConstants.LARGE_POSITIVE_CHANGE);
                    break;
                case BattleEventType.FriendlyFire:
                    // 大きな対立: -25 (1段階ダウン)
                    ModifyMutualRelationship(character1Id, character2Id, RelationshipConstants.LARGE_NEGATIVE_CHANGE);
                    break;
                case BattleEventType.Protection:
                    // 守られた側: +25, 守った側: +12 (半段階)
                    ModifyRelationshipValue(character2Id, character1Id, RelationshipConstants.PROTECTION_BENEFICIARY_CHANGE);
                    ModifyRelationshipValue(character1Id, character2Id, RelationshipConstants.PROTECTION_PROTECTOR_CHANGE);
                    break;
                case BattleEventType.Rivalry:
                    // 小さな対立: -12 (半段階ダウン)
                    ModifyMutualRelationship(character1Id, character2Id, RelationshipConstants.SMALL_NEGATIVE_CHANGE);
                    break;
                case BattleEventType.Support:
                    // 小さな協力: +12 (半段階アップ)
                    ModifyMutualRelationship(character1Id, character2Id, RelationshipConstants.SMALL_POSITIVE_CHANGE);
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

        /// <summary>
        /// 5段階関係値システムのテスト（CLAUDE.md指定）
        /// </summary>
        [ContextMenu("Test 5-Level Relationship System")]
        public void TestRelationshipSystem()
        {
            // テスト用キャラクター追加
            string char1 = "test_char1";
            string char2 = "test_char2";
            
            // 初期値設定（普通レベル）
            SetRelationshipValue(char1, char2, 50);
            Debug.Log($"初期関係値: {GetRelationshipValue(char1, char2)} (レベル: {GetRelationshipLevel(char1, char2)})");
            
            // 段階的な関係値変動テスト
            ModifyRelationshipByStep(char1, char2, 1f); // +25 (1段階アップ)
            Debug.Log($"1段階アップ後: {GetRelationshipValue(char1, char2)} (レベル: {GetRelationshipLevel(char1, char2)})");
            
            ModifyRelationshipByStep(char1, char2, 0.5f); // +12 (半段階アップ)
            Debug.Log($"半段階アップ後: {GetRelationshipValue(char1, char2)} (レベル: {GetRelationshipLevel(char1, char2)})");
            
            // 各段階のスキル発動テスト
            Debug.Log($"共闘技使用可能: {CanUseCooperationSkill(char1, char2)}");
            Debug.Log($"対立技使用可能: {CanUseConflictSkill(char1, char2)}");
        }

        /// <summary>
        /// 各段階のスキル発動テスト
        /// </summary>
        [ContextMenu("Test Skill Activation by Level")]
        public void TestSkillActivation()
        {
            string char1 = "test_char1";
            string char2 = "test_char2";
            
            // 親密レベルでの共闘技テスト
            SetRelationshipValue(char1, char2, 100);
            Debug.Log($"親密レベル({GetRelationshipValue(char1, char2)}): 共闘技={CanUseCooperationSkill(char1, char2)}, 対立技={CanUseConflictSkill(char1, char2)}");
            
            // 敵対レベルでの対立技テスト  
            SetRelationshipValue(char1, char2, -25);
            Debug.Log($"敵対レベル({GetRelationshipValue(char1, char2)}): 共闘技={CanUseCooperationSkill(char1, char2)}, 対立技={CanUseConflictSkill(char1, char2)}");
        }
    }

    /// <summary>
    /// 関係値レベル（5段階システム: -25～100を25刻み）
    /// </summary>
    public enum RelationshipLevel
    {
        Hostile,    // 敵対 (0～-25)
        Cold,       // 冷淡 (25-1)
        Neutral,    // 普通 (50-26)
        Friendly,   // 友好 (75-51)
        Intimate    // 親密 (100-76)
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