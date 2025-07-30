using NegabokuRPG.Domain.ValueObjects;

namespace NegabokuRPG.Domain.Specifications
{
    /// <summary>
    /// 関係値に関する仕様クラス群
    /// ビジネスルールを明示的に表現
    /// </summary>
    public static class RelationshipSpecifications
    {
        /// <summary>
        /// 共闘技使用可能仕様
        /// </summary>
        public static ISpecification<RelationshipValue> CanUseCooperationSkill()
        {
            return new CooperationSkillAvailableSpecification();
        }
        
        /// <summary>
        /// 対立技使用可能仕様
        /// </summary>
        public static ISpecification<RelationshipValue> CanUseConflictSkill()
        {
            return new ConflictSkillAvailableSpecification();
        }
        
        /// <summary>
        /// 親密レベル仕様
        /// </summary>
        public static ISpecification<RelationshipValue> IsIntimateLevel()
        {
            return new IntimateRelationshipSpecification();
        }
        
        /// <summary>
        /// 敵対レベル仕様
        /// </summary>
        public static ISpecification<RelationshipValue> IsHostileLevel()
        {
            return new HostileRelationshipSpecification();
        }
        
        /// <summary>
        /// 安定した関係仕様（友好以上、冷淡以下を除く）
        /// </summary>
        public static ISpecification<RelationshipValue> IsStableRelationship()
        {
            return new StableRelationshipSpecification();
        }
    }
    
    /// <summary>
    /// 共闘技使用可能仕様の実装
    /// </summary>
    internal class CooperationSkillAvailableSpecification : ISpecification<RelationshipValue>
    {
        public bool IsSatisfiedBy(RelationshipValue candidate)
        {
            return candidate.Value >= RelationshipValue.COOPERATION_THRESHOLD;
        }
    }
    
    /// <summary>
    /// 対立技使用可能仕様の実装
    /// </summary>
    internal class ConflictSkillAvailableSpecification : ISpecification<RelationshipValue>
    {
        public bool IsSatisfiedBy(RelationshipValue candidate)
        {
            return candidate.Value <= RelationshipValue.CONFLICT_THRESHOLD;
        }
    }
    
    /// <summary>
    /// 親密レベル仕様の実装
    /// </summary>
    internal class IntimateRelationshipSpecification : ISpecification<RelationshipValue>
    {
        public bool IsSatisfiedBy(RelationshipValue candidate)
        {
            return candidate.Level == RelationshipLevel.Intimate;
        }
    }
    
    /// <summary>
    /// 敵対レベル仕様の実装
    /// </summary>
    internal class HostileRelationshipSpecification : ISpecification<RelationshipValue>
    {
        public bool IsSatisfiedBy(RelationshipValue candidate)
        {
            return candidate.Level == RelationshipLevel.Hostile;
        }
    }
    
    /// <summary>
    /// 安定した関係仕様の実装
    /// 普通レベル（26-75ポイント）を安定とみなす
    /// </summary>
    internal class StableRelationshipSpecification : ISpecification<RelationshipValue>
    {
        public bool IsSatisfiedBy(RelationshipValue candidate)
        {
            return candidate.Level == RelationshipLevel.Neutral || 
                   candidate.Level == RelationshipLevel.Friendly;
        }
    }
}