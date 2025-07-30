using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using NegabokuRPG.Data;
using NegabokuRPG.Characters;

namespace NegabokuRPG.Systems
{
    /// <summary>
    /// スキルシステム - 関係値による動的スキル解放
    /// </summary>
    public class SkillSystem : MonoBehaviour
    {
        private static SkillSystem instance;
        public static SkillSystem Instance
        {
            get
            {
                if (instance == null)
                {
                    instance = FindObjectOfType<SkillSystem>();
                    if (instance == null)
                    {
                        var go = new GameObject("SkillSystem");
                        instance = go.AddComponent<SkillSystem>();
                        DontDestroyOnLoad(go);
                    }
                }
                return instance;
            }
        }

        [Header("スキル設定")]
        [SerializeField] private List<SkillData> allSkills = new List<SkillData>();
        [SerializeField] private List<SkillCollection> skillCollections = new List<SkillCollection>();

        // 解放済みスキル
        private HashSet<string> unlockedSkills = new HashSet<string>();

        // イベント
        public event Action<SkillData, List<string>> OnSkillUnlocked; // スキル, 関連キャラクター
        public event Action<SkillData> OnSkillLearned;
        public event Action<string, List<SkillData>> OnCharacterSkillsUpdated;

        // 依存システム
        private RelationshipSystem relationshipSystem;

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

        private void Start()
        {
            relationshipSystem = RelationshipSystem.Instance;
            if (relationshipSystem != null)
            {
                relationshipSystem.OnRelationshipChanged += OnRelationshipChanged;
            }
        }

        /// <summary>
        /// キャラクターの初期スキルを設定
        /// </summary>
        public void InitializeCharacterSkills(PlayerCharacter character)
        {
            if (character.Data == null) return;

            // 基本スキルを追加
            foreach (var baseSkill in character.Data.baseSkills)
            {
                character.AddSkill(baseSkill);
                unlockedSkills.Add(baseSkill.skillId);
            }

            // レベルベースのスキルをチェック
            UpdateAvailableSkills(character);
        }

        /// <summary>
        /// パーティ全体のスキルを更新
        /// </summary>
        public void UpdatePartySkills(List<PlayerCharacter> party)
        {
            var characterIds = party.Select(c => c.CharacterId).ToList();
            var relationships = relationshipSystem?.GetAllRelationships();

            foreach (var character in party)
            {
                UpdateAvailableSkills(character, party, relationships);
            }

            // 新しく解放されたスキルをチェック
            CheckForNewSkillUnlocks(party, relationships);
        }

        /// <summary>
        /// 単一キャラクターの利用可能スキルを更新
        /// </summary>
        public void UpdateAvailableSkills(PlayerCharacter character, List<PlayerCharacter> party = null, Dictionary<string, Dictionary<string, int>> relationships = null)
        {
            if (character.Data == null) return;

            var currentSkills = new List<SkillData>(character.AvailableSkills);
            var newSkills = new List<SkillData>();

            // レベルベースのスキルをチェック
            foreach (var skill in allSkills)
            {
                if (ShouldLearnSkill(skill, character, party, relationships) && 
                    !currentSkills.Any(s => s.skillId == skill.skillId))
                {
                    character.AddSkill(skill);
                    newSkills.Add(skill);
                    unlockedSkills.Add(skill.skillId);
                }
            }

            if (newSkills.Count > 0)
            {
                OnCharacterSkillsUpdated?.Invoke(character.CharacterId, newSkills);
            }
        }

        /// <summary>
        /// スキルを習得すべきかチェック
        /// </summary>
        private bool ShouldLearnSkill(SkillData skill, PlayerCharacter character, List<PlayerCharacter> party = null, Dictionary<string, Dictionary<string, int>> relationships = null)
        {
            // レベル条件チェック
            if (character.Level < skill.requiredLevel)
                return false;

            // 通常スキルは条件満たせば習得
            if (skill.skillType == SkillType.Normal)
                return true;

            // 特殊スキル（共闘技・対立技）の条件チェック
            if (skill.requiredCharacterIds.Count == 0)
                return false;

            // パーティに必要キャラクターがいるかチェック
            if (party != null)
            {
                var partyCharacterIds = party.Select(c => c.CharacterId).ToList();
                foreach (var requiredCharId in skill.requiredCharacterIds)
                {
                    if (!partyCharacterIds.Contains(requiredCharId))
                        return false;
                }
            }

            // 関係値条件チェック
            if (relationships != null && skill.requiredCharacterIds.Count >= 2)
            {
                return skill.CanUse(character.Data, 
                    party?.Select(c => c.Data).ToList() ?? new List<CharacterData>(), 
                    relationships);
            }

            return true;
        }

