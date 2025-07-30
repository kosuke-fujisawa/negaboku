using System.Collections.Generic;
using System.Linq;
using NegabokuRPG.Domain.Events;

namespace NegabokuRPG.Domain.Common
{
    /// <summary>
    /// 集約ルートの基底クラス
    /// ドメインイベントの管理機能を提供
    /// </summary>
    public abstract class AggregateRoot
    {
        private readonly List<IDomainEvent> _domainEvents = new List<IDomainEvent>();
        
        /// <summary>
        /// 未コミットのドメインイベント一覧
        /// </summary>
        public IReadOnlyList<IDomainEvent> UncommittedEvents => _domainEvents.AsReadOnly();
        
        /// <summary>
        /// ドメインイベントを追加
        /// </summary>
        /// <param name="domainEvent">追加するドメインイベント</param>
        protected void AddDomainEvent(IDomainEvent domainEvent)
        {
            _domainEvents.Add(domainEvent);
        }
        
        /// <summary>
        /// 未コミットのドメインイベントをクリア
        /// </summary>
        public void MarkChangesAsCommitted()
        {
            _domainEvents.Clear();
        }
        
        /// <summary>
        /// 指定タイプのドメインイベントが存在するかチェック
        /// </summary>
        /// <typeparam name="T">ドメインイベントの型</typeparam>
        /// <returns>存在する場合true</returns>
        public bool HasDomainEvent<T>() where T : IDomainEvent
        {
            return _domainEvents.OfType<T>().Any();
        }
        
        /// <summary>
        /// 指定タイプのドメインイベントを取得
        /// </summary>
        /// <typeparam name="T">ドメインイベントの型</typeparam>
        /// <returns>該当するドメインイベントのリスト</returns>
        public IEnumerable<T> GetDomainEvents<T>() where T : IDomainEvent
        {
            return _domainEvents.OfType<T>();
        }
    }
}