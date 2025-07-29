using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace NegabokuRPG.Core
{
    /// <summary>
    /// シーン管理システム - 非同期ロード、遷移効果対応
    /// </summary>
    public class SceneController : MonoBehaviour
    {
        private static SceneController instance;
        public static SceneController Instance
        {
            get
            {
                if (instance == null)
                {
                    instance = FindObjectOfType<SceneController>();
                    if (instance == null)
                    {
                        var go = new GameObject("SceneController");
                        instance = go.AddComponent<SceneController>();
                        DontDestroyOnLoad(go);
                    }
                }
                return instance;
            }
        }

        [Header("ローディング設定")]
        [SerializeField] private GameObject loadingScreenPrefab;
        [SerializeField] private float minimumLoadingTime = 1f;
        [SerializeField] private bool useTransitionEffects = true;

        [Header("シーン設定")]
        [SerializeField] private List<SceneInfo> registeredScenes = new List<SceneInfo>();

        // 現在のシーン状態
        private string currentSceneName;
        private string previousSceneName;
        private bool isLoading = false;
        private Canvas loadingCanvas;

        // ロード進捗
        private float currentLoadProgress = 0f;

        // イベント
        public event Action<string> OnSceneLoadStarted;
        public event Action<string> OnSceneLoadCompleted;
        public event Action<float> OnLoadProgressChanged;
        public event Action<string, string> OnSceneChanged; // previous, current

        private void Awake()
        {
            if (instance == null)
            {
                instance = this;
                DontDestroyOnLoad(gameObject);
                InitializeSceneController();
            }
            else if (instance != this)
            {
                Destroy(gameObject);
            }
        }

        private void Start()
        {
            // 現在のシーン名を取得
            currentSceneName = SceneManager.GetActiveScene().name;
        }

        /// <summary>
        /// シーンコントローラー初期化
        /// </summary>
        private void InitializeSceneController()
        {
            // シーンロードイベントに登録
            SceneManager.sceneLoaded += OnSceneLoaded;
            SceneManager.sceneUnloaded += OnSceneUnloaded;

            // ローディング画面準備
            if (loadingScreenPrefab != null)
            {
                SetupLoadingScreen();
            }
        }

        /// <summary>
        /// ローディング画面セットアップ
        /// </summary>
        private void SetupLoadingScreen()
        {
            var loadingGO = Instantiate(loadingScreenPrefab);
            loadingCanvas = loadingGO.GetComponent<Canvas>();
            
            if (loadingCanvas != null)
            {
                loadingCanvas.sortingOrder = 1000; // 最前面に表示
                DontDestroyOnLoad(loadingGO);
                loadingGO.SetActive(false);
            }
        }

        /// <summary>
        /// シーンを非同期でロード
        /// </summary>
        public void LoadScene(string sceneName, Action onCompleted = null)
        {
            if (isLoading)
            {
                Debug.LogWarning("Scene is already loading, ignoring request");
                return;
            }

            var sceneInfo = GetSceneInfo(sceneName);
            if (sceneInfo == null)
            {
                Debug.LogError($"Scene not registered: {sceneName}");
                return;
            }

            StartCoroutine(LoadSceneAsync(sceneName, onCompleted));
        }

        /// <summary>
        /// 前のシーンに戻る
        /// </summary>
        public void LoadPreviousScene(Action onCompleted = null)
        {
            if (!string.IsNullOrEmpty(previousSceneName))
            {
                LoadScene(previousSceneName, onCompleted);
            }
            else
            {
                Debug.LogWarning("No previous scene to load");
            }
        }

        /// <summary>
        /// シーンの非同期ロード処理
        /// </summary>
        private IEnumerator LoadSceneAsync(string sceneName, Action onCompleted = null)
        {
            isLoading = true;
            currentLoadProgress = 0f;

            OnSceneLoadStarted?.Invoke(sceneName);

            // ローディング画面表示
            if (loadingCanvas != null)
            {
                loadingCanvas.gameObject.SetActive(true);
                yield return StartCoroutine(FadeIn());
            }

            // 最小ローディング時間の計測開始
            float startTime = Time.realtimeSinceStartup;

            // シーンの非同期ロード開始
            AsyncOperation asyncLoad = SceneManager.LoadSceneAsync(sceneName);
            asyncLoad.allowSceneActivation = false;

            // ロード進捗更新
            while (!asyncLoad.isDone)
            {
                // Unity's progress goes from 0 to 0.9, then jumps to 1
                float progress = Mathf.Clamp01(asyncLoad.progress / 0.9f);
                currentLoadProgress = progress;
                OnLoadProgressChanged?.Invoke(progress);

                // 90%まで進んだら、最小時間チェック
                if (asyncLoad.progress >= 0.9f)
                {
                    float elapsedTime = Time.realtimeSinceStartup - startTime;
                    if (elapsedTime >= minimumLoadingTime)
                    {
                        currentLoadProgress = 1f;
                        OnLoadProgressChanged?.Invoke(1f);
                        asyncLoad.allowSceneActivation = true;
                    }
                }

                yield return null;
            }

            // シーンアクティベーション完了まで待機
            yield return new WaitUntil(() => asyncLoad.isDone);

            // ローディング画面非表示
            if (loadingCanvas != null)
            {
                yield return StartCoroutine(FadeOut());
                loadingCanvas.gameObject.SetActive(false);
            }

            // 完了処理
            isLoading = false;
            onCompleted?.Invoke();
            OnSceneLoadCompleted?.Invoke(sceneName);
        }

        /// <summary>
        /// 追加シーンをロード（アディティブ）
        /// </summary>
        public void LoadAdditiveScene(string sceneName, Action onCompleted = null)
        {
            StartCoroutine(LoadAdditiveSceneAsync(sceneName, onCompleted));
        }

        /// <summary>
        /// 追加シーンの非同期ロード
        /// </summary>
        private IEnumerator LoadAdditiveSceneAsync(string sceneName, Action onCompleted = null)
        {
            if (SceneManager.GetSceneByName(sceneName).isLoaded)
            {
                Debug.LogWarning($"Scene {sceneName} is already loaded");
                onCompleted?.Invoke();
                yield break;
            }

            AsyncOperation asyncLoad = SceneManager.LoadSceneAsync(sceneName, LoadSceneMode.Additive);
            yield return asyncLoad;

            onCompleted?.Invoke();
        }

        /// <summary>
        /// シーンをアンロード
        /// </summary>
        public void UnloadScene(string sceneName, Action onCompleted = null)
        {
            StartCoroutine(UnloadSceneAsync(sceneName, onCompleted));
        }

        /// <summary>
        /// シーンの非同期アンロード
        /// </summary>
        private IEnumerator UnloadSceneAsync(string sceneName, Action onCompleted = null)
        {
            if (!SceneManager.GetSceneByName(sceneName).isLoaded)
            {
                Debug.LogWarning($"Scene {sceneName} is not loaded");
                onCompleted?.Invoke();
                yield break;
            }

            AsyncOperation asyncUnload = SceneManager.UnloadSceneAsync(sceneName);
            yield return asyncUnload;

            // メモリクリーンアップ
            Resources.UnloadUnusedAssets();
            System.GC.Collect();

            onCompleted?.Invoke();
        }

        /// <summary>
        /// シーンの事前ロード（非アクティブ状態で）
        /// </summary>
        public void PreloadScene(string sceneName, Action onCompleted = null)
        {
            StartCoroutine(PreloadSceneAsync(sceneName, onCompleted));
        }

        /// <summary>
        /// シーンの事前ロード処理
        /// </summary>
        private IEnumerator PreloadSceneAsync(string sceneName, Action onCompleted = null)
        {
            AsyncOperation asyncLoad = SceneManager.LoadSceneAsync(sceneName);
            asyncLoad.allowSceneActivation = false;

            while (asyncLoad.progress < 0.9f)
            {
                yield return null;
            }

            // アクティベートはせずに完了
            onCompleted?.Invoke();
        }

        /// <summary>
        /// フェードイン効果
        /// </summary>
        private IEnumerator FadeIn()
        {
            if (!useTransitionEffects) yield break;

            var canvasGroup = loadingCanvas.GetComponent<CanvasGroup>();
            if (canvasGroup == null)
            {
                canvasGroup = loadingCanvas.gameObject.AddComponent<CanvasGroup>();
            }

            float fadeTime = 0.5f;
            float elapsedTime = 0f;

            while (elapsedTime < fadeTime)
            {
                elapsedTime += Time.unscaledDeltaTime;
                canvasGroup.alpha = Mathf.Lerp(0f, 1f, elapsedTime / fadeTime);
                yield return null;
            }

            canvasGroup.alpha = 1f;
        }

        /// <summary>
        /// フェードアウト効果
        /// </summary>
        private IEnumerator FadeOut()
        {
            if (!useTransitionEffects) yield break;

            var canvasGroup = loadingCanvas.GetComponent<CanvasGroup>();
            if (canvasGroup == null) yield break;

            float fadeTime = 0.5f;
            float elapsedTime = 0f;

            while (elapsedTime < fadeTime)
            {
                elapsedTime += Time.unscaledDeltaTime;
                canvasGroup.alpha = Mathf.Lerp(1f, 0f, elapsedTime / fadeTime);
                yield return null;
            }

            canvasGroup.alpha = 0f;
        }

        /// <summary>
        /// シーン情報を取得
        /// </summary>
        private SceneInfo GetSceneInfo(string sceneName)
        {
            return registeredScenes.Find(s => s.sceneName == sceneName);
        }

        /// <summary>
        /// シーンが登録されているかチェック
        /// </summary>
        public bool IsSceneRegistered(string sceneName)
        {
            return GetSceneInfo(sceneName) != null;
        }

        /// <summary>
        /// 現在のシーン名を取得
        /// </summary>
        public string GetCurrentSceneName()
        {
            return currentSceneName;
        }

        /// <summary>
        /// 前のシーン名を取得
        /// </summary>
        public string GetPreviousSceneName()
        {
            return previousSceneName;
        }

        /// <summary>
        /// ロード中かどうか
        /// </summary>
        public bool IsLoading()
        {
            return isLoading;
        }

        /// <summary>
        /// 現在のロード進捗を取得
        /// </summary>
        public float GetLoadProgress()
        {
            return currentLoadProgress;
        }

        /// <summary>
        /// メモリ使用量を最適化
        /// </summary>
        public void OptimizeMemory()
        {
            StartCoroutine(OptimizeMemoryAsync());
        }

        /// <summary>
        /// メモリ最適化の非同期処理
        /// </summary>
        private IEnumerator OptimizeMemoryAsync()
        {
            // 未使用アセットをアンロード
            yield return Resources.UnloadUnusedAssets();
            
            // ガベージコレクション実行
            System.GC.Collect();
            
            yield return null;
        }

        // イベントハンドラー
        private void OnSceneLoaded(Scene scene, LoadSceneMode mode)
        {
            if (mode == LoadSceneMode.Single)
            {
                previousSceneName = currentSceneName;
                currentSceneName = scene.name;
                OnSceneChanged?.Invoke(previousSceneName, currentSceneName);
            }

            Debug.Log($"Scene loaded: {scene.name} (Mode: {mode})");
        }

        private void OnSceneUnloaded(Scene scene)
        {
            Debug.Log($"Scene unloaded: {scene.name}");
        }

        private void OnDestroy()
        {
            SceneManager.sceneLoaded -= OnSceneLoaded;
            SceneManager.sceneUnloaded -= OnSceneUnloaded;
        }

        /// <summary>
        /// エディタ専用デバッグ機能
        /// </summary>
        [ContextMenu("Load Main Menu")]
        private void DebugLoadMainMenu()
        {
            LoadScene("MainMenu");
        }

        [ContextMenu("Optimize Memory")]
        private void DebugOptimizeMemory()
        {
            OptimizeMemory();
        }
    }

    /// <summary>
    /// シーン情報
    /// </summary>
    [Serializable]
    public class SceneInfo
    {
        [Header("シーン情報")]
        public string sceneName;
        public string displayName;
        [TextArea(2, 4)]
        public string description;
        
        [Header("設定")]
        public bool isMainScene = true;
        public bool preloadOnStart = false;
        public SceneCategory category = SceneCategory.Gameplay;
        
        [Header("必要条件")]
        public List<string> requiredScenes = new List<string>();
        public bool requiresInternet = false;
    }

    /// <summary>
    /// シーンカテゴリ
    /// </summary>
    public enum SceneCategory
    {
        Menu,
        Gameplay,
        Battle,
        Cutscene,
        Loading,
        Debug
    }
}