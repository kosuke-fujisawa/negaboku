using NUnit.Framework;
using Unity.PerformanceTesting;
using NegabokuRPG.Domain.Entities;
using NegabokuRPG.Domain.ValueObjects;
using NegabokuRPG.Domain.Services;
using System.Collections.Generic;
using System.Linq;

namespace NegabokuRPG.Tests.Performance
{
    /// <summary>
    /// 関係値システムのパフォーマンステスト
    /// Unity Performance Testing Frameworkを使用
    /// </summary>
    [TestFixture]
    public class RelationshipPerformanceTests
    {
        private RelationshipAggregate _aggregate;
        private RelationshipDomainService _domainService;
        private List<CharacterId> _testCharacters;

        [SetUp]
        public void SetUp()
        {
            _aggregate = new RelationshipAggregate();
            _domainService = new RelationshipDomainService();
            
            // テスト用キャラクター生成（10人）
            _testCharacters = Enumerable.Range(1, 10)
                .Select(i => new CharacterId($"char{i}"))
                .ToList();
        }

        [Test, Performance]
        public void 関係値初期化_10人_パフォーマンステスト()
        {
            // Given: 10人のキャラクター
            var characters = _testCharacters.Take(10).ToList();
            
            Measure.Method(() =>
            {
                // When: 全ての関係値を初期化
                foreach (var char1 in characters)
                {
                    foreach (var char2 in characters)
                    {
                        if (char1 != char2)
                        {
                            _aggregate.InitializeRelationship(char1, char2, new RelationshipValue(50));
                        }
                    }
                }
            })
            .WarmupCount(5)
            .MeasurementCount(20)
            .IterationsPerMeasurement(100)
            .Run();
            
            // Then: パフォーマンス目標
            // 10人×9関係 = 90関係の初期化が1ms以内で完了すること
        }

        [Test, Performance]
        public void 関係値変更_大量処理_パフォーマンステスト()
        {
            // Given: 初期化された関係値
            var char1 = _testCharacters[0];
            var char2 = _testCharacters[1];
            _aggregate.InitializeRelationship(char1, char2, new RelationshipValue(50));
            
            Measure.Method(() =>
            {
                // When: 関係値を大量に変更
                for (int i = 0; i < 1000; i++)
                {
                    _aggregate.ModifyRelationship(char1, char2, 1, "パフォーマンステスト");
                }
            })
            .WarmupCount(3)
            .MeasurementCount(10)
            .IterationsPerMeasurement(1)
            .Run();
            
            // Then: 1000回の変更が10ms以内で完了すること
        }

        [Test, Performance]
        public void バトルイベント処理_連続実行_パフォーマンステスト()
        {
            // Given: 初期化された関係値
            var char1 = _testCharacters[0];
            var char2 = _testCharacters[1];
            _aggregate.InitializeRelationship(char1, char2, new RelationshipValue(50));
            _aggregate.InitializeRelationship(char2, char1, new RelationshipValue(50));
            
            var eventTypes = new[] { 
                BattleEventType.Cooperation, 
                BattleEventType.Support, 
                BattleEventType.Protection,
                BattleEventType.Rivalry,
                BattleEventType.FriendlyFire
            };
            
            Measure.Method(() =>
            {
                // When: バトルイベントを連続実行
                for (int i = 0; i < 100; i++)
                {
                    var eventType = eventTypes[i % eventTypes.Length];
                    _aggregate.HandleBattleEvent(eventType, char1, char2);
                }
            })
            .WarmupCount(3)
            .MeasurementCount(15)
            .IterationsPerMeasurement(10)
            .Run();
            
            // Then: 100回のイベント処理が5ms以内で完了すること
        }

        [Test, Performance]
        public void ドメインサービス_平均関係値計算_パフォーマンステスト()
        {
            // Given: 10人の関係値を初期化
            foreach (var char1 in _testCharacters)
            {
                foreach (var char2 in _testCharacters)
                {
                    if (char1 != char2)
                    {
                        var randomValue = UnityEngine.Random.Range(-25, 101);
                        _aggregate.InitializeRelationship(char1, char2, new RelationshipValue(randomValue));
                    }
                }
            }
            
            Measure.Method(() =>
            {
                // When: 平均関係値を計算
                var averageRelationship = _domainService.CalculateAveragePartyRelationship(_aggregate, _testCharacters);
            })
            .WarmupCount(5)
            .MeasurementCount(20)
            .IterationsPerMeasurement(100)
            .Run();
            
            // Then: 平均計算が1ms以内で完了すること
        }

