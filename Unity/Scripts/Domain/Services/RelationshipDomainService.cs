using System.Collections.Generic;
using System.Linq;
using NegabokuRPG.Domain.ValueObjects;
using NegabokuRPG.Domain.Entities;

namespace NegabokuRPG.Domain.Services
{
    /// <summary>
    /// 関係値ドメインサービス
    /// 複数の集約をまたがる複雑なビジネスロジックを担当
    /// </summary>
    public class RelationshipDomainService
    {
        /// <summary>
        /// パーティ全体の平均関係値を計算
        /// </summary>
        /// <param name="aggregate">関係値集約</param>
        /// <param name="partyMembers">パーティメンバー</param>
        /// <returns>平均関係値</returns>
        public float CalculateAveragePartyRelationship(RelationshipAggregate aggregate, List<CharacterId> partyMembers)
        {
            if (partyMembers.Count < 2) 
                return RelationshipValue.DEFAULT_VALUE;

            var totalValue = 0;
            var count = 0;

            for (int i = 0; i < partyMembers.Count; i++)
            {
                for (int j = i + 1; j < partyMembers.Count; j++)
                {
                    var relationship = aggregate.GetRelationship(partyMembers[i], partyMembers[j]);
                    totalValue += relationship.Value;
                    count++;
                }
            }

            return count > 0 ? (float)totalValue / count : RelationshipValue.DEFAULT_VALUE;
        }
        
        /// <summary>
        /// パーティで共闘技が使用可能なペアを取得
        /// </summary>
        /// <param name="aggregate">関係値集約</param>
        /// <param name="partyMembers">パーティメンバー</param>
        /// <returns>共闘技可能なペアのリスト</returns>
        public List<(CharacterId, CharacterId)> GetCooperationSkillPairs(RelationshipAggregate aggregate, List<CharacterId> partyMembers)
        {
            var pairs = new List<(CharacterId, CharacterId)>();
            
            for (int i = 0; i < partyMembers.Count; i++)
            {
                for (int j = i + 1; j < partyMembers.Count; j++)
                {
                    var relationship = aggregate.GetRelationship(partyMembers[i], partyMembers[j]);
                    if (relationship.CanUseCooperationSkill())
                    {
                        pairs.Add((partyMembers[i], partyMembers[j]));
                    }
                }
            }
            
            return pairs;
        }
        
        /// <summary>
        /// パーティで対立技が使用可能なペアを取得
        /// </summary>
        /// <param name="aggregate">関係値集約</param>
        /// <param name="partyMembers">パーティメンバー</param>
        /// <returns>対立技可能なペアのリスト</returns>
        public List<(CharacterId, CharacterId)> GetConflictSkillPairs(RelationshipAggregate aggregate, List<CharacterId> partyMembers)
        {
            var pairs = new List<(CharacterId, CharacterId)>();
            
            for (int i = 0; i < partyMembers.Count; i++)
            {
                for (int j = i + 1; j < partyMembers.Count; j++)
                {
                    var relationship = aggregate.GetRelationship(partyMembers[i], partyMembers[j]);
                    if (relationship.CanUseConflictSkill())
                    {
                        pairs.Add((partyMembers[i], partyMembers[j]));
                    }
                }
            }
            
            return pairs;
        }
        
        /// <summary>
        /// 関係値分布を分析
        /// </summary>
        /// <param name="aggregate">関係値集約</param>
        /// <param name="partyMembers">パーティメンバー</param>
        /// <returns>各レベルの関係値ペア数</returns>
        public Dictionary<RelationshipLevel, int> AnalyzeRelationshipDistribution(RelationshipAggregate aggregate, List<CharacterId> partyMembers)
        {
            var distribution = new Dictionary<RelationshipLevel, int>
            {
                [RelationshipLevel.Intimate] = 0,
                [RelationshipLevel.Friendly] = 0,
                [RelationshipLevel.Neutral] = 0,
                [RelationshipLevel.Cold] = 0,
                [RelationshipLevel.Hostile] = 0
            };
            
            for (int i = 0; i < partyMembers.Count; i++)
            {
                for (int j = i + 1; j < partyMembers.Count; j++)
                {
                    var relationship = aggregate.GetRelationship(partyMembers[i], partyMembers[j]);
                    distribution[relationship.Level]++;
                }
            }
            
            return distribution;
        }
    }
}