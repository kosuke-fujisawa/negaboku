using System;
using System.Collections.Generic;
using NegabokuRPG.Domain.ValueObjects;

namespace NegabokuRPG.Domain.Entities
{
    /// <summary>
    /// 関係値集約（集約ルート）
    /// キャラクター間の関係値管理とビジネスルールを担当
    /// </summary>
    public class RelationshipAggregate
    {
        // バトルイベント変動値
        private const int LARGE_POSITIVE_CHANGE = 25;  // 大きな協力
        private const int LARGE_NEGATIVE_CHANGE = -25; // 大きな対立
        private const int SMALL_POSITIVE_CHANGE = 12;  // 小さな協力
        private const int SMALL_NEGATIVE_CHANGE = -12; // 小さな対立
        private const int PROTECTION_BENEFICIARY_CHANGE = 25; // 守られた側
        private const int PROTECTION_PROTECTOR_CHANGE = 12;   // 守った側
        
        private readonly Dictionary<(CharacterId, CharacterId), RelationshipValue> _relationships;
        
        // イベント
        public event Action<CharacterId, CharacterId, RelationshipLevel, RelationshipLevel, string> RelationshipLevelChanged;
        
        public RelationshipAggregate()
        {
            _relationships = new Dictionary<(CharacterId, CharacterId), RelationshipValue>();
        }
        
        /// <summary>
        /// 関係値を初期化
        /// </summary>
        /// <param name="character1">キャラクター1</param>
        /// <param name="character2">キャラクター2</param>
        /// <param name="initialValue">初期関係値</param>
        public void InitializeRelationship(CharacterId character1, CharacterId character2, RelationshipValue initialValue)
        {
            _relationships[(character1, character2)] = initialValue;
        }
        
        /// <summary>
        /// 関係値を取得
        /// </summary>
        /// <param name="character1">キャラクター1</param>
        /// <param name="character2">キャラクター2</param>
        /// <returns>関係値（存在しない場合はデフォルト値）</returns>
        public RelationshipValue GetRelationship(CharacterId character1, CharacterId character2)
        {
            if (_relationships.TryGetValue((character1, character2), out var relationship))
            {
                return relationship;
            }
            return new RelationshipValue(); // デフォルト値
        }
        
        /// <summary>
        /// 関係値を変更
        /// </summary>
        /// <param name="character1">キャラクター1</param>
        /// <param name="character2">キャラクター2</param>
        /// <param name="change">変更値</param>
        /// <param name="reason">変更理由</param>
        public void ModifyRelationship(CharacterId character1, CharacterId character2, int change, string reason)
        {
            var oldRelationship = GetRelationship(character1, character2);
            var newRelationship = oldRelationship.Add(change);
            
            _relationships[(character1, character2)] = newRelationship;
            
            // レベル変化をチェック
            if (oldRelationship.Level != newRelationship.Level)
            {
                RelationshipLevelChanged?.Invoke(character1, character2, oldRelationship.Level, newRelationship.Level, reason);
            }
        }
        
        /// <summary>
        /// 双方向の関係値を変更
        /// </summary>
        /// <param name="character1">キャラクター1</param>
        /// <param name="character2">キャラクター2</param>
        /// <param name="change">変更値</param>
        /// <param name="reason">変更理由</param>
        public void ModifyMutualRelationship(CharacterId character1, CharacterId character2, int change, string reason)
        {
            ModifyRelationship(character1, character2, change, reason);
            ModifyRelationship(character2, character1, change, reason);
        }
        
        /// <summary>
        /// バトルイベントを処理
        /// </summary>
        /// <param name="eventType">イベントタイプ</param>
        /// <param name="character1">キャラクター1</param>
        /// <param name="character2">キャラクター2</param>
        public void HandleBattleEvent(BattleEventType eventType, CharacterId character1, CharacterId character2)
        {
            switch (eventType)
            {
                case BattleEventType.Cooperation:
                    ModifyMutualRelationship(character1, character2, LARGE_POSITIVE_CHANGE, "協力行動");
                    break;
                case BattleEventType.FriendlyFire:
                    ModifyMutualRelationship(character1, character2, LARGE_NEGATIVE_CHANGE, "誤射");
                    break;
                case BattleEventType.Protection:
                    // 非対称な変化：守った側 +12、守られた側 +25
                    ModifyRelationship(character1, character2, PROTECTION_PROTECTOR_CHANGE, "保護行動");
                    ModifyRelationship(character2, character1, PROTECTION_BENEFICIARY_CHANGE, "保護された");
                    break;
                case BattleEventType.Rivalry:
                    ModifyMutualRelationship(character1, character2, SMALL_NEGATIVE_CHANGE, "対立");
                    break;
                case BattleEventType.Support:
                    ModifyMutualRelationship(character1, character2, SMALL_POSITIVE_CHANGE, "支援");
                    break;
            }
        }
        
        /// <summary>
        /// 全ての関係値を取得
        /// </summary>
        /// <returns>関係値の辞書</returns>
        public Dictionary<(CharacterId, CharacterId), RelationshipValue> GetAllRelationships()
        {
            return new Dictionary<(CharacterId, CharacterId), RelationshipValue>(_relationships);
        }
    }
}