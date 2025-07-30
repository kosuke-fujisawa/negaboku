using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using NegabokuRPG.Data;
using NegabokuRPG.Characters;
using NegabokuRPG.Utilities;

namespace NegabokuRPG.Systems
{
    /// <summary>
    /// ダンジョンシステム - 探索とイベント管理
    /// </summary>
    public class DungeonSystem : MonoBehaviour
    {
        private static DungeonSystem instance;
        public static DungeonSystem Instance
        {
            get
            {
                if (instance == null)
                {
                    instance = FindObjectOfType<DungeonSystem>();
                    if (instance == null)
                    {
                        var go = new GameObject("DungeonSystem");
                        instance = go.AddComponent<DungeonSystem>();
                        DontDestroyOnLoad(go);
                    }
                }
                return instance;
            }
        }

        [Header("ダンジョン設定")]
        [SerializeField] private List<DungeonData> allDungeons = new List<DungeonData>();
        [SerializeField] private float eventDelay = 1f;

        // 現在の探索状態
        private DungeonExplorationState currentExploration;
        private List<PlayerCharacter> currentParty = new List<PlayerCharacter>();
        
        // 解放済みダンジョン
        private HashSet<string> unlockedDungeons = new HashSet<string>();
        private HashSet<string> clearedDungeons = new HashSet<string>();

        // イベント
        public event Action<DungeonData> OnDungeonStarted;
        public event Action<DungeonData, bool> OnDungeonCompleted; // bool: クリア成功
        public event Action<int> OnFloorChanged;
        public event Action<DungeonEventData> OnEventTriggered;
        public event Action<DungeonChoice, List<ChoiceConsequence>> OnChoiceResult;
        public event Action<EnemyEncounter> OnBattleTriggered;
        public event Action<TreasureChest> OnTreasureFound;

        // 依存システム
        private RelationshipSystem relationshipSystem;
        private BattleSystem battleSystem;

        private void Awake()
        {
            if (instance == null)
            {
                instance = this;
                DontDestroyOnLoad(gameObject);
                InitializeDungeonSystem();
            }
            else if (instance != this)
            {
                Destroy(gameObject);
            }
        }

        private void Start()
        {
            relationshipSystem = RelationshipSystem.Instance;
            battleSystem = FindObjectOfType<BattleSystem>();
        }

        /// <summary>
        /// ダンジョンシステム初期化
        /// </summary>
        private void InitializeDungeonSystem()
        {
            // 初期解放ダンジョンを設定
            foreach (var dungeon in allDungeons)
            {
                if (dungeon.isUnlockedByDefault)
                {
                    unlockedDungeons.Add(dungeon.dungeonId);
                }
            }
        }

        /// <summary>
        /// ダンジョン探索開始（2人パーティ固定）
        /// </summary>
        public bool StartDungeonExploration(string dungeonId, List<PlayerCharacter> party)
        {
            var dungeonData = GetDungeonData(dungeonId);
            if (dungeonData == null || !IsUnlocked(dungeonId))
            {
                Debug.LogWarning($"Cannot start dungeon exploration: {dungeonId}");
                return false;
            }

            if (!ValidationHelper.ValidatePartySize(party, nameof(StartDungeonExploration)))
            {
                return false;
            }

            // 探索状態初期化
            currentExploration = new DungeonExplorationState
            {
                dungeonId = dungeonId,
                currentFloor = 1,
                visitedEvents = new HashSet<string>(),
                obtainedTreasures = new HashSet<string>(),
                partyStatus = CreatePartyStatus(party)
            };

            currentParty = new List<PlayerCharacter>(party);

            OnDungeonStarted?.Invoke(dungeonData);
            OnFloorChanged?.Invoke(currentExploration.currentFloor);

            return true;
        }

        /// <summary>
        /// 現在のフロアのイベントを取得
        /// </summary>
        public List<DungeonEventData> GetCurrentFloorEvents()
        {
            if (currentExploration == null) return new List<DungeonEventData>();

            var dungeon = GetDungeonData(currentExploration.dungeonId);
            var floor = dungeon?.GetFloorData(currentExploration.currentFloor);
            
            if (floor == null) return new List<DungeonEventData>();

            // まだ発生していないイベントのみ返す
            return floor.events.Where(e => 
                !currentExploration.visitedEvents.Contains(e.eventId) &&
                CheckEventConditions(e)).ToList();
        }

