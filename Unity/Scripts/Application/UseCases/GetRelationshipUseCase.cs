using NegabokuRPG.Application.Interfaces;
using NegabokuRPG.Domain.ValueObjects;
using NegabokuRPG.Domain.Services;
using System.Collections.Generic;

namespace NegabokuRPG.Application.UseCases
{
    /// <summary>
    /// 関係値取得ユースケース
    /// 関係値の照会機能を提供
    /// </summary>
    public class GetRelationshipUseCase
    {
        private readonly IRelationshipRepository _repository;
        private readonly RelationshipDomainService _domainService;
        
        public GetRelationshipUseCase(IRelationshipRepository repository, RelationshipDomainService domainService)
        {
            _repository = repository;
            _domainService = domainService;
        }
        
        /// <summary>
        /// 関係値を取得
        /// </summary>
        /// <param name="character1">キャラクター1</param>
        /// <param name="character2">キャラクター2</param>
        /// <returns>関係値</returns>
        public RelationshipValue Execute(CharacterId character1, CharacterId character2)
        {
            var aggregate = _repository.Load(new List<CharacterId> { character1, character2 });
            return aggregate.GetRelationship(character1, character2);
        }
        
        /// <summary>
        /// パーティの平均関係値を取得
        /// </summary>
        /// <param name="partyMembers">パーティメンバー</param>
        /// <returns>平均関係値</returns>
        public float GetAveragePartyRelationship(List<CharacterId> partyMembers)
        {
            var aggregate = _repository.Load(partyMembers);
            return _domainService.CalculateAveragePartyRelationship(aggregate, partyMembers);
        }
        
        /// <summary>
        /// 共闘技使用可能なペアを取得
        /// </summary>
        /// <param name="partyMembers">パーティメンバー</param>
        /// <returns>共闘技可能なペア</returns>
        public List<(CharacterId, CharacterId)> GetCooperationSkillPairs(List<CharacterId> partyMembers)
        {
            var aggregate = _repository.Load(partyMembers);
            return _domainService.GetCooperationSkillPairs(aggregate, partyMembers);
        }
        
        /// <summary>
        /// 対立技使用可能なペアを取得
        /// </summary>
        /// <param name="partyMembers">パーティメンバー</param>
        /// <returns>対立技可能なペア</returns>
        public List<(CharacterId, CharacterId)> GetConflictSkillPairs(List<CharacterId> partyMembers)
        {
            var aggregate = _repository.Load(partyMembers);
            return _domainService.GetConflictSkillPairs(aggregate, partyMembers);
        }
        
        /// <summary>
        /// 関係値分布を分析
        /// </summary>
        /// <param name="partyMembers">パーティメンバー</param>
        /// <returns>レベル別分布</returns>
        public Dictionary<RelationshipLevel, int> AnalyzeRelationshipDistribution(List<CharacterId> partyMembers)
        {
            var aggregate = _repository.Load(partyMembers);
            return _domainService.AnalyzeRelationshipDistribution(aggregate, partyMembers);
        }
    }
}