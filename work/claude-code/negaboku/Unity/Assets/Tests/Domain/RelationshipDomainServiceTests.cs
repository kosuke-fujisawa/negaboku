using NUnit.Framework;
using NegabokuRPG.Domain.Services;
using NegabokuRPG.Domain.Entities;
using NegabokuRPG.Domain.ValueObjects;
using System.Collections.Generic;

namespace NegabokuRPG.Tests.Domain
{
    /// <summary>
    /// 関係値ドメインサービスのテスト（TDD - twadaスタイル）
    /// </summary>
    [TestFixture]
    public class RelationshipDomainServiceTests
    {
        private RelationshipDomainService _domainService;
        private RelationshipAggregate _aggregate;
        private CharacterId _char1;
        private CharacterId _char2;
        private CharacterId _char3;

        [SetUp]
        public void SetUp()
        {
            _domainService = new RelationshipDomainService();
            _aggregate = new RelationshipAggregate();
            _char1 = new CharacterId("char1");
            _char2 = new CharacterId("char2");
            _char3 = new CharacterId("char3");
        }

        [Test]
        public void 2人パーティの平均関係値が正しく計算される()
        {
            // Arrange
            _aggregate.InitializeRelationship(_char1, _char2, new RelationshipValue(75));
            var partyMembers = new List<CharacterId> { _char1, _char2 };
            
            // Act
            var average = _domainService.CalculateAveragePartyRelationship(_aggregate, partyMembers);
            
            // Assert
            Assert.AreEqual(75f, average);
        }

        [Test]
        public void 3人パーティの平均関係値が正しく計算される()
        {
            // Arrange
            _aggregate.InitializeRelationship(_char1, _char2, new RelationshipValue(75));
            _aggregate.InitializeRelationship(_char1, _char3, new RelationshipValue(50));
            _aggregate.InitializeRelationship(_char2, _char3, new RelationshipValue(25));
            var partyMembers = new List<CharacterId> { _char1, _char2, _char3 };
            
            // Act
            var average = _domainService.CalculateAveragePartyRelationship(_aggregate, partyMembers);
            
            // Assert
            Assert.AreEqual(50f, average); // (75 + 50 + 25) / 3 = 50
        }

        [Test]
        public void 単独パーティではデフォルト値が返される()
        {
            // Arrange
            var partyMembers = new List<CharacterId> { _char1 };
            
            // Act
            var average = _domainService.CalculateAveragePartyRelationship(_aggregate, partyMembers);
            
            // Assert
            Assert.AreEqual(50f, average); // DEFAULT_VALUE
        }

        [Test]
        public void 共闘技使用可能なペアが正しく特定される()
        {
            // Arrange
            _aggregate.InitializeRelationship(_char1, _char2, new RelationshipValue(100)); // 親密
            _aggregate.InitializeRelationship(_char1, _char3, new RelationshipValue(50));  // 普通
            _aggregate.InitializeRelationship(_char2, _char3, new RelationshipValue(25));  // 冷淡
            var partyMembers = new List<CharacterId> { _char1, _char2, _char3 };
            
            // Act
            var pairs = _domainService.GetCooperationSkillPairs(_aggregate, partyMembers);
            
            // Assert
            Assert.AreEqual(1, pairs.Count);
            Assert.Contains((_char1, _char2), pairs);
        }

        [Test]
        public void 対立技使用可能なペアが正しく特定される()
        {
            // Arrange
            _aggregate.InitializeRelationship(_char1, _char2, new RelationshipValue(-25)); // 敵対
            _aggregate.InitializeRelationship(_char1, _char3, new RelationshipValue(50));  // 普通
            _aggregate.InitializeRelationship(_char2, _char3, new RelationshipValue(75));  // 友好
            var partyMembers = new List<CharacterId> { _char1, _char2, _char3 };
            
            // Act
            var pairs = _domainService.GetConflictSkillPairs(_aggregate, partyMembers);
            
            // Assert
            Assert.AreEqual(1, pairs.Count);
            Assert.Contains((_char1, _char2), pairs);
        }

        [Test]
        public void 関係値分布が正しく分析される()
        {
            // Arrange
            _aggregate.InitializeRelationship(_char1, _char2, new RelationshipValue(100)); // 親密
            _aggregate.InitializeRelationship(_char1, _char3, new RelationshipValue(75));  // 友好
            var char4 = new CharacterId("char4");
            _aggregate.InitializeRelationship(_char2, _char3, new RelationshipValue(50));  // 普通
            _aggregate.InitializeRelationship(_char1, char4, new RelationshipValue(25));   // 冷淡
            _aggregate.InitializeRelationship(_char2, char4, new RelationshipValue(-25));  // 敵対
            var partyMembers = new List<CharacterId> { _char1, _char2, _char3, char4 };
            
            // Act
            var distribution = _domainService.AnalyzeRelationshipDistribution(_aggregate, partyMembers);
            
            // Assert
            Assert.AreEqual(1, distribution[RelationshipLevel.Intimate]); // 1ペア
            Assert.AreEqual(1, distribution[RelationshipLevel.Friendly]);  // 1ペア
            Assert.AreEqual(1, distribution[RelationshipLevel.Neutral]);   // 1ペア
            Assert.AreEqual(1, distribution[RelationshipLevel.Cold]);      // 1ペア
            Assert.AreEqual(1, distribution[RelationshipLevel.Hostile]);   // 1ペア
        }
    }
}