        [Test, Performance]
        public void スキル使用可能ペア検索_パフォーマンステスト()
        {
            // Given: 様々なレベルの関係値を設定
            for (int i = 0; i < _testCharacters.Count; i++)
            {
                for (int j = i + 1; j < _testCharacters.Count; j++)
                {
                    // バリエーション豊かな関係値を設定
                    var value = (i * j % 5) switch
                    {
                        0 => 100,  // 親密
                        1 => 75,   // 友好
                        2 => 50,   // 普通
                        3 => 25,   // 冷淡
                        4 => -25,  // 敵対
                        _ => 50
                    };
                    
                    _aggregate.InitializeRelationship(_testCharacters[i], _testCharacters[j], new RelationshipValue(value));
                }
            }
            
            Measure.Method(() =>
            {
                // When: 共闘技使用可能ペアを検索
                var cooperationPairs = _domainService.GetCooperationSkillPairs(_aggregate, _testCharacters);
                var conflictPairs = _domainService.GetConflictSkillPairs(_aggregate, _testCharacters);
            })
            .WarmupCount(3)
            .MeasurementCount(15)
            .IterationsPerMeasurement(50)
            .Run();
            
            // Then: ペア検索が2ms以内で完了すること
        }

        [Test, Performance]
        public void 関係値分布分析_パフォーマンステスト()
        {
            // Given: 複雑な関係値分布を作成
            int index = 0;
            foreach (var char1 in _testCharacters)
            {
                foreach (var char2 in _testCharacters)
                {
                    if (char1 != char2)
                    {
                        // 段階的な分布を作成
                        var level = (RelationshipLevel)(index % 5);
                        var value = level switch
                        {
                            RelationshipLevel.Intimate => 100,
                            RelationshipLevel.Friendly => 75,
                            RelationshipLevel.Neutral => 50,
                            RelationshipLevel.Cold => 25,
                            RelationshipLevel.Hostile => -25,
                            _ => 50
                        };
                        
                        _aggregate.InitializeRelationship(char1, char2, new RelationshipValue(value));
                        index++;
                    }
                }
            }
            
            Measure.Method(() =>
            {
                // When: 関係値分布を分析
                var distribution = _domainService.AnalyzeRelationshipDistribution(_aggregate, _testCharacters);
            })
            .WarmupCount(3)
            .MeasurementCount(15)
            .IterationsPerMeasurement(30)
            .Run();
            
            // Then: 分布分析が3ms以内で完了すること
        }

        [Test, Performance]
        public void 大規模データ_メモリ使用量テスト()
        {
            // Given: 50人のキャラクター（2450の関係値）
            var largeCharacterSet = Enumerable.Range(1, 50)
                .Select(i => new CharacterId($"char{i}"))
                .ToList();
            
            Measure.Method(() =>
            {
                // When: 大規模データを処理
                var largeAggregate = new RelationshipAggregate();
                foreach (var char1 in largeCharacterSet)
                {
                    foreach (var char2 in largeCharacterSet)
                    {
                        if (char1 != char2)
                        {
                            largeAggregate.InitializeRelationship(char1, char2, new RelationshipValue(50));
                        }
                    }
                }
                
                // 平均計算も実行
                var average = _domainService.CalculateAveragePartyRelationship(largeAggregate, largeCharacterSet);
            })
            .WarmupCount(1)
            .MeasurementCount(5)
            .IterationsPerMeasurement(1)
            .Run();
            
            // Then: メモリ効率的に処理されること
        }

        [Test, Performance]
        public void ドメインイベント発行_パフォーマンステスト()
        {
            // Given: イベント発行が多発する状況を作成
            var char1 = _testCharacters[0];
            var char2 = _testCharacters[1];
            _aggregate.InitializeRelationship(char1, char2, new RelationshipValue(25)); // 冷淡レベルから開始
            
            Measure.Method(() =>
            {
                // When: レベル変化を伴う関係値変更を連続実行
                for (int i = 0; i < 10; i++)
                {
                    _aggregate.ModifyRelationship(char1, char2, 25, $"テスト{i}"); // レベル変化が発生
                    _aggregate.ModifyRelationship(char1, char2, -25, $"テスト逆{i}"); // レベル変化が発生
                }
            })
            .WarmupCount(3)
            .MeasurementCount(15)
            .IterationsPerMeasurement(10)
            .Run();
            
            // Then: ドメインイベント発行を含む処理が効率的に実行されること
        }
    }
}