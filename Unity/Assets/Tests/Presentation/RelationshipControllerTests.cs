using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;
using NegabokuRPG.Presentation.Controllers;
using NegabokuRPG.Application.Interfaces;
using NegabokuRPG.Domain.Services;
using NegabokuRPG.Domain.ValueObjects;
using NegabokuRPG.Domain.Entities;
using System;
using System.Collections.Generic;

namespace NegabokuRPG.Tests.Presentation
{
    /// <summary>
    /// RelationshipControllerのテスト
    /// タイトカップリング問題が解決されているかを確認
    /// </summary>
    public class RelationshipControllerTests
    {
        private RelationshipController _controller;
        private MockRelationshipRepository _mockRepository;
        private RelationshipDomainService _domainService;
        
        [SetUp]
        public void SetUp()
        {
            // GameObjectとコンポーネントを作成
            var gameObject = new GameObject("TestRelationshipController");
            _controller = gameObject.AddComponent<RelationshipController>();
            
            // モックリポジトリを作成
            _mockRepository = new MockRelationshipRepository();
            _domainService = new RelationshipDomainService();
            
            // 依存性注入でテスト
            _controller.Initialize(_mockRepository, _domainService);
        }
        
        [TearDown]
        public void TearDown()
        {
            if (_controller != null)
            {
                UnityEngine.Object.DestroyImmediate(_controller.gameObject);
            }
        }
        
        [Test]
        public void Initialize_正常なパラメータ_初期化が成功する()
        {
            // Arrange
            var repository = new MockRelationshipRepository();
            var domainService = new RelationshipDomainService();
            
            // Act
            _controller.Initialize(repository, domainService);
            
            // Assert
            Assert.IsTrue(_controller.IsInitialized);
        }
        
        [Test]
        public void Initialize_Nullリポジトリ_ArgumentNullExceptionが発生()
        {
            // Arrange
            var domainService = new RelationshipDomainService();
            
            // Act & Assert
            Assert.Throws<ArgumentNullException>(() => 
                _controller.Initialize(null, domainService));
        }
        
        [Test]
        public void Initialize_Nullドメインサービス_ArgumentNullExceptionが発生()
        {
            // Arrange
            var repository = new MockRelationshipRepository();
            
            // Act & Assert
            Assert.Throws<ArgumentNullException>(() => 
                _controller.Initialize(repository, null));
        }
        
        [Test]
        public void GetRelationship_初期化前_InvalidOperationExceptionが発生()
        {
            // Arrange
            var uninitializedController = new GameObject().AddComponent<RelationshipController>();
            
            // Act & Assert
            Assert.Throws<InvalidOperationException>(() => 
                uninitializedController.GetRelationship("char1", "char2"));
                
            UnityEngine.Object.DestroyImmediate(uninitializedController.gameObject);
        }
        
        [Test]
        public void GetRelationship_正常なパラメータ_関係値が取得できる()
        {
            // Arrange
            var char1Id = "char1";
            var char2Id = "char2";
            var expectedValue = new RelationshipValue(75);
            _mockRepository.SetRelationship(new CharacterId(char1Id), new CharacterId(char2Id), expectedValue);
            
            // Act
            var result = _controller.GetRelationship(char1Id, char2Id);
            
            // Assert
            Assert.AreEqual(expectedValue.Value, result.Value);
            Assert.AreEqual(expectedValue.Level, result.Level);
        }
        
        [Test]
        public void ModifyRelationship_正常なパラメータ_関係値が変更される()
        {
            // Arrange
            var char1Id = "char1";
            var char2Id = "char2";
            var initialValue = new RelationshipValue(50);
            var change = 25;
            var reason = "テスト変更";
            
            _mockRepository.SetRelationship(new CharacterId(char1Id), new CharacterId(char2Id), initialValue);
            
            // Act
            var result = _controller.ModifyRelationship(char1Id, char2Id, change, reason);
            
            // Assert
            Assert.AreEqual(75, result.Value);
            Assert.AreEqual(RelationshipLevel.Friendly, result.Level);
        }
        
        [Test]
        public void HandleBattleEvent_協力イベント_関係値が正しく変更される()
        {
            // Arrange
            var char1Id = "char1";
            var char2Id = "char2";
            var initialValue = new RelationshipValue(50);
            
            _mockRepository.SetRelationship(new CharacterId(char1Id), new CharacterId(char2Id), initialValue);
            _mockRepository.SetRelationship(new CharacterId(char2Id), new CharacterId(char1Id), initialValue);
            
            // Act
            var result = _controller.HandleBattleEvent(BattleEventType.Cooperation, char1Id, char2Id);
            
            // Assert
            Assert.AreEqual(75, result.Item1.Value); // char1 → char2
            Assert.AreEqual(75, result.Item2.Value); // char2 → char1
        }
    }
    
    /// <summary>
    /// テスト用のモックリポジトリ
    /// IRelationshipRepositoryインターフェースに準拠
    /// </summary>
    public class MockRelationshipRepository : IRelationshipRepository
    {
        private RelationshipAggregate _aggregate;
        
        public MockRelationshipRepository()
        {
            _aggregate = new RelationshipAggregate();
        }
        
        public void Save(RelationshipAggregate aggregate)
        {
            _aggregate = aggregate;
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
            return true; // テスト用では常にtrue
        }
        
        public void Clear()
        {
            _aggregate = new RelationshipAggregate();
        }
        
        /// <summary>
        /// テスト用ヘルパーメソッド
        /// </summary>
        public void SetRelationship(CharacterId char1, CharacterId char2, RelationshipValue value)
        {
            _aggregate.InitializeRelationship(char1, char2, value);
        }
    }
}