using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.SceneManagement;
using NegabokuRPG.Data;
using NegabokuRPG.Characters;
using NegabokuRPG.Systems;
using NegabokuRPG.Utilities;
using NegabokuRPG.Infrastructure.Unity;
using NegabokuRPG.Infrastructure.DependencyInjection;
using NegabokuRPG.Application.Interfaces;
using NegabokuRPG.Domain.Services;

namespace NegabokuRPG.Core
{
    /// <summary>
    /// DI対応のゲーム全体管理クラス
    /// テスタビリティと保守性を向上
    /// </summary>
    public class DIGameManager : MonoBehaviour
    {
        private static DIGameManager instance;
        public static DIGameManager Instance
        {
            get
            {
                if (instance == null)
                {
                    instance = FindObjectOfType<DIGameManager>();
                    if (instance == null)
                    {
                        var go = new GameObject("DIGameManager");
                        instance = go.AddComponent<DIGameManager>();
                        DontDestroyOnLoad(go);
                    }
                }
                return instance;
            }
        }

        [Header("ゲーム設定")]
        [SerializeField] private GameConfiguration gameConfig;
        [SerializeField] private List<CharacterData> allCharacterData = new List<CharacterData>();
        [SerializeField] private List<CharacterData> dlcCharacterData = new List<CharacterData>();

        [Header("初期設定")]
        [SerializeField] private string mainMenuScene = "MainMenu";
        [SerializeField] private string gameplayScene = "Gameplay";
        [SerializeField] private string battleScene = "Battle";

        // 依存関係（DI対応）
        private IRelationshipRepository relationshipRepository;
        private RelationshipDomainService relationshipDomainService;
        private BattleSystem battleSystem;
        private DungeonSystem dungeonSystem;
        private SkillSystem skillSystem;
        private SaveSystem saveSystem;
        private SceneController sceneController;

        // ゲーム状態
        private GameState currentGameState = GameState.MainMenu;
        private GameData currentGameData;
        private List<PlayerCharacter> currentParty = new List<PlayerCharacter>();
        
        // 設定
        private bool isDLCUnlocked = false;
        private Dictionary<string, bool> gameFlags = new Dictionary<string, bool>();

        // イベント
        public event Action<GameState, GameState> OnGameStateChanged;
        public event Action<GameData> OnGameDataChanged;
        public event Action<List<PlayerCharacter>> OnPartyChanged;
        public event Action OnDLCUnlocked;

        // プロパティ
        public GameState CurrentGameState => currentGameState;
        public GameData CurrentGameData => currentGameData;
        public List<PlayerCharacter> CurrentParty => new List<PlayerCharacter>(currentParty);
        public bool IsDLCUnlocked => isDLCUnlocked;

        private void Awake()
        {
            if (instance == null)
            {
                instance = this;
                DontDestroyOnLoad(gameObject);
                InitializeServices();
                InitializeGame();
            }
            else if (instance != this)
            {
                Destroy(gameObject);
            }
        }

        /// <summary>
        /// DIサービスの初期化
        /// </summary>
        private void InitializeServices()
        {
            // ServiceLocatorが初期化されていない場合は初期化
            if (!ServiceLocator.IsRegistered<IRelationshipRepository>())
            {
                ServiceLocator.Initialize();
                RegisterServices();
            }

            // 依存関係を解決
            ResolveDependencies();
        }

        /// <summary>
        /// サービスの登録
        /// </summary>
        private void RegisterServices()
        {
            // Infrastructure層のサービス
            ServiceLocator.RegisterSingleton<IRelationshipRepository, TestRelationshipRepository>();
            
            // Domain層のサービス
            ServiceLocator.RegisterSingleton<RelationshipDomainService>();

            // 他のUnityシステムも必要に応じて登録
            // ServiceLocator.RegisterSingleton<BattleSystem>();
            // ServiceLocator.RegisterSingleton<DungeonSystem>();
        }

        /// <summary>
        /// 依存関係の解決
        /// </summary>
        private void ResolveDependencies()
        {
            try
            {
                relationshipRepository = ServiceLocator.Resolve<IRelationshipRepository>();
                relationshipDomainService = ServiceLocator.Resolve<RelationshipDomainService>();
            }
            catch (InvalidOperationException ex)
            {
                Debug.LogError($"Failed to resolve dependencies: {ex.Message}");
                // フォールバック処理
                CreateFallbackServices();
            }
        }

        /// <summary>
        /// フォールバック用のサービス生成
        /// </summary>
        private void CreateFallbackServices()
        {
            relationshipRepository = new TestRelationshipRepository();
            relationshipDomainService = new RelationshipDomainService();
            
            Debug.LogWarning("Using fallback services. DI container may not be properly configured.");
        }

        /// <summary>
        /// テスト用のサービス差し替え
        /// </summary>
        public void InjectDependencies(
            IRelationshipRepository repository = null,
            RelationshipDomainService domainService = null)
        {
            if (repository != null) relationshipRepository = repository;
            if (domainService != null) relationshipDomainService = domainService;
        }

