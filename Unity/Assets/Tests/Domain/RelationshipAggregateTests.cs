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
            // Given: 初期化された関係値
            _aggregate.InitializeRelationship(_character1, _character2, new RelationshipValue(50));
            _aggregate.InitializeRelationship(_character2, _character1, new RelationshipValue(50));
            
            // When: 保護イベント（char1がchar2を保護）
            _aggregate.HandleBattleEvent(BattleEventType.Protection, _character1, _character2);
            
            // Then: 非対称な関係値変化が発生
            var relationship1to2 = _aggregate.GetRelationship(_character1, _character2); // 保護者
            var relationship2to1 = _aggregate.GetRelationship(_character2, _character1); // 被保護者
            
            Assert.AreEqual(62, relationship1to2.Value); // +12（保護者の変化）
            Assert.AreEqual(75, relationship2to1.Value); // +25（被保護者の変化）
        }

        [Test]
        public void 誤射イベントで相互に関係値が悪化する()
        {
            // Given: 友好レベルの関係値
            _aggregate.InitializeRelationship(_character1, _character2, new RelationshipValue(75));
            _aggregate.InitializeRelationship(_character2, _character1, new RelationshipValue(75));
            
            // When: 誤射イベント
            _aggregate.HandleBattleEvent(BattleEventType.FriendlyFire, _character1, _character2);
            
            // Then: 両方向で25ポイント減少
            var relationship1to2 = _aggregate.GetRelationship(_character1, _character2);
            var relationship2to1 = _aggregate.GetRelationship(_character2, _character1);
            
            Assert.AreEqual(50, relationship1to2.Value); // 75 - 25 = 50
            Assert.AreEqual(50, relationship2to1.Value); // 75 - 25 = 50
            Assert.AreEqual(RelationshipLevel.Neutral, relationship1to2.Level);
            Assert.AreEqual(RelationshipLevel.Neutral, relationship2to1.Level);
        }

        [Test]
        public void 対立イベントで小さな相互悪化が発生する()
        {
            // Given: 普通レベルの関係値
            _aggregate.InitializeRelationship(_character1, _character2, new RelationshipValue(50));
            _aggregate.InitializeRelationship(_character2, _character1, new RelationshipValue(50));
            
            // When: 対立イベント
            _aggregate.HandleBattleEvent(BattleEventType.Rivalry, _character1, _character2);
            
            // Then: 両方向で12ポイント減少
            var relationship1to2 = _aggregate.GetRelationship(_character1, _character2);
            var relationship2to1 = _aggregate.GetRelationship(_character2, _character1);
            
            Assert.AreEqual(38, relationship1to2.Value); // 50 - 12 = 38
            Assert.AreEqual(38, relationship2to1.Value); // 50 - 12 = 38
            Assert.AreEqual(RelationshipLevel.Neutral, relationship1to2.Level); // まだ普通レベル
        }

        [Test]
        public void 支援イベントで小さな相互改善が発生する()
        {
            // Given: 普通レベルの関係値
            _aggregate.InitializeRelationship(_character1, _character2, new RelationshipValue(50));
            _aggregate.InitializeRelationship(_character2, _character1, new RelationshipValue(50));
            
            // When: 支援イベント
            _aggregate.HandleBattleEvent(BattleEventType.Support, _character1, _character2);
            
            // Then: 両方向で12ポイント増加
            var relationship1to2 = _aggregate.GetRelationship(_character1, _character2);
            var relationship2to1 = _aggregate.GetRelationship(_character2, _character1);
            
            Assert.AreEqual(62, relationship1to2.Value); // 50 + 12 = 62
            Assert.AreEqual(62, relationship2to1.Value); // 50 + 12 = 62
            Assert.AreEqual(RelationshipLevel.Neutral, relationship1to2.Level); // まだ普通レベル
        }

        [Test]
        public void GetAllRelationshipsで全ての関係値を取得できる()
        {
            // Given: 複数の関係値を設定
            _aggregate.InitializeRelationship(_character1, _character2, new RelationshipValue(75));
            var character3 = new CharacterId("char3");
            _aggregate.InitializeRelationship(_character1, character3, new RelationshipValue(50));
            
            // When: 全ての関係値を取得
            var allRelationships = _aggregate.GetAllRelationships();
            
            // Then: 設定した関係値がすべて含まれる
            Assert.AreEqual(2, allRelationships.Count);
            Assert.AreEqual(75, allRelationships[(_character1, _character2)].Value);
            Assert.AreEqual(50, allRelationships[(_character1, character3)].Value);
        }

        [Test]
        public void GetAllRelationshipsは新しい辞書インスタンスを返す()
        {
            // Given: 初期化された関係値
            _aggregate.InitializeRelationship(_character1, _character2, new RelationshipValue(75));
            
            // When: 全ての関係値を2回取得
            var relationships1 = _aggregate.GetAllRelationships();
            var relationships2 = _aggregate.GetAllRelationships();
            
            // Then: 異なるインスタンスが返される（イミュータブル）
            Assert.AreNotSame(relationships1, relationships2);
            Assert.AreEqual(relationships1.Count, relationships2.Count);
        }

        [Test]
        public void 複数回のレベル変化イベントが正しく発生する()
        {
            // Given: イベント追跡用の変数
            var eventCount = 0;
            var levelChanges = new List<(RelationshipLevel oldLevel, RelationshipLevel newLevel)>();
            
            _aggregate.RelationshipLevelChanged += (char1, char2, oldLvl, newLvl, reason) =>
            {
                eventCount++;
                levelChanges.Add((oldLvl, newLvl));
            };
            
            _aggregate.InitializeRelationship(_character1, _character2, new RelationshipValue(50));
            
            // When: 段階的に関係値を変化させる
            _aggregate.ModifyRelationship(_character1, _character2, 25, "第1段階"); // 50 → 75 (Neutral → Friendly)
            _aggregate.ModifyRelationship(_character1, _character2, 25, "第2段階"); // 75 → 100 (Friendly → Intimate)
            
            // Then: 2回のレベル変化イベントが発生
            Assert.AreEqual(2, eventCount);
            Assert.AreEqual(RelationshipLevel.Neutral, levelChanges[0].oldLevel);
            Assert.AreEqual(RelationshipLevel.Friendly, levelChanges[0].newLevel);
            Assert.AreEqual(RelationshipLevel.Friendly, levelChanges[1].oldLevel);
            Assert.AreEqual(RelationshipLevel.Intimate, levelChanges[1].newLevel);
        }
    }
}