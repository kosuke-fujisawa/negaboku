using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using NegabokuRPG.Utilities.Performance;

namespace NegabokuRPG.Editor
{
    /// <summary>
    /// パフォーマンステスト用のEditorWindow
    /// Unity Editor上でのパフォーマンス測定UI
    /// </summary>
    public class PerformanceTestWindow : EditorWindow
    {
        private int characterCount = 10;
        private int iterations = 1000;
        private Vector2 scrollPosition;
        private List<PerformanceProfiler.ProfileResult> latestResults;
        private PerformanceProfiler.MemoryProfileResult latestMemoryResult;
        private bool isRunning = false;
        
        [MenuItem("NegabokuRPG/Performance Test Window")]
        public static void ShowWindow()
        {
            GetWindow<PerformanceTestWindow>("パフォーマンステスト");
        }
        
        private void OnGUI()
        {
            GUILayout.Label("関係値システム パフォーマンステスト", EditorStyles.boldLabel);
            
            EditorGUILayout.Space();
            
            // テスト設定
            GUILayout.Label("テスト設定", EditorStyles.boldLabel);
            characterCount = EditorGUILayout.IntSlider("キャラクター数", characterCount, 2, 100);
            iterations = EditorGUILayout.IntSlider("反復回数", iterations, 100, 10000);
            
            EditorGUILayout.Space();
            
            // テスト実行ボタン
            GUI.enabled = !isRunning;
            
            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button("パフォーマンステスト実行", GUILayout.Height(30)))
            {
                RunPerformanceTest();
            }
            
            if (GUILayout.Button("メモリテスト実行", GUILayout.Height(30)))
            {
                RunMemoryTest();
            }
            EditorGUILayout.EndHorizontal();
            
            if (GUILayout.Button("全テスト実行", GUILayout.Height(40)))
            {
                RunAllTests();
            }
            
            GUI.enabled = true;
            
            EditorGUILayout.Space();
            
            // 実行状態表示
            if (isRunning)
            {
                EditorGUILayout.HelpBox("テスト実行中...", MessageType.Info);
            }
            
            // 結果表示
            DisplayResults();
        }
        
        private void RunPerformanceTest()
        {
            isRunning = true;
            EditorApplication.delayCall += () =>
            {
                try
                {
                    Debug.Log($"パフォーマンステスト開始: キャラクター{characterCount}人, 反復{iterations}回");
                    latestResults = PerformanceProfiler.ProfileRelationshipSystem(characterCount, iterations);
                    PerformanceProfiler.LogResults(latestResults);
                    Debug.Log("パフォーマンステスト完了");
                }
                catch (System.Exception ex)
                {
                    Debug.LogError($"パフォーマンステストエラー: {ex.Message}");
                }
                finally
                {
                    isRunning = false;
                    Repaint();
                }
            };
        }
        
        private void RunMemoryTest()
        {
            isRunning = true;
            EditorApplication.delayCall += () =>
            {
                try
                {
                    Debug.Log($"メモリテスト開始: キャラクター{characterCount}人");
                    latestMemoryResult = PerformanceProfiler.ProfileMemoryUsage(characterCount);
                    Debug.Log($"メモリテスト結果: {latestMemoryResult}");
                }
                catch (System.Exception ex)
                {
                    Debug.LogError($"メモリテストエラー: {ex.Message}");
                }
                finally
                {
                    isRunning = false;
                    Repaint();
                }
            };
        }
        
        private void RunAllTests()
        {
            isRunning = true;
            EditorApplication.delayCall += () =>
            {
                try
                {
                    Debug.Log("全テスト開始");
                    
                    // パフォーマンステスト
                    latestResults = PerformanceProfiler.ProfileRelationshipSystem(characterCount, iterations);
                    PerformanceProfiler.LogResults(latestResults);
                    
                    // メモリテスト
                    latestMemoryResult = PerformanceProfiler.ProfileMemoryUsage(characterCount);
                    Debug.Log($"メモリテスト結果: {latestMemoryResult}");
                    
                    Debug.Log("全テスト完了");
                }
                catch (System.Exception ex)
                {
                    Debug.LogError($"テストエラー: {ex.Message}");
                }
                finally
                {
                    isRunning = false;
                    Repaint();
                }
            };
        }
        