        private void Start()
        {
            StartCoroutine(InitializeSystemsAfterFrame());
        }

        /// <summary>
        /// ゲーム初期化
        /// </summary>
        private void InitializeGame()
        {
            // プラットフォーム固有の初期化
            InitializePlatformSpecific();
            
            // ゲームデータ初期化
            currentGameData = new GameData();
            
            // 設定ロード
            LoadGameSettings();
        }

        /// <summary>
        /// プラットフォーム固有の初期化
        /// </summary>
        private void InitializePlatformSpecific()
        {
#if UNITY_STANDALONE_WIN
            // Windows固有の設定
            Application.targetFrameRate = 60;
            QualitySettings.vSyncCount = 1;
#elif UNITY_STANDALONE_OSX
            // Mac固有の設定
            Application.targetFrameRate = 60;
            QualitySettings.vSyncCount = 1;
#endif
        }

        /// <summary>
        /// システム初期化（フレーム後）
        /// </summary>
        private IEnumerator InitializeSystemsAfterFrame()
        {
            yield return null; // 1フレーム待機

            // 既存のUnityシステム参照を取得
            skillSystem = SkillSystem.Instance;
            dungeonSystem = DungeonSystem.Instance;
            saveSystem = SaveSystem.Instance;
            
            sceneController = SceneController.Instance;
            if (sceneController != null)
            {
                sceneController.OnSceneLoadCompleted += OnSceneLoadCompleted;
            }

            // システム間の連携設定
            SetupSystemConnections();

            // 初期キャラクター関係値設定（DI対応）
            if (relationshipRepository != null)
            {
                InitializeRelationshipsWithDI();
            }

            Debug.Log("DIGameManager initialized successfully");
        }

        /// <summary>
        /// DIを使用した関係値初期化
        /// </summary>
        private void InitializeRelationshipsWithDI()
        {
            var characterIds = allCharacterData.Select(c => 
                new NegabokuRPG.Domain.ValueObjects.CharacterId(c.characterId)).ToList();
            
            try
            {
                var aggregate = relationshipRepository.Load(characterIds);
                Debug.Log($"Relationship system initialized with {characterIds.Count} characters");
            }
            catch (System.Exception ex)
            {
                Debug.LogError($"Failed to initialize relationships: {ex.Message}");
            }
        }

        /// <summary>
        /// システム間の連携設定
        /// </summary>
        private void SetupSystemConnections()
        {
            // バトルシステムとの連携
            if (battleSystem != null)
            {
                battleSystem.OnBattleEnd += OnBattleEnded;
            }

            // セーブシステムとの連携
            if (saveSystem != null)
            {
                saveSystem.OnSaveCompleted += OnSaveCompleted;
                saveSystem.OnLoadCompleted += OnLoadCompleted;
            }
        }

        /// <summary>
        /// 新しいゲームを開始
        /// </summary>
        public void StartNewGame(string playerName = "勇者")
        {
            currentGameData = CreateNewGameData(playerName);
            
            // 初期パーティ設定（最初の2キャラクター）
            SetupInitialParty();
            
            // ゲーム状態変更
            ChangeGameState(GameState.Playing);
            
            // ゲームプレイシーンへ
            if (sceneController != null)
            {
                sceneController.LoadScene(gameplayScene);
            }
        }

        /// <summary>
        /// パーティを設定（2人固定システム）
        /// </summary>
        public bool SetParty(List<string> characterIds)
        {
            // 2人固定システムの検証
            if (!ValidationHelper.ValidatePartySize(characterIds, nameof(SetParty)))
            {
                return false;
            }

            var newParty = new List<PlayerCharacter>();
            var availableCharacters = GetAvailableCharacters();

            foreach (var charId in characterIds)
            {
                var characterData = availableCharacters.Find(c => c.characterId == charId);
                if (characterData != null)
                {
                    var playerChar = CreatePlayerCharacter(characterData);
                    newParty.Add(playerChar);
                }
                else
                {
                    Debug.LogWarning($"Character not found or not available: {charId}");
                    return false;
                }
            }

            currentParty = newParty;
            
            // スキルシステムに通知
            if (skillSystem != null)
            {
                skillSystem.UpdatePartySkills(currentParty);
            }

            OnPartyChanged?.Invoke(currentParty);
            return true;
        }

        /// <summary>
        /// 利用可能なキャラクターを取得
        /// </summary>
        public List<CharacterData> GetAvailableCharacters()
        {
            var available = new List<CharacterData>(allCharacterData);
            
            if (isDLCUnlocked)
            {
                available.AddRange(dlcCharacterData);
            }
            
            return available;
        }

        // 他のメソッドは元のGameManagerと同様...
        
