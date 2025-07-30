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
            // Given: 普通レベルの関係値オブジェクト
            var relationship = new RelationshipValue(50);
            
            // When: 25ポイント増加させる
            var newRelationship = relationship.Add(25);
            
            // Then: 友好レベルに変化する
            Assert.AreEqual(75, newRelationship.Value);
            Assert.AreEqual(RelationshipLevel.Friendly, newRelationship.Level);
        }

        [Test]
        public void 関係値が25減少したとき_普通から冷淡レベルに変化する()
        {
            // Given: 普通レベルの関係値オブジェクト
            var relationship = new RelationshipValue(50);
            
            // When: 25ポイント減少させる
            var newRelationship = relationship.Add(-25);
            
            // Then: 冷淡レベルに変化する
            Assert.AreEqual(25, newRelationship.Value);
            Assert.AreEqual(RelationshipLevel.Cold, newRelationship.Level);
        }

        [Test]
        public void 最大値を超える変更を行っても100で制限される()
        {
            // Given: 90ポイントの関係値オブジェクト
            var relationship = new RelationshipValue(90);
            
            // When: 50ポイント増加（最大値超過）させる
            var newRelationship = relationship.Add(50);
            
            // Then: 最大値100で制限される
            Assert.AreEqual(100, newRelationship.Value);
            Assert.AreEqual(RelationshipLevel.Intimate, newRelationship.Level);
        }

        [Test]
        public void 最小値を下回る変更を行ってもマイナス25で制限される()
        {
            // Given: -20ポイントの関係値オブジェクト
            var relationship = new RelationshipValue(-20);
            
            // When: 50ポイント減少（最小値下回り）させる
            var newRelationship = relationship.Add(-50);
            
            // Then: 最小値-25で制限される
            Assert.AreEqual(-25, newRelationship.Value);
            Assert.AreEqual(RelationshipLevel.Hostile, newRelationship.Level);
        }

        [Test]
        public void 親密レベルで共闘技が使用可能()
        {
            // Given: 親密レベル（100ポイント）の関係値
            var relationship = new RelationshipValue(100);
            
            // When & Then: 共闘技は使用可能、対立技は使用不可
            Assert.IsTrue(relationship.CanUseCooperationSkill());
            Assert.IsFalse(relationship.CanUseConflictSkill());
        }

        [Test]
        public void 敵対レベルで対立技が使用可能()
        {
            // Given: 敵対レベル（-25ポイント）の関係値
            var relationship = new RelationshipValue(-25);
            
            // When & Then: 対立技は使用可能、共闘技は使用不可
            Assert.IsFalse(relationship.CanUseCooperationSkill());
            Assert.IsTrue(relationship.CanUseConflictSkill());
        }

        [Test]
        public void 同じ値の関係値オブジェクトは等価()
        {
            // Given: 同じ値（75ポイント）の関係値オブジェクト2つ
            var relationship1 = new RelationshipValue(75);
            var relationship2 = new RelationshipValue(75);
            
            // When & Then: 等価である
            Assert.AreEqual(relationship1, relationship2);
        }

        [Test]
        public void 異なる値の関係値オブジェクトは非等価()
        {
            // Given: 異なる値（75と50ポイント）の関係値オブジェクト2つ
            var relationship1 = new RelationshipValue(75);
            var relationship2 = new RelationshipValue(50);
            
            // When & Then: 非等価である
            Assert.AreNotEqual(relationship1, relationship2);
        }

        [Test]
        public void デフォルトコンストラクタで普通レベルが設定される()
        {
            // Given & When: デフォルトコンストラクタで関係値オブジェクトを作成
            var relationship = new RelationshipValue();
            
            // Then: 普通レベル（50ポイント）が設定される
            Assert.AreEqual(50, relationship.Value);
            Assert.AreEqual(RelationshipLevel.Neutral, relationship.Level);
        }

        [Test]
        public void 境界値テスト_76ポイントで親密レベルの下限()
        {
            // Given: 76ポイントの関係値オブジェクト
            var relationship = new RelationshipValue(76);
            
            // When & Then: 親密レベルの下限であることを確認
            Assert.AreEqual(RelationshipLevel.Intimate, relationship.Level);
            Assert.IsTrue(relationship.CanUseCooperationSkill());
        }

        [Test]
        public void 境界値テスト_75ポイントで友好レベルの上限()
        {
            // Given: 75ポイントの関係値オブジェクト
            var relationship = new RelationshipValue(75);
            
            // When & Then: 友好レベルの上限であることを確認
            Assert.AreEqual(RelationshipLevel.Friendly, relationship.Level);
            Assert.IsFalse(relationship.CanUseCooperationSkill());
        }

        [Test]
        public void 境界値テスト_0ポイントで敵対レベルの上限()
        {
            // Given: 0ポイントの関係値オブジェクト
            var relationship = new RelationshipValue(0);
            
            // When & Then: 敵対レベルの上限であることを確認
            Assert.AreEqual(RelationshipLevel.Hostile, relationship.Level);
            Assert.IsTrue(relationship.CanUseConflictSkill());
        }

        [Test]
        public void 境界値テスト_1ポイントで冷淡レベルの下限()
        {
            // Given: 1ポイントの関係値オブジェクト
            var relationship = new RelationshipValue(1);
            
            // When & Then: 冷淡レベルの下限であることを確認
            Assert.AreEqual(RelationshipLevel.Cold, relationship.Level);
            Assert.IsFalse(relationship.CanUseConflictSkill());
        }

        [Test]
        public void 不変性テスト_Addメソッドは新しいインスタンスを返す()
        {
            // Given: 元の関係値オブジェクト
            var original = new RelationshipValue(50);
            
            // When: Addメソッドで変更
            var modified = original.Add(25);
            
            // Then: 元のオブジェクトは変更されず、新しいインスタンスが返される
            Assert.AreEqual(50, original.Value);
            Assert.AreEqual(75, modified.Value);
            Assert.AreNotSame(original, modified);
        }

        [Test]
        public void 極値テスト_ゼロ変更では同じ値が維持される()
        {
            // Given: 任意の関係値オブジェクト
            var relationship = new RelationshipValue(75);
            
            // When: ゼロポイント変更
            var result = relationship.Add(0);
            
            // Then: 値は変わらない
            Assert.AreEqual(75, result.Value);
            Assert.AreEqual(RelationshipLevel.Friendly, result.Level);
        }

        [Test]
        public void ハッシュコードテスト_同じ値のオブジェクトは同じハッシュコード()
        {
            // Given: 同じ値の関係値オブジェクト2つ
            var relationship1 = new RelationshipValue(75);
            var relationship2 = new RelationshipValue(75);
            
            // When & Then: 同じハッシュコードを持つ
            Assert.AreEqual(relationship1.GetHashCode(), relationship2.GetHashCode());
        }

        [Test]
        public void AddStepsメソッド_1段階増加で25ポイント増加()
        {
            // Given: 50ポイントの関係値オブジェクト
            var relationship = new RelationshipValue(50);
            
            // When: 1段階増加
            var result = relationship.AddSteps(1.0f);
            
            // Then: 25ポイント増加して75ポイントになる
            Assert.AreEqual(75, result.Value);
            Assert.AreEqual(RelationshipLevel.Friendly, result.Level);
        }

        [Test]
        public void AddStepsメソッド_半段階増加で12ポイント増加()
        {
            // Given: 50ポイントの関係値オブジェクト
            var relationship = new RelationshipValue(50);
            
            // When: 0.5段階増加
            var result = relationship.AddSteps(0.5f);
            
            // Then: 約12-13ポイント増加
            Assert.AreEqual(62, result.Value); // Math.Round(25 * 0.5) = 12, 50 + 12 = 62
            Assert.AreEqual(RelationshipLevel.Neutral, result.Level);
        }

        [Test]
        public void AddStepsメソッド_マイナス段階で減少()
        {
            // Given: 75ポイントの関係値オブジェクト
            var relationship = new RelationshipValue(75);
            
            // When: -1段階変化
            var result = relationship.AddSteps(-1.0f);
            
            // Then: 25ポイント減少して50ポイントになる
            Assert.AreEqual(50, result.Value);
            Assert.AreEqual(RelationshipLevel.Neutral, result.Level);
        }

        [Test]
        public void ToStringメソッド_値とレベルが正しく表示される()
        {
            // Given: 75ポイントの関係値オブジェクト
            var relationship = new RelationshipValue(75);
            
            // When: ToString呼び出し
            var result = relationship.ToString();
            
            // Then: 値とレベルが含まれる文字列が返される
            Assert.AreEqual("RelationshipValue(75, Friendly)", result);
        }

        [Test]
        public void 範囲外値テスト_200を指定しても100でクランプされる()
        {
            // Given & When: 範囲外の値でインスタンス作成
            var relationship = new RelationshipValue(200);
            
            // Then: 最大値100でクランプされる
            Assert.AreEqual(100, relationship.Value);
            Assert.AreEqual(RelationshipLevel.Intimate, relationship.Level);
        }

        [Test]
        public void 範囲外値テスト_マイナス100を指定してもマイナス25でクランプされる()
        {
            // Given & When: 範囲外の値でインスタンス作成
            var relationship = new RelationshipValue(-100);
            
            // Then: 最小値-25でクランプされる
            Assert.AreEqual(-25, relationship.Value);
            Assert.AreEqual(RelationshipLevel.Hostile, relationship.Level);
        }
    }
}