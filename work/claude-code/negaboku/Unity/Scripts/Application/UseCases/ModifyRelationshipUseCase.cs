using NegabokuRPG.Application.Interfaces;
using NegabokuRPG.Domain.Entities;
using NegabokuRPG.Domain.ValueObjects;
using NegabokuRPG.Domain.Services;
using System.Collections.Generic;

namespace NegabokuRPG.Application.UseCases
{
    /// <summary>
    /// 関係値変更ユースケース
    /// アプリケーションのビジネスフローを制御
    /// </summary>
    public class ModifyRelationshipUseCase
    {
        private readonly IRelationshipRepository _repository;
        private readonly RelationshipDomainService _domainService;
        
        public ModifyRelationshipUseCase(IRelationshipRepository repository, RelationshipDomainService domainService)
        {
            _repository = repository;
            _domainService = domainService;
        }
        
        /// <summary>
        /// 関係値を変更
        /// </summary>
        /// <param name="character1">キャラクター1</param>
        /// <param name="character2">キャラクター2</param>
        /// <param name="change">変更値</param>
        /// <param name="reason">理由</param>
        /// <returns>変更後の関係値</returns>
        public RelationshipValue Execute(CharacterId character1, CharacterId character2, int change, string reason)
        {
            // 集約を読み込み
            var aggregate = _repository.Load(new List<CharacterId> { character1, character2 });
            
            // ビジネスロジック実行
            aggregate.ModifyRelationship(character1, character2, change, reason);
            
            // 永続化
            _repository.Save(aggregate);
            
            // 結果を返す
            return aggregate.GetRelationship(character1, character2);
        }
        
        /// <summary>
        /// 双方向関係値を変更
        /// </summary>
        /// <param name="character1">キャラクター1</param>
        /// <param name="character2">キャラクター2</param>
        /// <param name="change">変更値</param>
        /// <param name="reason">理由</param>
        /// <returns>両方向の関係値</returns>
        public (RelationshipValue, RelationshipValue) ExecuteMutual(CharacterId character1, CharacterId character2, int change, string reason)
        {
            // 集約を読み込み
            var aggregate = _repository.Load(new List<CharacterId> { character1, character2 });
            
            // ビジネスロジック実行
            aggregate.ModifyMutualRelationship(character1, character2, change, reason);
            
            // 永続化
            _repository.Save(aggregate);
            
            // 結果を返す
            return (
                aggregate.GetRelationship(character1, character2),
                aggregate.GetRelationship(character2, character1)
            );
        }
        
        /// <summary>
        /// バトルイベント処理
        /// </summary>
        /// <param name="eventType">イベントタイプ</param>
        /// <param name="character1">キャラクター1</param>
        /// <param name="character2">キャラクター2</param>
        /// <returns>変更後の関係値</returns>
        public (RelationshipValue, RelationshipValue) ExecuteBattleEvent(BattleEventType eventType, CharacterId character1, CharacterId character2)
        {
            // 集約を読み込み
            var aggregate = _repository.Load(new List<CharacterId> { character1, character2 });
            
            // ビジネスロジック実行
            aggregate.HandleBattleEvent(eventType, character1, character2);
            
            // 永続化
            _repository.Save(aggregate);
            
            // 結果を返す
            return (
                aggregate.GetRelationship(character1, character2),
                aggregate.GetRelationship(character2, character1)
            );
        }
    }
}