        /// <summary>
        /// ゲーム状態変更
        /// </summary>
        private void ChangeGameState(GameState newState)
        {
            var oldState = currentGameState;
            currentGameState = newState;
            
            OnGameStateChanged?.Invoke(oldState, newState);
            
            // 状態変更に応じた処理
            switch (newState)
            {
                case GameState.MainMenu:
                    Time.timeScale = 1f;
                    break;
                case GameState.Playing:
                    Time.timeScale = 1f;
                    break;
                case GameState.Battle:
                    // バトル固有の設定
                    break;
                case GameState.Paused:
                    Time.timeScale = 0f;
                    break;
            }
        }

        /// <summary>
        /// 新しいゲームデータを作成
        /// </summary>
        private GameData CreateNewGameData(string playerName)
        {
            return new GameData
            {
                playerName = playerName,
                playTime = 0f,
                level = 1,
                gold = gameConfig != null ? gameConfig.initialGold : GameConstants.INITIAL_GOLD,
                orbs = 0,
                isDLCUnlocked = false,
                gameFlags = new Dictionary<string, bool>()
            };
        }

        /// <summary>
        /// 初期パーティ設定（2人固定）
        /// </summary>
        private void SetupInitialParty()
        {
            // 最初の2キャラクターで自動編成
            var initialCharacterIds = allCharacterData
                .Take(GameConstants.INITIAL_PARTY_SIZE)
                .Select(c => c.characterId)
                .ToList();
                
            SetParty(initialCharacterIds);
        }

        /// <summary>
        /// プレイヤーキャラクター作成
        /// </summary>
        private PlayerCharacter CreatePlayerCharacter(CharacterData characterData)
        {
            var go = new GameObject($"PlayerCharacter_{characterData.characterId}");
            var playerChar = go.AddComponent<PlayerCharacter>();
            playerChar.InitializeCharacter(characterData);
            
            // スキル初期化
            if (skillSystem != null)
            {
                skillSystem.InitializeCharacterSkills(playerChar);
            }
            
            return playerChar;
        }

        /// <summary>
        /// ゲーム設定をロード
        /// </summary>
        private void LoadGameSettings()
        {
            // PlayerPrefsやファイルから設定を読み込み
            // 将来的にはクラウド設定にも対応
        }

        /// <summary>
        /// イベントハンドラー群
        /// </summary>
        private void OnBattleEnded(BattleResult result)
        {
            // バトル結果処理
            if (result.victory)
            {
                foreach (var character in currentParty)
                {
                    character.AddExperience(result.experience / currentParty.Count);
                }
                if (currentGameData != null)
                {
                    currentGameData.gold += result.gold;
                }
            }

            ChangeGameState(GameState.Playing);
        }

        private void OnSaveCompleted(int slotNumber)
        {
            Debug.Log($"Game saved to slot {slotNumber}");
        }

        private void OnLoadCompleted(int slotNumber)
        {
            Debug.Log($"Game loaded from slot {slotNumber}");
        }

        private void OnSceneLoadCompleted(string sceneName)
        {
            Debug.Log($"Scene loaded: {sceneName}");
        }

        private void OnDestroy()
        {
            if (sceneController != null)
            {
                sceneController.OnSceneLoadCompleted -= OnSceneLoadCompleted;
            }
        }

        /// <summary>
        /// テスト用のクリーンアップ
        /// </summary>
        public void CleanupForTesting()
        {
            ServiceLocator.Clear();
            currentParty.Clear();
            currentGameState = GameState.MainMenu;
            currentGameData = null;
        }
    }

    /// <summary>
    /// テスト用のリポジトリ実装（本実装に差し替え予定）
    /// </summary>
    public class TestRelationshipRepository : IRelationshipRepository
    {
        private NegabokuRPG.Domain.Entities.RelationshipAggregate _aggregate = 
            new NegabokuRPG.Domain.Entities.RelationshipAggregate();

        public void Save(NegabokuRPG.Domain.Entities.RelationshipAggregate aggregate)
        {
            _aggregate = aggregate;
        }

        public NegabokuRPG.Domain.Entities.RelationshipAggregate Load(List<NegabokuRPG.Domain.ValueObjects.CharacterId> characterIds)
        {
            // 初期値で関係値を設定
            foreach (var char1 in characterIds)
            {
                foreach (var char2 in characterIds)
                {
                    if (char1 != char2)
                    {
                        var existing = _aggregate.GetRelationship(char1, char2);
                        if (existing.Value == NegabokuRPG.Domain.ValueObjects.RelationshipValue.DEFAULT_VALUE)
                        {
                            _aggregate.InitializeRelationship(char1, char2, new NegabokuRPG.Domain.ValueObjects.RelationshipValue());
                        }
                    }
                }
            }
            return _aggregate;
        }

        public bool Exists(NegabokuRPG.Domain.ValueObjects.CharacterId character1, NegabokuRPG.Domain.ValueObjects.CharacterId character2)
        {
            return true;
        }

        public void Clear()
        {
            _aggregate = new NegabokuRPG.Domain.Entities.RelationshipAggregate();
        }
    }
}