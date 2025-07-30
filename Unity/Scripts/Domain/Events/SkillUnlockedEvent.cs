using System;
using NegabokuRPG.Domain.ValueObjects;

namespace NegabokuRPG.Domain.Events
{
    /// <summary>
    /// スキル解放イベント
    /// 関係値変化により新しいスキルが使用可能になった際に発行
    /// </summary>
    public class SkillUnlockedEvent : IDomainEvent
    {
        public DateTime OccurredAt { get; }
        public Guid EventId { get; }
        
        /// <summary>
        /// 関係の主体キャラクター
        /// </summary>
        public CharacterId Character1 { get; }
        
        /// <summary>
        /// 関係の対象キャラクター
        /// </summary>
        public CharacterId Character2 { get; }
        
        /// <summary>
        /// 解放されたスキルタイプ
        /// </summary>
        public SkillType UnlockedSkillType { get; }
        
        /// <summary>
        /// 現在の関係レベル
        /// </summary>
        public RelationshipLevel CurrentLevel { get; }
        
        /// <summary>
        /// 現在の関係値
        /// </summary>
        public int CurrentValue { get; }
        
        /// <summary>
        /// コンストラクタ
        /// </summary>
        public SkillUnlockedEvent(
            CharacterId character1,
            CharacterId character2,
            SkillType unlockedSkillType,
            RelationshipLevel currentLevel,
            int currentValue)
        {
            EventId = Guid.NewGuid();
            OccurredAt = DateTime.UtcNow;
            Character1 = character1;
            Character2 = character2;
            UnlockedSkillType = unlockedSkillType;
            CurrentLevel = currentLevel;
            CurrentValue = currentValue;
        }
    }
    
    /// <summary>
    /// スキルタイプ列挙型
    /// </summary>
    public enum SkillType
    {
        /// <summary>
        /// 共闘技（親密レベルで解放）
        /// </summary>
        CooperationSkill,
        
        /// <summary>
        /// 対立技（敵対レベルで解放）
        /// </summary>
        ConflictSkill
    }
}