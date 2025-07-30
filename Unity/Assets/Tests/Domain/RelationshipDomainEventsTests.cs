using NUnit.Framework;
using NegabokuRPG.Domain.Entities;
using NegabokuRPG.Domain.ValueObjects;
using NegabokuRPG.Domain.Events;
using System.Linq;

namespace NegabokuRPG.Tests.Domain
{
    /// <summary>
    /// 関係値ドメインイベントのテスト（DDD戦術設計強化）
    /// </summary>
    [TestFixture]
    public class RelationshipDomainEventsTests
    {
        private RelationshipAggregate _aggregate;
        private CharacterId _character1;
        private CharacterId _character2;

        [SetUp]
        public void SetUp()
        {
            _aggregate = new RelationshipAggregate();
            _character1 = new CharacterId("char1");
            _character2 = new CharacterId("char2");
        }

        [Test]
        public void 関係レベル変化時にRelationshipLevelChangedEventが発行される()
        {
            // Given: 普通レベルの関係値
            _aggregate.InitializeRelationship(_character1, _character2, new RelationshipValue(50));
            
            // When: 関係値を変更してレベルを変化させる
            _aggregate.ModifyRelationship(_character1, _character2, 25, "テスト変更");
            
            // Then: RelationshipLevelChangedEventが発行される
            var events = _aggregate.GetDomainEvents<RelationshipLevelChangedEvent>().ToList();
            Assert.AreEqual(1, events.Count);
            
            var evt = events.First();
            Assert.AreEqual(_character1, evt.SourceCharacter);
            Assert.AreEqual(_character2, evt.TargetCharacter);
            Assert.AreEqual(RelationshipLevel.Neutral, evt.PreviousLevel);
            Assert.AreEqual(RelationshipLevel.Friendly, evt.NewLevel);
            Assert.AreEqual(50, evt.PreviousValue);
            Assert.AreEqual(75, evt.NewValue);
            Assert.AreEqual("テスト変更", evt.Reason);
        }

        [Test]
        public void 共闘技解放時にSkillUnlockedEventが発行される()
        {
            // Given: 友好レベル（75ポイント）の関係値
            _aggregate.InitializeRelationship(_character1, _character2, new RelationshipValue(75));
            
            // When: 親密レベル（76ポイント以上）に変化させる
            _aggregate.ModifyRelationship(_character1, _character2, 25, "親密レベル到達");
            
            // Then: SkillUnlockedEventが発行される
            var skillEvents = _aggregate.GetDomainEvents<SkillUnlockedEvent>().ToList();
            Assert.AreEqual(1, skillEvents.Count);
            
            var skillEvent = skillEvents.First();
            Assert.AreEqual(_character1, skillEvent.Character1);
            Assert.AreEqual(_character2, skillEvent.Character2);
            Assert.AreEqual(SkillType.CooperationSkill, skillEvent.UnlockedSkillType);
            Assert.AreEqual(RelationshipLevel.Intimate, skillEvent.CurrentLevel);
            Assert.AreEqual(100, skillEvent.CurrentValue);
        }

        [Test]
        public void 対立技解放時にSkillUnlockedEventが発行される()
        {
            // Given: 冷淡レベル（1ポイント）の関係値
            _aggregate.InitializeRelationship(_character1, _character2, new RelationshipValue(1));
            
            // When: 敵対レベル（0ポイント以下）に変化させる
            _aggregate.ModifyRelationship(_character1, _character2, -25, "敵対レベル到達");
            
            // Then: SkillUnlockedEventが発行される
            var skillEvents = _aggregate.GetDomainEvents<SkillUnlockedEvent>().ToList();
            Assert.AreEqual(1, skillEvents.Count);
            
            var skillEvent = skillEvents.First();
            Assert.AreEqual(_character1, skillEvent.Character1);
            Assert.AreEqual(_character2, skillEvent.Character2);
            Assert.AreEqual(SkillType.ConflictSkill, skillEvent.UnlockedSkillType);
            Assert.AreEqual(RelationshipLevel.Hostile, skillEvent.CurrentLevel);
            Assert.AreEqual(-24, skillEvent.CurrentValue); // 1 - 25 = -24 (最小値-25でクランプ)
        }