        /// <summary>
        /// イベント発生条件をチェック
        /// </summary>
        private bool CheckEventConditions(DungeonEventData eventData)
        {
            foreach (var condition in eventData.conditions)
            {
                if (!EvaluateCondition(condition))
                    return false;
            }
            return true;
        }

        /// <summary>
        /// 条件を評価
        /// </summary>
        private bool EvaluateCondition(EventCondition condition)
        {
            switch (condition.conditionType)
            {
                case ConditionType.CharacterLevel:
                    var character = currentParty.Find(c => c.CharacterId == condition.targetId);
                    if (character == null) return false;
                    return CompareValues(character.Level, condition.value, condition.comparison);

                case ConditionType.RelationshipValue:
                    // targetIdは "char1_char2" 形式
                    var ids = condition.targetId.Split('_');
                    if (ids.Length != 2) return false;
                    var relationshipValue = relationshipSystem?.GetRelationshipValue(ids[0], ids[1]) ?? 50;
                    return CompareValues(relationshipValue, condition.value, condition.comparison);

                case ConditionType.PartyMember:
                    return currentParty.Any(c => c.CharacterId == condition.targetId);

                case ConditionType.Random:
                    return UnityEngine.Random.Range(0, 100) < condition.value;

                default:
                    return true;
            }
        }

        /// <summary>
        /// 選択肢の要求条件をチェック
        /// </summary>
        private bool CheckChoiceRequirements(DungeonChoice choice)
        {
            foreach (var requirement in choice.requirements)
            {
                if (!EvaluateRequirement(requirement))
                    return false;
            }
            return true;
        }

        /// <summary>
        /// 要求条件を評価
        /// </summary>
        private bool EvaluateRequirement(ChoiceRequirement requirement)
        {
            // 条件評価ロジック（EvaluateConditionと類似）
            switch (requirement.requirementType)
            {
                case RequirementType.CharacterLevel:
                    var character = currentParty.Find(c => c.CharacterId == requirement.targetId);
                    if (character == null) return false;
                    return CompareValues(character.Level, requirement.value, requirement.comparison);

                case RequirementType.RelationshipValue:
                    var ids = requirement.targetId.Split('_');
                    if (ids.Length != 2) return false;
                    var relationshipValue = relationshipSystem?.GetRelationshipValue(ids[0], ids[1]) ?? 50;
                    return CompareValues(relationshipValue, requirement.value, requirement.comparison);

                default:
                    return true;
            }
        }

        /// <summary>
        /// 値の比較
        /// </summary>
        private bool CompareValues(int actual, int expected, ComparisonType comparison)
        {
            switch (comparison)
            {
                case ComparisonType.Equal: return actual == expected;
                case ComparisonType.NotEqual: return actual != expected;
                case ComparisonType.Greater: return actual > expected;
                case ComparisonType.GreaterOrEqual: return actual >= expected;
                case ComparisonType.Less: return actual < expected;
                case ComparisonType.LessOrEqual: return actual <= expected;
                default: return false;
            }
        }

        /// <summary>
        /// イベント処理
        /// </summary>
        public void ProcessEvent(string eventId)
        {
            var availableEvents = GetCurrentFloorEvents();
            var eventData = availableEvents.Find(e => e.eventId == eventId);
            
            if (eventData == null) return;

            currentExploration.visitedEvents.Add(eventId);
            OnEventTriggered?.Invoke(eventData);
        }

        /// <summary>
        /// 選択肢処理
        /// </summary>
        public void ProcessChoice(string eventId, string choiceId)
        {
            var dungeon = GetDungeonData(currentExploration.dungeonId);
            var floor = dungeon?.GetFloorData(currentExploration.currentFloor);
            var eventData = floor?.events.Find(e => e.eventId == eventId);
            var choice = eventData?.choices.Find(c => c.choiceId == choiceId);

            if (choice == null) return;

            if (!CheckChoiceRequirements(choice))
            {
                Debug.LogWarning($"Choice requirements not met: {choiceId}");
                return;
            }

            // 結果を適用
            var appliedConsequences = new List<ChoiceConsequence>();
            foreach (var consequence in choice.consequences)
            {
                if (ApplyConsequence(consequence))
                {
                    appliedConsequences.Add(consequence);
                }
            }

            OnChoiceResult?.Invoke(choice, appliedConsequences);
        }

