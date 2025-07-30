using NUnit.Framework;
using NegabokuRPG.Domain.Entities;
using NegabokuRPG.Domain.ValueObjects;

namespace NegabokuRPG.Tests.Domain
{
    /// <summary>
    /// 関係値集約のテスト（TDD - twadaスタイル）
    /// </summary>
    [TestFixture]
    public class RelationshipAggregateTests
    {
        private RelationshipAggregate _aggregate;
        private CharacterId _character1;
        private CharacterId _character2;

        [SetUp]
        public void SetUp()
        {
            _character1 = new CharacterId("char1");
            _character2 = new CharacterId("char2");
            _aggregate = new RelationshipAggregate();
        }

        [Test]
        public void 新しい関係値を初期化できる()
        {
            // Act
            _aggregate.InitializeRelationship(_character1, _character2, new RelationshipValue(50));
            
            // Assert
            var relationship = _aggregate.GetRelationship(_character1, _character2);
            Assert.AreEqual(50, relationship.Value);
            Assert.AreEqual(RelationshipLevel.Neutral, relationship.Level);
        }

        [Test]
        public void 存在しない関係値を取得すると初期値が返される()
        {
            // Act
            var relationship = _aggregate.GetRelationship(_character1, _character2);
            
            // Assert
            Assert.AreEqual(50, relationship.Value);
            Assert.AreEqual(RelationshipLevel.Neutral, relationship.Level);
        }

        [Test]
        public void 関係値を変更するとイベントが発生する()
        {
            // Arrange
            bool eventFired = false;
            RelationshipLevel oldLevel = RelationshipLevel.Neutral;
            RelationshipLevel newLevel = RelationshipLevel.Neutral;
            
            _aggregate.RelationshipLevelChanged += (char1, char2, oldLvl, newLvl, reason) =>
            {
                eventFired = true;
                oldLevel = oldLvl;
                newLevel = newLvl;
            };
            
            _aggregate.InitializeRelationship(_character1, _character2, new RelationshipValue(50));
            
            // Act
            _aggregate.ModifyRelationship(_character1, _character2, 25, "大きな協力");
            
            // Assert
            Assert.IsTrue(eventFired);
            Assert.AreEqual(RelationshipLevel.Neutral, oldLevel);
            Assert.AreEqual(RelationshipLevel.Friendly, newLevel);
        }

        [Test]
        public void 関係値が変更されてもレベルが同じ場合はイベントが発生しない()
        {
            // Arrange
            bool eventFired = false;
            _aggregate.RelationshipLevelChanged += (char1, char2, oldLvl, newLvl, reason) =>
            {
                eventFired = true;
            };
            
            _aggregate.InitializeRelationship(_character1, _character2, new RelationshipValue(50));
            
            // Act
            _aggregate.ModifyRelationship(_character1, _character2, 10, "小さな変化");
            
            // Assert
            Assert.IsFalse(eventFired);
        }

        [Test]
        public void 双方向の関係値を同時に変更できる()
        {
            // Arrange
            _aggregate.InitializeRelationship(_character1, _character2, new RelationshipValue(50));
            _aggregate.InitializeRelationship(_character2, _character1, new RelationshipValue(50));
            
            // Act
            _aggregate.ModifyMutualRelationship(_character1, _character2, 25, "相互協力");
            
            // Assert
            var relationship1to2 = _aggregate.GetRelationship(_character1, _character2);
            var relationship2to1 = _aggregate.GetRelationship(_character2, _character1);
            
            Assert.AreEqual(75, relationship1to2.Value);
            Assert.AreEqual(75, relationship2to1.Value);
        }

        [Test]
        public void バトルイベントで関係値が適切に変化する()
        {
            // Arrange
            _aggregate.InitializeRelationship(_character1, _character2, new RelationshipValue(50));
            _aggregate.InitializeRelationship(_character2, _character1, new RelationshipValue(50));
            
            // Act - 協力イベント
            _aggregate.HandleBattleEvent(BattleEventType.Cooperation, _character1, _character2);
            
            // Assert
            var relationship1to2 = _aggregate.GetRelationship(_character1, _character2);
            var relationship2to1 = _aggregate.GetRelationship(_character2, _character1);
            
            Assert.AreEqual(75, relationship1to2.Value); // +25
            Assert.AreEqual(75, relationship2to1.Value); // +25
        }

        [Test]
        public void 保護イベントで非対称な関係値変化が発生する()
        {
            // Arrange
            _aggregate.InitializeRelationship(_character1, _character2, new RelationshipValue(50));
            _aggregate.InitializeRelationship(_character2, _character1, new RelationshipValue(50));
            
            // Act - 保護イベント（char1がchar2を保護）
            _aggregate.HandleBattleEvent(BattleEventType.Protection, _character1, _character2);
            
            // Assert
            var relationship1to2 = _aggregate.GetRelationship(_character1, _character2); // 保護者
            var relationship2to1 = _aggregate.GetRelationship(_character2, _character1); // 被保護者
            
            Assert.AreEqual(62, relationship1to2.Value); // +12（保護者の変化）
            Assert.AreEqual(75, relationship2to1.Value); // +25（被保護者の変化）
        }
    }
}