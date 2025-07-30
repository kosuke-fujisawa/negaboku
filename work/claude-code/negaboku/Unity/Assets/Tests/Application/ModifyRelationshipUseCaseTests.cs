using NUnit.Framework;
using NegabokuRPG.Application.UseCases;
using NegabokuRPG.Application.Interfaces;
using NegabokuRPG.Domain.Services;
using NegabokuRPG.Domain.Entities;
using NegabokuRPG.Domain.ValueObjects;
using System.Collections.Generic;

namespace NegabokuRPG.Tests.Application
{
    /// <summary>
    /// 関係値変更ユースケースのテスト（TDD - twadaスタイル）
    /// </summary>
    [TestFixture]
    public class ModifyRelationshipUseCaseTests
    {
        private ModifyRelationshipUseCase _useCase;
        private TestRelationshipRepository _repository;
        private RelationshipDomainService _domainService;
        private CharacterId _char1;
        private CharacterId _char2;

        [SetUp]
        public void SetUp()
        {
            _repository = new TestRelationshipRepository();
            _domainService = new RelationshipDomainService();
            _useCase = new ModifyRelationshipUseCase(_repository, _domainService);
            _char1 = new CharacterId("char1");
            _char2 = new CharacterId("char2");
        }

        [Test]
        public void 関係値変更が正しく実行される()
        {
            // Act
            var result = _useCase.Execute(_char1, _char2, 25, "テスト変更");
            
            // Assert
            Assert.AreEqual(75, result.Value);
            Assert.AreEqual(RelationshipLevel.Friendly, result.Level);
            Assert.IsTrue(_repository.SaveCalled);
        }

        [Test]
        public void 双方向関係値変更が正しく実行される()
        {
            // Act
            var (result1, result2) = _useCase.ExecuteMutual(_char1, _char2, 25, "相互変更");
            
            // Assert
            Assert.AreEqual(75, result1.Value);
            Assert.AreEqual(75, result2.Value);
            Assert.IsTrue(_repository.SaveCalled);
        }

        [Test]
        public void バトルイベント処理が正しく実行される()
        {
            // Act
            var (result1, result2) = _useCase.ExecuteBattleEvent(
                BattleEventType.Cooperation, _char1, _char2);
            
            // Assert
            Assert.AreEqual(75, result1.Value); // +25
            Assert.AreEqual(75, result2.Value); // +25
            Assert.IsTrue(_repository.SaveCalled);
        }

        [Test]
        public void 保護イベントで非対称変化が正しく処理される()
        {
            // Act
            var (protector, beneficiary) = _useCase.ExecuteBattleEvent(
                BattleEventType.Protection, _char1, _char2);
            
            // Assert
            Assert.AreEqual(62, protector.Value);    // +12（保護者）
            Assert.AreEqual(75, beneficiary.Value);  // +25（被保護者）
            Assert.IsTrue(_repository.SaveCalled);
        }
    }

    /// <summary>
    /// テスト用リポジトリの実装
    /// </summary>
    public class TestRelationshipRepository : IRelationshipRepository
    {
        private RelationshipAggregate _aggregate = new RelationshipAggregate();
        public bool SaveCalled { get; private set; }

        public void Save(RelationshipAggregate aggregate)
        {
            _aggregate = aggregate;
            SaveCalled = true;
        }

        public RelationshipAggregate Load(List<CharacterId> characterIds)
        {
            // 初期値で関係値を設定
            foreach (var char1 in characterIds)
            {
                foreach (var char2 in characterIds)
                {
                    if (char1 != char2)
                    {
                        var existing = _aggregate.GetRelationship(char1, char2);
                        if (existing.Value == RelationshipValue.DEFAULT_VALUE)
                        {
                            _aggregate.InitializeRelationship(char1, char2, new RelationshipValue());
                        }
                    }
                }
            }
            return _aggregate;
        }

        public bool Exists(CharacterId character1, CharacterId character2)
        {
            return true;
        }

        public void Clear()
        {
            _aggregate = new RelationshipAggregate();
            SaveCalled = false;
        }
    }
}