        /// <summary>
        /// 新しいスキル解放をチェック
        /// </summary>
        private void CheckForNewSkillUnlocks(List<PlayerCharacter> party, Dictionary<string, Dictionary<string, int>> relationships)
        {
            if (relationships == null) return;

            foreach (var skill in allSkills)
            {
                if (unlockedSkills.Contains(skill.skillId)) continue;
                if (skill.skillType == SkillType.Normal) continue;

                // 特殊スキルの解放条件をチェック
                if (IsSkillUnlockable(skill, party, relationships))
                {
                    unlockedSkills.Add(skill.skillId);
                    OnSkillUnlocked?.Invoke(skill, skill.requiredCharacterIds);

                    // 該当キャラクターにスキルを追加
                    var primaryCharacter = GetPrimaryCharacterForSkill(skill, party);
                    if (primaryCharacter != null)
                    {
                        primaryCharacter.AddSkill(skill);
                        OnSkillLearned?.Invoke(skill);
                    }
                }
            }
        }

        /// <summary>
        /// スキルが解放可能かチェック
        /// </summary>
        private bool IsSkillUnlockable(SkillData skill, List<PlayerCharacter> party, Dictionary<string, Dictionary<string, int>> relationships)
        {
            if (skill.requiredCharacterIds.Count < 2) return false;

            // パーティに必要キャラクターがいるかチェック
            var partyCharacterIds = party.Select(c => c.CharacterId).ToList();
            foreach (var requiredCharId in skill.requiredCharacterIds)
            {
                if (!partyCharacterIds.Contains(requiredCharId))
                    return false;
            }

            // レベル条件チェック
            var primaryCharacter = party.Find(c => c.CharacterId == skill.requiredCharacterIds[0]);
            if (primaryCharacter != null && primaryCharacter.Level < skill.requiredLevel)
                return false;

            // 関係値条件チェック
            var char1Id = skill.requiredCharacterIds[0];
            var char2Id = skill.requiredCharacterIds[1];

            if (relationships.ContainsKey(char1Id) && relationships[char1Id].ContainsKey(char2Id))
            {
                var relationshipValue = relationships[char1Id][char2Id];

                switch (skill.skillType)
                {
                    case SkillType.Cooperation:
                        return relationshipValue >= skill.requiredRelationshipValue;
                    case SkillType.Conflict:
                        return relationshipValue <= skill.requiredRelationshipValue;
                }
            }

            return false;
        }

        /// <summary>
        /// スキルの主要キャラクターを取得
        /// </summary>
        private PlayerCharacter GetPrimaryCharacterForSkill(SkillData skill, List<PlayerCharacter> party)
        {
            if (skill.requiredCharacterIds.Count == 0) return null;
            return party.Find(c => c.CharacterId == skill.requiredCharacterIds[0]);
        }

        /// <summary>
        /// 関係値変化時の処理
        /// </summary>
        private void OnRelationshipChanged(string char1Id, string char2Id, int oldValue, int newValue)
        {
            // 関係値変化により新しいスキルが解放される可能性があるため、
            // 現在のパーティスキルを更新
            var activeParty = GetCurrentActiveParty(); // 実装時は現在のパーティを取得
            if (activeParty.Count > 0)
            {
                UpdatePartySkills(activeParty);
            }
        }

        /// <summary>
        /// 使用可能なスキルを取得
        /// </summary>
        public List<SkillData> GetUsableSkills(PlayerCharacter character, List<PlayerCharacter> party)
        {
            var usableSkills = new List<SkillData>();
            var relationships = relationshipSystem?.GetAllRelationships();

            foreach (var skill in character.AvailableSkills)
            {
                if (CanUseSkill(skill, character, party, relationships))
                {
                    usableSkills.Add(skill);
                }
            }

            return usableSkills;
        }

        /// <summary>
        /// スキルが使用可能かチェック
        /// </summary>
        public bool CanUseSkill(SkillData skill, PlayerCharacter character, List<PlayerCharacter> party, Dictionary<string, Dictionary<string, int>> relationships = null)
        {
            // 基本条件（MP、レベル）
            if (!character.CanUseSkill(skill))
                return false;

            // 通常スキルは使用可能
            if (skill.skillType == SkillType.Normal)
                return true;

            // 特殊スキルの条件チェック
            if (relationships == null)
                relationships = relationshipSystem?.GetAllRelationships();

            if (relationships != null)
            {
                return skill.CanUse(character.Data, 
                    party.Select(c => c.Data).ToList(), 
                    relationships);
            }

            return false;
        }

