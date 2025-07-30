using System;
using System.Collections.Generic;
using System.Diagnostics;
using UnityEngine;
using NegabokuRPG.Domain.Entities;
using NegabokuRPG.Domain.ValueObjects;
using NegabokuRPG.Domain.Services;

namespace NegabokuRPG.Utilities.Performance
{
    /// <summary>
    /// パフォーマンスプロファイラー
    /// Unity Editor上でのパフォーマンス測定と分析
    /// </summary>
    public static class PerformanceProfiler
    {
        /// <summary>
        /// パフォーマンス測定結果
        /// </summary>
        public struct ProfileResult
        {
            public string TestName;
            public double ElapsedMilliseconds;
            public long MemoryUsedBytes;
            public int IterationCount;
            public double AverageMilliseconds => ElapsedMilliseconds / IterationCount;
            
            public override string ToString()
            {
                return $"{TestName}: {ElapsedMilliseconds:F2}ms total, {AverageMilliseconds:F4}ms avg, {MemoryUsedBytes} bytes, {IterationCount} iterations";
            }
        }
        
        /// <summary>
        /// 関係値システムの包括的パフォーマンステスト
        /// </summary>
        /// <param name="characterCount">テスト対象キャラクター数</param>
        /// <param name="iterations">反復回数</param>
        /// <returns>パフォーマンス結果リスト</returns>
        public static List<ProfileResult> ProfileRelationshipSystem(int characterCount = 10, int iterations = 1000)
        {
            var results = new List<ProfileResult>();
            
            // テスト用データ準備
            var characters = new List<CharacterId>();
            for (int i = 1; i <= characterCount; i++)
            {
                characters.Add(new CharacterId($"char{i}"));
            }
            
            var aggregate = new RelationshipAggregate();
            var domainService = new RelationshipDomainService();
            
            // 1. 関係値初期化テスト
            results.Add(ProfileMethod("関係値初期化", () =>
            {
                var testAggregate = new RelationshipAggregate();
                foreach (var char1 in characters)
                {
                    foreach (var char2 in characters)
                    {
                        if (char1 != char2)
                        {
                            testAggregate.InitializeRelationship(char1, char2, new RelationshipValue(50));
                        }
                    }
                }
            }, 10));
            
            // 初期化実行
            foreach (var char1 in characters)
            {
                foreach (var char2 in characters)
                {
                    if (char1 != char2)
                    {
                        aggregate.InitializeRelationship(char1, char2, new RelationshipValue(50));
                    }
                }
            }
            
            // 2. 関係値変更テスト
            results.Add(ProfileMethod("関係値変更", () =>
            {
                var char1 = characters[0];
                var char2 = characters[1];
                aggregate.ModifyRelationship(char1, char2, 1, "パフォーマンステスト");
            }, iterations));
            
            // 3. バトルイベント処理テスト
            var eventTypes = new[] { 
                BattleEventType.Cooperation, 
                BattleEventType.Support, 
                BattleEventType.Protection 
            };
            
            results.Add(ProfileMethod("バトルイベント処理", () =>
            {
                var char1 = characters[0];
                var char2 = characters[1];
                var eventType = eventTypes[UnityEngine.Random.Range(0, eventTypes.Length)];
                aggregate.HandleBattleEvent(eventType, char1, char2);
            }, iterations / 10));
            
            // 4. 平均関係値計算テスト
            results.Add(ProfileMethod("平均関係値計算", () =>
            {
                var average = domainService.CalculateAveragePartyRelationship(aggregate, characters);
            }, iterations / 5));
            
            // 5. スキル使用可能ペア検索テスト
            results.Add(ProfileMethod("スキルペア検索", () =>
            {
                var cooperationPairs = domainService.GetCooperationSkillPairs(aggregate, characters);
                var conflictPairs = domainService.GetConflictSkillPairs(aggregate, characters);
            }, iterations / 10));
            
            // 6. 関係値分布分析テスト
            results.Add(ProfileMethod("関係値分布分析", () =>
            {
                var distribution = domainService.AnalyzeRelationshipDistribution(aggregate, characters);
            }, iterations / 20));
            
            return results;
        }
        
