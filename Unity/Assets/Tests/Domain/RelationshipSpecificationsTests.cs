using NUnit.Framework;
using NegabokuRPG.Domain.ValueObjects;
using NegabokuRPG.Domain.Specifications;

namespace NegabokuRPG.Tests.Domain
{
    /// <summary>
    /// 関係値仕様パターンのテスト（DDD戦術設計強化）
    /// </summary>
    [TestFixture]
    public class RelationshipSpecificationsTests
    {
        [Test]
        public void 共闘技使用可能仕様_親密レベルで満たされる()
        {
            // Given: 親密レベル（76ポイント以上）の関係値
            var intimateRelationship = new RelationshipValue(100);
            var spec = RelationshipSpecifications.CanUseCooperationSkill();
            
            // When & Then: 仕様を満たす
            Assert.IsTrue(spec.IsSatisfiedBy(intimateRelationship));
        }
        
        [Test]
        public void 共闘技使用可能仕様_友好レベルで満たされない()
        {
            // Given: 友好レベル（75ポイント）の関係値
            var friendlyRelationship = new RelationshipValue(75);
            var spec = RelationshipSpecifications.CanUseCooperationSkill();
            
            // When & Then: 仕様を満たさない
            Assert.IsFalse(spec.IsSatisfiedBy(friendlyRelationship));
        }
        
        [Test]
        public void 共闘技使用可能仕様_境界値76ポイントで満たされる()
        {
            // Given: 境界値（76ポイント）の関係値
            var boundaryRelationship = new RelationshipValue(76);
            var spec = RelationshipSpecifications.CanUseCooperationSkill();
            
            // When & Then: 仕様を満たす
            Assert.IsTrue(spec.IsSatisfiedBy(boundaryRelationship));
        }
        
        [Test]
        public void 対立技使用可能仕様_敵対レベルで満たされる()
        {
            // Given: 敵対レベル（0ポイント以下）の関係値
            var hostileRelationship = new RelationshipValue(-25);
            var spec = RelationshipSpecifications.CanUseConflictSkill();
            
            // When & Then: 仕様を満たす
            Assert.IsTrue(spec.IsSatisfiedBy(hostileRelationship));
        }
        
        [Test]
        public void 対立技使用可能仕様_冷淡レベルで満たされない()
        {
            // Given: 冷淡レベル（1ポイント）の関係値
            var coldRelationship = new RelationshipValue(1);
            var spec = RelationshipSpecifications.CanUseConflictSkill();
            
            // When & Then: 仕様を満たさない
            Assert.IsFalse(spec.IsSatisfiedBy(coldRelationship));
        }
        
        [Test]
        public void 対立技使用可能仕様_境界値0ポイントで満たされる()
        {
            // Given: 境界値（0ポイント）の関係値
            var boundaryRelationship = new RelationshipValue(0);
            var spec = RelationshipSpecifications.CanUseConflictSkill();
            
            // When & Then: 仕様を満たす
            Assert.IsTrue(spec.IsSatisfiedBy(boundaryRelationship));
        }
        
        [Test]
        public void 親密レベル仕様_親密レベルで満たされる()
        {
            // Given: 親密レベルの関係値
            var intimateRelationship = new RelationshipValue(100);
            var spec = RelationshipSpecifications.IsIntimateLevel();
            
            // When & Then: 仕様を満たす
            Assert.IsTrue(spec.IsSatisfiedBy(intimateRelationship));
        }
        
        [Test]
        public void 親密レベル仕様_友好レベルで満たされない()
        {
            // Given: 友好レベルの関係値
            var friendlyRelationship = new RelationshipValue(75);
            var spec = RelationshipSpecifications.IsIntimateLevel();
            
            // When & Then: 仕様を満たさない
            Assert.IsFalse(spec.IsSatisfiedBy(friendlyRelationship));
        }
        
        [Test]
        public void 敵対レベル仕様_敵対レベルで満たされる()
        {
            // Given: 敵対レベルの関係値
            var hostileRelationship = new RelationshipValue(-25);
            var spec = RelationshipSpecifications.IsHostileLevel();
            
            // When & Then: 仕様を満たす
            Assert.IsTrue(spec.IsSatisfiedBy(hostileRelationship));
        }
        
        [Test]
        public void 敵対レベル仕様_冷淡レベルで満たされない()
        {
            // Given: 冷淡レベルの関係値
            var coldRelationship = new RelationshipValue(1);
            var spec = RelationshipSpecifications.IsHostileLevel();
            
            // When & Then: 仕様を満たさない
            Assert.IsFalse(spec.IsSatisfiedBy(coldRelationship));
        }
        
        [Test]
        public void 安定した関係仕様_普通レベルで満たされる()
        {
            // Given: 普通レベルの関係値
            var neutralRelationship = new RelationshipValue(50);
            var spec = RelationshipSpecifications.IsStableRelationship();
            
            // When & Then: 仕様を満たす
            Assert.IsTrue(spec.IsSatisfiedBy(neutralRelationship));
        }
        
        [Test]
        public void 安定した関係仕様_友好レベルで満たされる()
        {
            // Given: 友好レベルの関係値
            var friendlyRelationship = new RelationshipValue(75);
            var spec = RelationshipSpecifications.IsStableRelationship();
            
            // When & Then: 仕様を満たす
            Assert.IsTrue(spec.IsSatisfiedBy(friendlyRelationship));
        }
        
        [Test]
        public void 安定した関係仕様_親密レベルで満たされない()
        {
            // Given: 親密レベルの関係値
            var intimateRelationship = new RelationshipValue(100);
            var spec = RelationshipSpecifications.IsStableRelationship();
            
            // When & Then: 仕様を満たさない（極端すぎる）
            Assert.IsFalse(spec.IsSatisfiedBy(intimateRelationship));
        }
        
        [Test]
        public void 安定した関係仕様_敵対レベルで満たされない()
        {
            // Given: 敵対レベルの関係値
            var hostileRelationship = new RelationshipValue(-25);
            var spec = RelationshipSpecifications.IsStableRelationship();
            
            // When & Then: 仕様を満たさない（極端すぎる）
            Assert.IsFalse(spec.IsSatisfiedBy(hostileRelationship));
        }
        
        [Test]
        public void 安定した関係仕様_冷淡レベルで満たされない()
        {
            // Given: 冷淡レベルの関係値
            var coldRelationship = new RelationshipValue(1);
            var spec = RelationshipSpecifications.IsStableRelationship();
            
            // When & Then: 仕様を満たさない（不安定）
            Assert.IsFalse(spec.IsSatisfiedBy(coldRelationship));
        }
        
        [Test]
        public void 複数の仕様を組み合わせて使用できる()
        {
            // Given: 親密レベルの関係値
            var intimateRelationship = new RelationshipValue(100);
            
            var cooperationSpec = RelationshipSpecifications.CanUseCooperationSkill();
            var intimateSpec = RelationshipSpecifications.IsIntimateLevel();
            var stableSpec = RelationshipSpecifications.IsStableRelationship();
            
            // When & Then: 複数の仕様を個別に評価
            Assert.IsTrue(cooperationSpec.IsSatisfiedBy(intimateRelationship)); // 共闘技使用可能
            Assert.IsTrue(intimateSpec.IsSatisfiedBy(intimateRelationship));     // 親密レベル
            Assert.IsFalse(stableSpec.IsSatisfiedBy(intimateRelationship));     // 安定した関係ではない
        }
    }
}