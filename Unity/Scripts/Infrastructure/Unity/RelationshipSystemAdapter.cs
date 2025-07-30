using UnityEngine;
using NegabokuRPG.Presentation.Controllers;
using NegabokuRPG.Domain.ValueObjects;
using NegabokuRPG.Domain.Entities;
using System.Collections.Generic;
using NegabokuRPG.Data;

namespace NegabokuRPG.Infrastructure.Unity
{
    /// <summary>
    /// 既存RelationshipSystemと新アーキテクチャを繋ぐアダプター
    /// 段階的移行を可能にする
    /// </summary>
    public class RelationshipSystemAdapter : MonoBehaviour
    {
        private static RelationshipSystemAdapter s_instance;
        public static RelationshipSystemAdapter Instance
        {
            get
            {
                if (s_instance == null)
                {
                    s_instance = FindObjectOfType<RelationshipSystemAdapter>();
                    if (s_instance == null)
                    {
                        var go = new GameObject("RelationshipSystemAdapter");
                        s_instance = go.AddComponent<RelationshipSystemAdapter>();
                        DontDestroyOnLoad(go);
                    }
                }
                return s_instance;
            }
        }
        
        private RelationshipController _controller;
        
        // 新アーキテクチャとの互換性のためのイベント
        public System.Action<string, string, int, int> OnRelationshipChanged;
        public System.Action<string, string, RelationshipLevel> OnRelationshipLevelChanged;
        
        private void Awake()
        {
            if (s_instance == null)
            {
                s_instance = this;
                DontDestroyOnLoad(gameObject);
                InitializeController();
            }
            else if (s_instance != this)
            {
                Destroy(gameObject);
            }
        }
        
        private void InitializeController()
        {
            // RelationshipControllerコンポーネントを追加
            _controller = gameObject.AddComponent<RelationshipController>();
            
            // イベント接続
            _controller.RelationshipLevelChanged += OnControllerRelationshipLevelChanged;
        }
        
        private void OnControllerRelationshipLevelChanged(string char1, string char2, RelationshipLevel oldLevel, RelationshipLevel newLevel, string reason)
        {
            // 既存システムとの互換性のためのイベント発火
            OnRelationshipLevelChanged?.Invoke(char1, char2, newLevel);
            
            Debug.Log($"関係レベル変化: {char1} → {char2}: {oldLevel} → {newLevel} (理由: {reason})");
        }
        
        #region 既存システムとの互換性メソッド
        
        /// <summary>
        /// 既存システム互換：キャラクターデータから関係値を初期化
        /// </summary>
        public void InitializeRelationships(List<CharacterData> characters)
        {
            foreach (var character in characters)
            {
                foreach (var otherCharacter in characters)
                {
                    if (character.characterId != otherCharacter.characterId)
                    {
                        // デフォルト値で初期化（既存システムと同じ動作）
                        var defaultValue = character.GetDefaultRelationshipWith(otherCharacter.characterId);
                        SetRelationshipValue(character.characterId, otherCharacter.characterId, defaultValue);
                    }
                }
            }
        }
        
        /// <summary>
        /// 既存システム互換：関係値を取得
        /// </summary>
        public int GetRelationshipValue(string character1Id, string character2Id)
        {
            if (_controller == null) return RelationshipValue.DEFAULT_VALUE;
            
            var relationship = _controller.GetRelationship(character1Id, character2Id);
            return relationship.Value;
        }
        
        /// <summary>
        /// 既存システム互換：関係値を設定
        /// </summary>
        public void SetRelationshipValue(string character1Id, string character2Id, int value)
        {
            if (_controller == null) return;
            
            var currentValue = GetRelationshipValue(character1Id, character2Id);
            var change = value - currentValue;
            
            if (change != 0)
            {
                _controller.ModifyRelationship(character1Id, character2Id, change, "直接設定");
                
                // 既存システムイベント発火
                OnRelationshipChanged?.Invoke(character1Id, character2Id, currentValue, value);
            }
        }
        
        /// <summary>
        /// 既存システム互換：関係値を変更
        /// </summary>
        public void ModifyRelationshipValue(string character1Id, string character2Id, int change)
        {
            if (_controller == null) return;
            
            var oldValue = GetRelationshipValue(character1Id, character2Id);
            _controller.ModifyRelationship(character1Id, character2Id, change, "相対変更");
            var newValue = GetRelationshipValue(character1Id, character2Id);
            
            // 既存システムイベント発火
            OnRelationshipChanged?.Invoke(character1Id, character2Id, oldValue, newValue);
        }
        
        /// <summary>
        /// 既存システム互換：双方向の関係値を変更
        /// </summary>
        public void ModifyMutualRelationship(string character1Id, string character2Id, int change)
        {
            if (_controller == null) return;
            
            _controller.ModifyMutualRelationship(character1Id, character2Id, change, "相互変更");
        }
        
        /// <summary>
        /// 既存システム互換：関係レベルを取得
        /// </summary>
        public RelationshipLevel GetRelationshipLevel(string character1Id, string character2Id)
        {
            if (_controller == null) return RelationshipLevel.Neutral;
            
            var relationship = _controller.GetRelationship(character1Id, character2Id);
            return relationship.Level;
        }
        
        /// <summary>
        /// 既存システム互換：共闘技が使用可能かチェック
        /// </summary>
        public bool CanUseCooperationSkill(string character1Id, string character2Id)
        {
            if (_controller == null) return false;
            
            var relationship = _controller.GetRelationship(character1Id, character2Id);
            return relationship.CanUseCooperationSkill();
        }
        
        /// <summary>
        /// 既存システム互換：対立技が使用可能かチェック
        /// </summary>
        public bool CanUseConflictSkill(string character1Id, string character2Id)
        {
            if (_controller == null) return false;
            
            var relationship = _controller.GetRelationship(character1Id, character2Id);
            return relationship.CanUseConflictSkill();
        }
        
        /// <summary>
        /// 既存システム互換：バトルイベントを処理
        /// </summary>
        public void HandleBattleEvent(BattleEventType eventType, string character1Id, string character2Id = null)
        {
            if (_controller == null || string.IsNullOrEmpty(character2Id)) return;
            
            _controller.HandleBattleEvent(eventType, character1Id, character2Id);
        }
        
        /// <summary>
        /// 既存システム互換：パーティ全体の平均関係値を計算
        /// </summary>
        public float CalculateAverageRelationship(List<string> partyCharacterIds)
        {
            if (_controller == null) return RelationshipValue.DEFAULT_VALUE;
            
            return _controller.GetAveragePartyRelationship(partyCharacterIds);
        }
        
        #endregion
        
        #region 新機能（新アーキテクチャの恩恵）
        
        /// <summary>
        /// 新機能：共闘技使用可能なペアを取得
        /// </summary>
        public List<(string, string)> GetCooperationSkillPairs(List<string> partyMemberIds)
        {
            if (_controller == null) return new List<(string, string)>();
            
            return _controller.GetCooperationSkillPairs(partyMemberIds);
        }
        
        /// <summary>
        /// 新機能：対立技使用可能なペアを取得
        /// </summary>
        public List<(string, string)> GetConflictSkillPairs(List<string> partyMemberIds)
        {
            if (_controller == null) return new List<(string, string)>();
            
            return _controller.GetConflictSkillPairs(partyMemberIds);
        }
        
        #endregion
    }
}