        /// <summary>
        /// 結果を適用
        /// </summary>
        private bool ApplyConsequence(ChoiceConsequence consequence)
        {
            switch (consequence.consequenceType)
            {
                case ConsequenceType.HPChange:
                    return ApplyHPChange(consequence);

                case ConsequenceType.MPChange:
                    return ApplyMPChange(consequence);

                case ConsequenceType.RelationshipChange:
                    return ApplyRelationshipChange(consequence);

                case ConsequenceType.ExperienceGain:
                    return ApplyExperienceGain(consequence);

                case ConsequenceType.StartBattle:
                    return StartBattle(consequence.targetId);

                default:
                    return true;
            }
        }

        /// <summary>
        /// HP変更を適用
        /// </summary>
        private bool ApplyHPChange(ChoiceConsequence consequence)
        {
            if (consequence.targetId == "all")
            {
                foreach (var character in currentParty)
                {
                    character.ModifyHP(consequence.value);
                    currentExploration.partyStatus.hp[character.CharacterId] = character.CurrentHP;
                }
            }
            else if (consequence.targetId == "random")
            {
                var randomCharacter = currentParty[UnityEngine.Random.Range(0, currentParty.Count)];
                randomCharacter.ModifyHP(consequence.value);
                currentExploration.partyStatus.hp[randomCharacter.CharacterId] = randomCharacter.CurrentHP;
            }
            else
            {
                var character = currentParty.Find(c => c.CharacterId == consequence.targetId);
                if (character != null)
                {
                    character.ModifyHP(consequence.value);
                    currentExploration.partyStatus.hp[character.CharacterId] = character.CurrentHP;
                }
            }
            return true;
        }

        /// <summary>
        /// MP変更を適用
        /// </summary>
        private bool ApplyMPChange(ChoiceConsequence consequence)
        {
            if (consequence.targetId == "all")
            {
                foreach (var character in currentParty)
                {
                    character.ModifyMP(consequence.value);
                    currentExploration.partyStatus.mp[character.CharacterId] = character.CurrentMP;
                }
            }
            return true;
        }

        /// <summary>
        /// 関係値変更を適用（25刻みシステム対応）
        /// </summary>
        private bool ApplyRelationshipChange(ChoiceConsequence consequence)
        {
            if (relationshipSystem == null) return false;

            if (consequence.targetId == "all")
            {
                // パーティ内全員の関係値向上（2人パーティ固定）
                if (ValidationHelper.ValidatePartySize(currentParty, "ApplyRelationshipChange"))
                {
                    relationshipSystem.ModifyMutualRelationship(
                        currentParty[0].CharacterId, 
                        currentParty[1].CharacterId, 
                        consequence.value);
                }
                else
                {
                    return false;
                }
            }
            else if (consequence.targetId.Contains("_"))
            {
                // 特定の2人の関係値変更 (例: "char1_char2")
                var ids = consequence.targetId.Split('_');
                if (ids.Length == 2)
                {
                    relationshipSystem.ModifyMutualRelationship(ids[0], ids[1], consequence.value);
                }
            }
            return true;
        }

        /// <summary>
        /// 経験値獲得を適用
        /// </summary>
        private bool ApplyExperienceGain(ChoiceConsequence consequence)
        {
            if (consequence.targetId == "all")
            {
                foreach (var character in currentParty)
                {
                    character.AddExperience(consequence.value);
                }
            }
            return true;
        }

        /// <summary>
        /// 戦闘開始
        /// </summary>
        private bool StartBattle(string encounterId)
        {
            var dungeon = GetDungeonData(currentExploration.dungeonId);
            var floor = dungeon?.GetFloorData(currentExploration.currentFloor);
            var encounter = floor?.enemyEncounters.Find(e => e.encounterId == encounterId);

            if (encounter != null && battleSystem != null)
            {
                OnBattleTriggered?.Invoke(encounter);
                battleSystem.StartBattle(currentParty, encounter.enemies);
                return true;
            }
            return false;
        }