        private void DisplayResults()
        {
            if (latestResults == null && latestMemoryResult.CharacterCount == 0)
                return;
            
            EditorGUILayout.Space();
            GUILayout.Label("テスト結果", EditorStyles.boldLabel);
            
            scrollPosition = EditorGUILayout.BeginScrollView(scrollPosition, GUILayout.Height(300));
            
            // パフォーマンステスト結果
            if (latestResults != null)
            {
                GUILayout.Label("パフォーマンス結果", EditorStyles.miniBoldLabel);
                
                foreach (var result in latestResults)
                {
                    EditorGUILayout.BeginVertical("box");
                    
                    GUILayout.Label(result.TestName, EditorStyles.boldLabel);
                    
                    var color = GetPerformanceColor(result.AverageMilliseconds);
                    var previousColor = GUI.color;
                    GUI.color = color;
                    
                    EditorGUILayout.LabelField("平均時間", $"{result.AverageMilliseconds:F4}ms");
                    GUI.color = previousColor;
                    
                    EditorGUILayout.LabelField("総時間", $"{result.ElapsedMilliseconds:F2}ms");
                    EditorGUILayout.LabelField("反復回数", result.IterationCount.ToString());
                    EditorGUILayout.LabelField("メモリ使用量", $"{result.MemoryUsedBytes} bytes");
                    
                    EditorGUILayout.EndVertical();
                    EditorGUILayout.Space();
                }
            }
            
            // メモリテスト結果
            if (latestMemoryResult.CharacterCount > 0)
            {
                GUILayout.Label("メモリ結果", EditorStyles.miniBoldLabel);
                
                EditorGUILayout.BeginVertical("box");
                EditorGUILayout.LabelField("キャラクター数", latestMemoryResult.CharacterCount.ToString());
                EditorGUILayout.LabelField("関係値数", latestMemoryResult.RelationshipCount.ToString());
                EditorGUILayout.LabelField("総メモリ使用量", $"{latestMemoryResult.MemoryUsedBytes} bytes");
                EditorGUILayout.LabelField("関係値あたりメモリ", $"{latestMemoryResult.MemoryPerRelationship:F2} bytes");
                
                // メモリ効率評価
                var memoryEfficiency = GetMemoryEfficiencyLevel(latestMemoryResult.MemoryPerRelationship);
                var efficiencyColor = GetEfficiencyColor(memoryEfficiency);
                var previousColor = GUI.color;
                GUI.color = efficiencyColor;
                EditorGUILayout.LabelField("メモリ効率", memoryEfficiency);
                GUI.color = previousColor;
                
                EditorGUILayout.EndVertical();
            }
            
            EditorGUILayout.EndScrollView();
            
            // パフォーマンス目標の表示
            EditorGUILayout.Space();
            GUILayout.Label("パフォーマンス目標", EditorStyles.boldLabel);
            EditorGUILayout.HelpBox(
                "目標:\n" +
                "• 関係値変更: < 0.1ms/回\n" +
                "• バトルイベント: < 0.5ms/回\n" +
                "• 平均計算: < 1.0ms/回\n" +
                "• メモリ効率: < 100bytes/関係値",
                MessageType.Info
            );
        }
        
        private Color GetPerformanceColor(double averageMs)
        {
            if (averageMs > 1.0) return Color.red;     // 1ms超過は赤
            if (averageMs > 0.1) return Color.yellow;  // 0.1ms超過は黄
            return Color.green;                        // 0.1ms以下は緑
        }
        
        private string GetMemoryEfficiencyLevel(double memoryPerRelationship)
        {
            if (memoryPerRelationship > 200) return "要改善";
            if (memoryPerRelationship > 100) return "普通";
            if (memoryPerRelationship > 50) return "良好";
            return "優秀";
        }
        
        private Color GetEfficiencyColor(string efficiency)
        {
            return efficiency switch
            {
                "要改善" => Color.red,
                "普通" => Color.yellow,
                "良好" => Color.cyan,
                "優秀" => Color.green,
                _ => Color.white
            };
        }
        
        private void Update()
        {
            // 実行中は定期的に再描画
            if (isRunning)
            {
                Repaint();
            }
        }
    }
}