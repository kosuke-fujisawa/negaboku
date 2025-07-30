using System;

namespace NegabokuRPG.Domain.Events
{
    /// <summary>
    /// ドメインイベントの基底インターフェース
    /// ドメイン内で発生する重要な出来事を表現
    /// </summary>
    public interface IDomainEvent
    {
        /// <summary>
        /// イベントが発生した日時
        /// </summary>
        DateTime OccurredAt { get; }
        
        /// <summary>
        /// イベントの一意識別子
        /// </summary>
        Guid EventId { get; }
    }
}