        /// <summary>
        /// 次のフロアへ進む
        /// </summary>
        public bool MoveToNextFloor()
        {
            if (currentExploration == null) return false;

            var dungeon = GetDungeonData(currentExploration.dungeonId);
            if (dungeon == null) return false;

            if (currentExploration.currentFloor >= dungeon.maxFloors)
            {
                // ダンジョンクリア
                CompleteDungeon(true);
                return false;
            }

            currentExploration.currentFloor++;
            currentExploration.visitedEvents.Clear(); // フロア変更時にイベント履歴をリセット
            
            OnFloorChanged?.Invoke(currentExploration.currentFloor);
            return true;
        }

        /// <summary>
        /// ダンジョン完了処理
        /// </summary>
        private void CompleteDungeon(bool success)
        {
            if (currentExploration == null) return;

            var dungeon = GetDungeonData(currentExploration.dungeonId);
            
            if (success)
            {
                clearedDungeons.Add(currentExploration.dungeonId);
                
                // 新しいダンジョンを解放
                if (!string.IsNullOrEmpty(dungeon.unlockedDungeonId))
                {
                    UnlockDungeon(dungeon.unlockedDungeonId);
                }
            }

            OnDungeonCompleted?.Invoke(dungeon, success);
            currentExploration = null;
            currentParty.Clear();
        }

        /// <summary>
        /// ダンジョンを解放
        /// </summary>
        public void UnlockDungeon(string dungeonId)
        {
            if (!unlockedDungeons.Contains(dungeonId))
            {
                unlockedDungeons.Add(dungeonId);
            }
        }

        /// <summary>
        /// ダンジョンが解放済みかチェック
        /// </summary>
        public bool IsUnlocked(string dungeonId)
        {
            return unlockedDungeons.Contains(dungeonId);
        }

        /// <summary>
        /// ダンジョンがクリア済みかチェック
        /// </summary>
        public bool IsCleared(string dungeonId)
        {
            return clearedDungeons.Contains(dungeonId);
        }

        /// <summary>
        /// ダンジョンデータを取得
        /// </summary>
        public DungeonData GetDungeonData(string dungeonId)
        {
            return allDungeons.Find(d => d.dungeonId == dungeonId);
        }

        /// <summary>
        /// 解放済みダンジョンを取得
        /// </summary>
        public List<DungeonData> GetUnlockedDungeons()
        {
            return allDungeons.Where(d => IsUnlocked(d.dungeonId)).ToList();
        }

        /// <summary>
        /// クリア済みダンジョンを取得
        /// </summary>
        public List<DungeonData> GetClearedDungeons()
        {
            return allDungeons.Where(d => IsCleared(d.dungeonId)).ToList();
        }

        /// <summary>
        /// 現在の探索状態を取得
        /// </summary>
        public DungeonExplorationState GetCurrentExplorationState()
        {
            return currentExploration;
        }

        /// <summary>
        /// パーティステータスを作成
        /// </summary>
        private PartyStatus CreatePartyStatus(List<PlayerCharacter> party)
        {
            var status = new PartyStatus
            {
                hp = new Dictionary<string, int>(),
                mp = new Dictionary<string, int>(),
                statusEffects = new Dictionary<string, List<string>>()
            };

            foreach (var character in party)
            {
                status.hp[character.CharacterId] = character.CurrentHP;
                status.mp[character.CharacterId] = character.CurrentMP;
                status.statusEffects[character.CharacterId] = new List<string>();
            }

            return status;
        }

        /// <summary>
        /// セーブデータから復元
        /// </summary>
        public void LoadFromSaveData(List<string> unlockedDungeonIds, List<string> clearedDungeonIds)
        {
            unlockedDungeons.Clear();
            clearedDungeons.Clear();

            foreach (var id in unlockedDungeonIds)
                unlockedDungeons.Add(id);
                
            foreach (var id in clearedDungeonIds)
                clearedDungeons.Add(id);
        }
    }

    /// <summary>
    /// ダンジョン探索状態
    /// </summary>
    [Serializable]
    public class DungeonExplorationState
    {
        public string dungeonId;
        public int currentFloor;
        public HashSet<string> visitedEvents;
        public HashSet<string> obtainedTreasures;
        public PartyStatus partyStatus;
    }

    /// <summary>
    /// パーティステータス
    /// </summary>
    [Serializable]
    public class PartyStatus
    {
        public Dictionary<string, int> hp;
        public Dictionary<string, int> mp;
        public Dictionary<string, List<string>> statusEffects;
    }
}