using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;
using NegabokuRPG.Core;
using NegabokuRPG.Infrastructure.DependencyInjection;
using NegabokuRPG.Application.Interfaces;
using NegabokuRPG.Domain.Services;
using NegabokuRPG.Domain.Entities;
using NegabokuRPG.Domain.ValueObjects;
using System.Collections.Generic;
using System.Collections;

namespace NegabokuRPG.Tests.Core
{
    /// <summary>
    /// DI対応GameManagerのテスト（DI導入検証）
    /// </summary>
    [TestFixture]
    public class DIGameManagerTests
    {
        private DIGameManager gameManager;
        private GameObject gameManagerObject;
        private MockRelationshipRepository mockRepository;
        private RelationshipDomainService domainService;

        [SetUp]
        public void SetUp()
        {
            // ServiceLocatorをクリア
            ServiceLocator.Reset();
            
            // モックサービスを作成
            mockRepository = new MockRelationshipRepository();
            domainService = new RelationshipDomainService();
            
            // GameManagerを作成
            gameManagerObject = new GameObject("TestDIGameManager");
            gameManager = gameManagerObject.AddComponent<DIGameManager>();
            
            // 依存関係を注入
            gameManager.InjectDependencies(mockRepository, domainService);
        }

        [TearDown]
        public void TearDown()
        {
            if (gameManager != null)
            {
                gameManager.CleanupForTesting();
            }
            
            if (gameManagerObject != null)
            {
                Object.DestroyImmediate(gameManagerObject);
            }
            
            ServiceLocator.Reset();
        }

        [Test]
        public void Initialize_正常に初期化される()
        {
            // Given: セットアップで初期化済み
            
            // When & Then: 初期状態が正しく設定される
            Assert.IsNotNull(gameManager);
            Assert.AreEqual(GameState.MainMenu, gameManager.CurrentGameState);
            Assert.IsNotNull(gameManager.CurrentParty);
            Assert.AreEqual(0, gameManager.CurrentParty.Count);
        }

        [Test]
        public void StartNewGame_新しいゲームが開始される()
        {
            // Given: 初期化されたGameManager
            var playerName = "テストプレイヤー";
            
            // When: 新しいゲームを開始
            gameManager.StartNewGame(playerName);
            
            // Then: ゲーム状態が正しく設定される
            Assert.AreEqual(GameState.Playing, gameManager.CurrentGameState);
            Assert.IsNotNull(gameManager.CurrentGameData);
            Assert.AreEqual(playerName, gameManager.CurrentGameData.playerName);
        }

        [UnityTest]
        public IEnumerator 依存関係注入_正しく動作する()
        {
            // Given: カスタムモックリポジトリ
            var customMockRepository = new MockRelationshipRepository();
            var testCharacterId1 = new CharacterId("test1");
            var testCharacterId2 = new CharacterId("test2");
            
            // リポジトリに初期データを設定
            var aggregate = new RelationshipAggregate();
            aggregate.InitializeRelationship(testCharacterId1, testCharacterId2, new RelationshipValue(75));
            customMockRepository.Save(aggregate);
            
            // When: 依存関係を注入
            gameManager.InjectDependencies(customMockRepository, domainService);
            
            yield return null; // 1フレーム待機
            
            // Then: 注入されたサービスが使用される
            var loadedAggregate = customMockRepository.Load(new List<CharacterId> { testCharacterId1, testCharacterId2 });
            var relationship = loadedAggregate.GetRelationship(testCharacterId1, testCharacterId2);
            
            Assert.AreEqual(75, relationship.Value);
        }

        [Test]
        public void ServiceLocator統合_正しく動作する()
        {
            // Given: ServiceLocatorを初期化
            ServiceLocator.Initialize();
            ServiceLocator.RegisterSingleton<IRelationshipRepository>(mockRepository);
            ServiceLocator.RegisterSingleton(domainService);
            
            // When: サービスを解決
            var resolvedRepository = ServiceLocator.Resolve<IRelationshipRepository>();
            var resolvedDomainService = ServiceLocator.Resolve<RelationshipDomainService>();
            
            // Then: 正しいサービスが取得される
            Assert.AreSame(mockRepository, resolvedRepository);
            Assert.AreSame(domainService, resolvedDomainService);
        }

        [Test]
        public void GetAvailableCharacters_空のリストが返される()
        {
            // Given: 初期化されたGameManager（キャラクターデータなし）
            
            // When: 利用可能なキャラクターを取得
            var availableCharacters = gameManager.GetAvailableCharacters();
            
            // Then: 空のリストが返される
            Assert.IsNotNull(availableCharacters);
            Assert.AreEqual(0, availableCharacters.Count);
        }

        [Test]
        public void GameStateChanged_イベントが正しく発行される()
        {
            // Given: ゲーム状態変更を監視
            GameState oldState = GameState.MainMenu;
            GameState newState = GameState.MainMenu;
            bool eventFired = false;
            
            gameManager.OnGameStateChanged += (oldSt, newSt) =>
            {
                oldState = oldSt;
                newState = newSt;
                eventFired = true;
            };
            
            // When: 新しいゲームを開始（状態変更が発生）
            gameManager.StartNewGame();
            
            // Then: イベントが正しく発行される
            Assert.IsTrue(eventFired);
            Assert.AreEqual(GameState.MainMenu, oldState);
            Assert.AreEqual(GameState.Playing, newState);
        }

        [Test]
        public void CleanupForTesting_状態が正しくクリアされる()
        {
            // Given: ゲームを開始して状態を変更
            gameManager.StartNewGame("テストプレイヤー");
            Assert.AreEqual(GameState.Playing, gameManager.CurrentGameState);
            
            // When: テスト用クリーンアップを実行
            gameManager.CleanupForTesting();
            
            // Then: 状態がクリアされる
            Assert.AreEqual(GameState.MainMenu, gameManager.CurrentGameState);
            Assert.IsNull(gameManager.CurrentGameData);
            Assert.AreEqual(0, gameManager.CurrentParty.Count);
        }

        [Test]
        public void SetParty_無効なサイズで失敗する()
        {
            // Given: 無効なパーティサイズ（3人）
            var invalidParty = new List<string> { "char1", "char2", "char3" };
            
            // When: パーティを設定
            var result = gameManager.SetParty(invalidParty);
            
            // Then: 失敗する
            Assert.IsFalse(result);
            Assert.AreEqual(0, gameManager.CurrentParty.Count);
        }
    }

    /// <summary>
    /// テスト用のモックRelationshipRepository
    /// </summary>
    public class MockRelationshipRepository : IRelationshipRepository
    {
        private RelationshipAggregate _aggregate = new RelationshipAggregate();

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
            return true;
        }

        public void Clear()
        {
            _aggregate = new RelationshipAggregate();
        }
    }
}