        /// <summary>
        /// メソッドのパフォーマンスを測定
        /// </summary>
        /// <param name="testName">テスト名</param>
        /// <param name="action">測定対象メソッド</param>
        /// <param name="iterations">反復回数</param>
        /// <returns>測定結果</returns>
        public static ProfileResult ProfileMethod(string testName, Action action, int iterations = 1000)
        {
            // ガベージコレクション実行
            GC.Collect();
            GC.WaitForPendingFinalizers();
            GC.Collect();
            
            var initialMemory = GC.GetTotalMemory(false);
            var stopwatch = Stopwatch.StartNew();
            
            // ウォームアップ
            for (int i = 0; i < Math.Min(iterations / 10, 100); i++)
            {
                action();
            }
            
            // 実測定
            stopwatch.Restart();
            for (int i = 0; i < iterations; i++)
            {
                action();
            }
            stopwatch.Stop();
            
            var finalMemory = GC.GetTotalMemory(false);
            var memoryUsed = Math.Max(0, finalMemory - initialMemory);
            
            return new ProfileResult
            {
                TestName = testName,
                ElapsedMilliseconds = stopwatch.Elapsed.TotalMilliseconds,
                MemoryUsedBytes = memoryUsed,
                IterationCount = iterations
            };
        }
        
        /// <summary>
        /// パフォーマンス結果をUnityコンソールに出力
        /// </summary>
        /// <param name="results">測定結果リスト</param>
        public static void LogResults(List<ProfileResult> results)
        {
            UnityEngine.Debug.Log("=== パフォーマンステスト結果 ===");
            
            foreach (var result in results)
            {
                var logMessage = result.ToString();
                
                // パフォーマンス警告の判定
                if (result.AverageMilliseconds > 1.0) // 1ms以上は警告
                {
                    UnityEngine.Debug.LogWarning($"⚠️ {logMessage}");
                }
                else if (result.AverageMilliseconds > 0.1) // 0.1ms以上は注意
                {
                    UnityEngine.Debug.Log($"⚡ {logMessage}");
                }
                else
                {
                    UnityEngine.Debug.Log($"✅ {logMessage}");
                }
            }
            
            // 総合評価
            var totalTime = 0.0;
            var totalMemory = 0L;
            
            foreach (var result in results)
            {
                totalTime += result.ElapsedMilliseconds;
                totalMemory += result.MemoryUsedBytes;
            }
            
            UnityEngine.Debug.Log($"総合時間: {totalTime:F2}ms, 総使用メモリ: {totalMemory} bytes");
        }
        
        /// <summary>
        /// Unity Editor向けのパフォーマンステスト実行
        /// </summary>
        [UnityEngine.ContextMenu("Run Performance Test")]
        public static void RunEditorPerformanceTest()
        {
            UnityEngine.Debug.Log("関係値システムのパフォーマンステストを開始...");
            
            var results = ProfileRelationshipSystem(10, 1000);
            LogResults(results);
            
            UnityEngine.Debug.Log("パフォーマンステスト完了");
        }
        
        /// <summary>
        /// メモリ効率テスト
        /// </summary>
        /// <param name="characterCount">キャラクター数</param>
        /// <returns>メモリ使用量情報</returns>
        public static MemoryProfileResult ProfileMemoryUsage(int characterCount = 50)
        {
            GC.Collect();
            GC.WaitForPendingFinalizers();
            GC.Collect();
            
            var initialMemory = GC.GetTotalMemory(false);
            
            // 大規模データ作成
            var characters = new List<CharacterId>();
            for (int i = 1; i <= characterCount; i++)
            {
                characters.Add(new CharacterId($"char{i}"));
            }
            
            var aggregate = new RelationshipAggregate();
            foreach (var char1 in characters)
            {
                foreach (var char2 in characters)
                {
                    if (char1 != char2)
                    {
                        aggregate.InitializeRelationship(char1, char2, new RelationshipValue(50));
                    }
                }
            }
            
            var peakMemory = GC.GetTotalMemory(false);
            var relationshipCount = characterCount * (characterCount - 1);
            
            return new MemoryProfileResult
            {
                CharacterCount = characterCount,
                RelationshipCount = relationshipCount,
                MemoryUsedBytes = peakMemory - initialMemory,
                MemoryPerRelationship = (double)(peakMemory - initialMemory) / relationshipCount
            };
        }
        
        /// <summary>
        /// メモリプロファイル結果
        /// </summary>
        public struct MemoryProfileResult
        {
            public int CharacterCount;
            public int RelationshipCount;
            public long MemoryUsedBytes;
            public double MemoryPerRelationship;
            
            public override string ToString()
            {
                return $"キャラクター{CharacterCount}人, 関係値{RelationshipCount}個, " +
                       $"使用メモリ{MemoryUsedBytes}bytes, 関係値あたり{MemoryPerRelationship:F2}bytes";
            }
        }
    }
}