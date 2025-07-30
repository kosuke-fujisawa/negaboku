using System;
using NegabokuRPG.Domain.ValueObjects;

namespace NegabokuRPG.Domain.Events
{
    /// <summary>
    /// 関係レベル変更イベント
    /// 関係値の段階的変化（レベル変更）が発生した際に発行
    /// </summary>
    public class RelationshipLevelChangedEvent : IDomainEvent
    {
        public DateTime OccurredAt { get; }
        public Guid EventId { get; }
        
        /// <summary>
        /// 関係変化の主体キャラクター
        /// </summary>
        public CharacterId SourceCharacter { get; }
        
        /// <summary>
        /// 関係変化の対象キャラクター
        /// </summary>
        public CharacterId TargetCharacter { get; }
        
        /// <summary>
        /// 変更前の関係レベル
        /// </summary>
        public RelationshipLevel PreviousLevel { get; }
        
        /// <summary>
        /// 変更後の関係レベル
        /// </summary>
        public RelationshipLevel NewLevel { get; }
        
        /// <summary>
        /// 変更前の関係値
        /// </summary>
        public int PreviousValue { get; }
        
        /// <summary>
        /// 変更後の関係値
        /// </summary>
        public int NewValue { get; }
        
        /// <summary>
        /// 変更理由
        /// </summary>
        public string Reason { get; }
        
        /// <summary>
        /// コンストラクタ
        /// </summary>
        public RelationshipLevelChangedEvent(
            CharacterId sourceCharacter,
            CharacterId targetCharacter,
            RelationshipLevel previousLevel,
            RelationshipLevel newLevel,
            int previousValue,
            int newValue,
            string reason)
        {
            EventId = Guid.NewGuid();
            OccurredAt = DateTime.UtcNow;
            SourceCharacter = sourceCharacter;
            TargetCharacter = targetCharacter;
            PreviousLevel = previousLevel;
            NewLevel = newLevel;
            PreviousValue = previousValue;
            NewValue = newValue;
            Reason = reason;
        }
        
        /// <summary>
        /// レベル向上かどうかを判定
        /// </summary>
        public bool IsImprovement()
        {
            return NewValue > PreviousValue;
        }
        
        /// <summary>
        /// 重要な変化（2段階以上の変化）かどうかを判定
        /// </summary>
        public bool IsSignificantChange()
        {
            return Math.Abs(NewValue - PreviousValue) >= RelationshipValue.STEP_SIZE * 2;
        }
    }
}