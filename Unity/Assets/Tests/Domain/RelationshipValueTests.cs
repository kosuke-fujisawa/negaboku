using NUnit.Framework;
using NegabokuRPG.Domain.ValueObjects;

namespace NegabokuRPG.Tests.Domain
{
    /// <summary>
    /// 関係値オブジェクトのテスト（TDD - twadaスタイル）
    /// </summary>
    [TestFixture]
    public class RelationshipValueTests
    {
        [Test]
        public void 関係値が25増加したとき_普通から友好レベルに変化する()
        {
            // Arrange
            var relationship = new RelationshipValue(50); // 普通レベル
            
            // Act
            var newRelationship = relationship.Add(25);
            
            // Assert
            Assert.AreEqual(75, newRelationship.Value);
            Assert.AreEqual(RelationshipLevel.Friendly, newRelationship.Level);
        }

        [Test]
        public void 関係値が25減少したとき_普通から冷淡レベルに変化する()
        {
            // Arrange
            var relationship = new RelationshipValue(50); // 普通レベル
            
            // Act
            var newRelationship = relationship.Add(-25);
            
            // Assert
            Assert.AreEqual(25, newRelationship.Value);
            Assert.AreEqual(RelationshipLevel.Cold, newRelationship.Level);
        }

        [Test]
        public void 最大値を超える変更を行っても100で制限される()
        {
            // Arrange
            var relationship = new RelationshipValue(90);
            
            // Act
            var newRelationship = relationship.Add(50);
            
            // Assert
            Assert.AreEqual(100, newRelationship.Value);
            Assert.AreEqual(RelationshipLevel.Intimate, newRelationship.Level);
        }

        [Test]
        public void 最小値を下回る変更を行ってもマイナス25で制限される()
        {
            // Arrange
            var relationship = new RelationshipValue(-20);
            
            // Act
            var newRelationship = relationship.Add(-50);
            
            // Assert
            Assert.AreEqual(-25, newRelationship.Value);
            Assert.AreEqual(RelationshipLevel.Hostile, newRelationship.Level);
        }

        [Test]
        public void 親密レベルで共闘技が使用可能()
        {
            // Arrange
            var relationship = new RelationshipValue(100);
            
            // Act & Assert
            Assert.IsTrue(relationship.CanUseCooperationSkill());
            Assert.IsFalse(relationship.CanUseConflictSkill());
        }

        [Test]
        public void 敵対レベルで対立技が使用可能()
        {
            // Arrange
            var relationship = new RelationshipValue(-25);
            
            // Act & Assert
            Assert.IsFalse(relationship.CanUseCooperationSkill());
            Assert.IsTrue(relationship.CanUseConflictSkill());
        }

        [Test]
        public void 同じ値の関係値オブジェクトは等価()
        {
            // Arrange
            var relationship1 = new RelationshipValue(75);
            var relationship2 = new RelationshipValue(75);
            
            // Act & Assert
            Assert.AreEqual(relationship1, relationship2);
        }

        [Test]
        public void 異なる値の関係値オブジェクトは非等価()
        {
            // Arrange
            var relationship1 = new RelationshipValue(75);
            var relationship2 = new RelationshipValue(50);
            
            // Act & Assert
            Assert.AreNotEqual(relationship1, relationship2);
        }

        [Test]
        public void デフォルトコンストラクタで普通レベルが設定される()
        {
            // Arrange & Act
            var relationship = new RelationshipValue();
            
            // Assert
            Assert.AreEqual(50, relationship.Value);
            Assert.AreEqual(RelationshipLevel.Neutral, relationship.Level);
        }
    }
}