        [Test]
        public void レベル変化なしの場合はドメインイベントが発行されない()
        {
            // Given: 普通レベルの関係値
            _aggregate.InitializeRelationship(_character1, _character2, new RelationshipValue(50));
            
            // When: 同一レベル内での小さな変更
            _aggregate.ModifyRelationship(_character1, _character2, 10, "小さな変更");
            
            // Then: ドメインイベントは発行されない
            Assert.AreEqual(0, _aggregate.UncommittedEvents.Count);
        }

        [Test]
        public void 複数の段階的変化で複数のイベントが発行される()
        {
            // Given: 普通レベルの関係値
            _aggregate.InitializeRelationship(_character1, _character2, new RelationshipValue(50));
            
            // When: 段階的に関係値を変更
            _aggregate.ModifyRelationship(_character1, _character2, 25, "第1段階"); // 50 → 75 (Neutral → Friendly)
            _aggregate.ModifyRelationship(_character1, _character2, 25, "第2段階"); // 75 → 100 (Friendly → Intimate + スキル解放)
            
            // Then: 関係レベル変更イベントが2回、スキル解放イベントが1回発行される
            var levelEvents = _aggregate.GetDomainEvents<RelationshipLevelChangedEvent>().ToList();
            var skillEvents = _aggregate.GetDomainEvents<SkillUnlockedEvent>().ToList();
            
            Assert.AreEqual(2, levelEvents.Count);
            Assert.AreEqual(1, skillEvents.Count);
            
            // 第1段階の変化
            Assert.AreEqual(RelationshipLevel.Neutral, levelEvents[0].PreviousLevel);
            Assert.AreEqual(RelationshipLevel.Friendly, levelEvents[0].NewLevel);
            
            // 第2段階の変化
            Assert.AreEqual(RelationshipLevel.Friendly, levelEvents[1].PreviousLevel);
            Assert.AreEqual(RelationshipLevel.Intimate, levelEvents[1].NewLevel);
            
            // スキル解放
            Assert.AreEqual(SkillType.CooperationSkill, skillEvents[0].UnlockedSkillType);
        }

        [Test]
        public void MarkChangesAsCommittedでドメインイベントがクリアされる()
        {
            // Given: 関係値を変更してドメインイベントを発行
            _aggregate.InitializeRelationship(_character1, _character2, new RelationshipValue(50));
            _aggregate.ModifyRelationship(_character1, _character2, 25, "テスト変更");
            
            Assert.AreEqual(1, _aggregate.UncommittedEvents.Count);
            
            // When: 変更をコミット
            _aggregate.MarkChangesAsCommitted();
            
            // Then: ドメインイベントがクリアされる
            Assert.AreEqual(0, _aggregate.UncommittedEvents.Count);
        }

        [Test]
        public void RelationshipLevelChangedEventのIsImprovementが正しく動作する()
        {
            // Given: 改善イベントと悪化イベント
            var improvementEvent = new RelationshipLevelChangedEvent(
                _character1, _character2,
                RelationshipLevel.Neutral, RelationshipLevel.Friendly,
                50, 75, "改善");
                
            var deteriorationEvent = new RelationshipLevelChangedEvent(
                _character1, _character2,
                RelationshipLevel.Friendly, RelationshipLevel.Neutral,
                75, 50, "悪化");
            
            // When & Then: IsImprovementが正しく判定される
            Assert.IsTrue(improvementEvent.IsImprovement());
            Assert.IsFalse(deteriorationEvent.IsImprovement());
        }

        [Test]
        public void RelationshipLevelChangedEventのIsSignificantChangeが正しく動作する()
        {
            // Given: 大きな変化と小さな変化のイベント
            var significantEvent = new RelationshipLevelChangedEvent(
                _character1, _character2,
                RelationshipLevel.Neutral, RelationshipLevel.Intimate,
                50, 100, "大きな変化");
                
            var minorEvent = new RelationshipLevelChangedEvent(
                _character1, _character2,
                RelationshipLevel.Neutral, RelationshipLevel.Friendly,
                50, 75, "小さな変化");
            
            // When & Then: IsSignificantChangeが正しく判定される
            Assert.IsTrue(significantEvent.IsSignificantChange()); // 50ポイント変化（2段階以上）
            Assert.IsFalse(minorEvent.IsSignificantChange()); // 25ポイント変化（1段階）
        }
    }
}