        /// <summary>
        /// スキル威力修正を取得
        /// </summary>
        public float GetSkillPowerModifier(SkillData skill, PlayerCharacter caster, List<PlayerCharacter> party)
        {
            if (skill.skillType == SkillType.Normal) return 1.0f;

            var relationships = relationshipSystem?.GetAllRelationships();
            if (relationships == null) return 1.0f;

            float modifier = skill.CalculatePowerModifier(relationships);

            // パーティ内の連携ボーナス
            if (skill.skillType == SkillType.Cooperation && skill.requiredCharacterIds.Count >= 2)
            {
                var partyCharacterIds = party.Select(c => c.CharacterId).ToList();
                var partnersInParty = skill.requiredCharacterIds.Count(id => partyCharacterIds.Contains(id));
                
                if (partnersInParty >= skill.requiredCharacterIds.Count)
                {
                    modifier *= 1.2f; // 20%ボーナス
                }
            }

            return modifier;
        }

        /// <summary>
        /// 共闘技を取得
        /// </summary>
        public List<SkillData> GetCooperationSkills(List<PlayerCharacter> party)
        {
            var cooperationSkills = new List<SkillData>();
            var relationships = relationshipSystem?.GetAllRelationships();

            foreach (var character in party)
            {
                foreach (var skill in character.AvailableSkills)
                {
                    if (skill.skillType == SkillType.Cooperation && 
                        CanUseSkill(skill, character, party, relationships))
                    {
                        cooperationSkills.Add(skill);
                    }
                }
            }

            return cooperationSkills.Distinct().ToList();
        }

        /// <summary>
        /// 対立技を取得
        /// </summary>
        public List<SkillData> GetConflictSkills(List<PlayerCharacter> party)
        {
            var conflictSkills = new List<SkillData>();
            var relationships = relationshipSystem?.GetAllRelationships();

            foreach (var character in party)
            {
                foreach (var skill in character.AvailableSkills)
                {
                    if (skill.skillType == SkillType.Conflict && 
                        CanUseSkill(skill, character, party, relationships))
                    {
                        conflictSkills.Add(skill);
                    }
                }
            }

            return conflictSkills.Distinct().ToList();
        }

        /// <summary>
        /// キャラクターペアのスキルを取得
        /// </summary>
        public List<SkillData> GetSkillsForCharacterPair(string char1Id, string char2Id)
        {
            return allSkills.Where(skill => 
                skill.requiredCharacterIds.Contains(char1Id) && 
                skill.requiredCharacterIds.Contains(char2Id)).ToList();
        }

        /// <summary>
        /// スキルIDでスキルを取得
        /// </summary>
        public SkillData GetSkillById(string skillId)
        {
            return allSkills.Find(skill => skill.skillId == skillId);
        }

        /// <summary>
        /// 解放済みスキル数を取得
        /// </summary>
        public int GetUnlockedSkillsCount()
        {
            return unlockedSkills.Count;
        }

        /// <summary>
        /// 全スキル数を取得
        /// </summary>
        public int GetTotalSkillsCount()
        {
            return allSkills.Count;
        }

        /// <summary>
        /// スキルが解放済みかチェック
        /// </summary>
        public bool IsSkillUnlocked(string skillId)
        {
            return unlockedSkills.Contains(skillId);
        }

        /// <summary>
        /// 現在のアクティブパーティを取得（実装時は適切な方法で取得）
        /// </summary>
        private List<PlayerCharacter> GetCurrentActiveParty()
        {
            // 実装時はGameManagerやPartyManagerから取得
            return new List<PlayerCharacter>();
        }

        /// <summary>
        /// セーブデータから復元
        /// </summary>
        public void LoadFromSaveData(List<string> unlockedSkillIds)
        {
            unlockedSkills.Clear();
            foreach (var skillId in unlockedSkillIds)
            {
                unlockedSkills.Add(skillId);
            }
        }

        /// <summary>
        /// スキルコレクションを設定
        /// </summary>
        public void SetSkillCollections(List<SkillCollection> collections)
        {
            skillCollections = collections;
            
            // 全スキルリストを更新
            allSkills.Clear();
            foreach (var collection in skillCollections)
            {
                allSkills.AddRange(collection.skills);
            }
        }

        private void OnDestroy()
        {
            if (relationshipSystem != null)
            {
                relationshipSystem.OnRelationshipChanged -= OnRelationshipChanged;
            }
        }
    }

    /// <summary>
    /// スキルコレクション - ScriptableObject
    /// </summary>
    [CreateAssetMenu(fileName = "New Skill Collection", menuName = "NegabokuRPG/Skill Collection")]
    [Serializable]
    public class SkillCollection : ScriptableObject
    {
        [Header("コレクション情報")]
        public string collectionName;
        public string description;
        
        [Header("スキル")]
        public List<SkillData> skills = new List<SkillData>();
        
        [Header("解放条件")]
        public bool isDLCContent = false;
        public List<string> requiredCompletedStories = new List<string>();
    }
}