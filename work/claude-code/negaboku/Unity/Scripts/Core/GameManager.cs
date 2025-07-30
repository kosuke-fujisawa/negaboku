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

namespace NegabokuRPG.Core
{
    /// <summary>
    /// ゲーム全体の管理を行うメインマネージャー
    /// Windows/Mac対応、拡張性を考慮した設計
    /// </summary>
    public class GameManager : MonoBehaviour
    {
        private static GameManager instance;
        public static GameManager Instance
        {
            get
            {
                if (instance == null)
                {
                    instance = FindObjectOfType<GameManager>();
                    if (instance == null)
                    {
                        var go = new GameObject("GameManager");
                        instance = go.AddComponent<GameManager>();
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

        // ゲーム状態
        private GameState currentGameState = GameState.MainMenu;
        private GameData currentGameData;
        private List<PlayerCharacter> currentParty = new List<PlayerCharacter>();
        
        // システム参照
        private RelationshipSystem relationshipSystem;
        private BattleSystem battleSystem;
        private DungeonSystem dungeonSystem;
        private SkillSystem skillSystem;
        private SaveSystem saveSystem;
        private SceneController sceneController;

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
                InitializeGame();
            }
            else if (instance != this)
            {
                Destroy(gameObject);
            }
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

            // システム参照を取得
            relationshipSystem = RelationshipSystem.Instance;
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

            // 初期キャラクター関係値設定
            if (relationshipSystem != null)
            {
                relationshipSystem.InitializeRelationships(allCharacterData);
            }

            Debug.Log("GameManager initialized successfully");
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
            
            // 初期パーティ設定（最初の4キャラクター）
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
        /// ゲームをロード
        /// </summary>
        public bool LoadGame(int slotNumber)
        {
            if (saveSystem == null) return false;

            var saveData = saveSystem.LoadGame(slotNumber);
            if (saveData == null) return false;

            // セーブデータからゲームデータを復元
            RestoreGameFromSaveData(saveData);
            
            ChangeGameState(GameState.Playing);
            return true;
        }

        /// <summary>
        /// ゲームをセーブ
        /// </summary>
        public bool SaveGame(int slotNumber)
        {
            if (saveSystem == null || currentGameData == null) return false;

            var saveData = CreateSaveDataFromCurrentGame();
            return saveSystem.SaveGame(slotNumber, saveData);
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
        /// DLCを解放
        /// </summary>
        public void UnlockDLC()
        {
            if (isDLCUnlocked) return;

            isDLCUnlocked = true;
            currentGameData.isDLCUnlocked = true;
            
            OnDLCUnlocked?.Invoke();
            Debug.Log("DLC content unlocked!");
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

        /// <summary>
        /// バトル開始（2人パーティ）
        /// </summary>
        public void StartBattle(List<BattleEnemyData> enemies)
        {
            if (!ValidationHelper.ValidatePartySize(currentParty, nameof(StartBattle)))
            {
                return;
            }

            ChangeGameState(GameState.Battle);
            
            if (sceneController != null)
            {
                sceneController.LoadScene(battleScene, () => {
                    battleSystem = FindObjectOfType<BattleSystem>();
                    if (battleSystem != null)
                    {
                        battleSystem.StartBattle(currentParty, enemies);
                    }
                });
            }
        }

        /// <summary>
        /// ダンジョン探索開始（2人パーティ）
        /// </summary>
        public bool StartDungeonExploration(string dungeonId)
        {
            if (dungeonSystem == null || !ValidationHelper.ValidatePartySize(currentParty, nameof(StartDungeonExploration))) 
            {
                return false;
            }

            return dungeonSystem.StartDungeonExploration(dungeonId, currentParty);
        }

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
                gold = gameConfig.initialGold,
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
        /// セーブデータから復元
        /// </summary>
        private void RestoreGameFromSaveData(GameSaveData saveData)
        {
            currentGameData = new GameData
            {
                playerName = saveData.playerName,
                playTime = saveData.playTime,
                level = saveData.playerLevel,
                gold = saveData.gold,
                orbs = saveData.orbs,
                isDLCUnlocked = saveData.dlcUnlocked,
                gameFlags = new Dictionary<string, bool>(saveData.gameFlags)
            };

            isDLCUnlocked = saveData.dlcUnlocked;

            // パーティ復元
            RestorePartyFromSaveData(saveData.partyMembers);

            // システム状態復元
            if (relationshipSystem != null)
            {
                relationshipSystem.LoadRelationships(saveData.relationships);
            }

            if (dungeonSystem != null)
            {
                dungeonSystem.LoadFromSaveData(saveData.availableDungeons, saveData.clearedDungeons);
            }

            OnGameDataChanged?.Invoke(currentGameData);
        }

        /// <summary>
        /// パーティをセーブデータから復元
        /// </summary>
        private void RestorePartyFromSaveData(List<CharacterSaveData> partySaveData)
        {
            currentParty.Clear();
            
            foreach (var charSaveData in partySaveData)
            {
                var characterData = GetAvailableCharacters().Find(c => c.characterId == charSaveData.characterId);
                if (characterData != null)
                {
                    var playerChar = CreatePlayerCharacter(characterData);
                    playerChar.LoadFromSaveData(charSaveData);
                    currentParty.Add(playerChar);
                }
            }

            OnPartyChanged?.Invoke(currentParty);
        }

        /// <summary>
        /// 現在のゲームからセーブデータを作成
        /// </summary>
        private GameSaveData CreateSaveDataFromCurrentGame()
        {
            var saveData = new GameSaveData
            {
                playerName = currentGameData.playerName,
                playTime = currentGameData.playTime,
                playerLevel = currentGameData.level,
                gold = currentGameData.gold,
                orbs = currentGameData.orbs,
                dlcUnlocked = currentGameData.isDLCUnlocked,
                gameFlags = new Dictionary<string, bool>(currentGameData.gameFlags)
            };

            // パーティデータ
            saveData.partyMembers = currentParty.Select(c => c.GetSaveData()).ToList();

            // 関係値データ
            if (relationshipSystem != null)
            {
                saveData.relationships = relationshipSystem.GetAllRelationships();
            }

            // ダンジョンデータ
            if (dungeonSystem != null)
            {
                saveData.availableDungeons = dungeonSystem.GetUnlockedDungeons().Select(d => d.dungeonId).ToList();
                saveData.clearedDungeons = dungeonSystem.GetClearedDungeons().Select(d => d.dungeonId).ToList();
            }

            return saveData;
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
                currentGameData.gold += result.gold;
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

        /// <summary>
        /// アプリケーション終了時の処理
        /// </summary>
        private void OnApplicationPause(bool pauseStatus)
        {
            if (pauseStatus && currentGameState == GameState.Playing)
            {
                // 自動セーブ
                if (saveSystem != null && currentGameData != null)
                {
                    var autoSaveData = CreateSaveDataFromCurrentGame();
                    saveSystem.AutoSave(autoSaveData);
                }
            }
        }

        private void OnApplicationFocus(bool hasFocus)
        {
            if (!hasFocus && currentGameState == GameState.Playing)
            {
                ChangeGameState(GameState.Paused);
            }
            else if (hasFocus && currentGameState == GameState.Paused)
            {
                ChangeGameState(GameState.Playing);
            }
        }

        private void OnDestroy()
        {
            if (sceneController != null)
            {
                sceneController.OnSceneLoadCompleted -= OnSceneLoadCompleted;
            }
        }
    }

    /// <summary>
    /// ゲーム状態列挙型
    /// </summary>
    public enum GameState
    {
        MainMenu,
        Playing,
        Battle,
        Paused,
        Loading,
        GameOver
    }

    /// <summary>
    /// ゲームデータ構造体
    /// </summary>
    [Serializable]
    public class GameData
    {
        public string playerName = "";
        public float playTime = 0f;
        public int level = 1;
        public int gold = 1000;
        public int orbs = 0;
        public bool isDLCUnlocked = false;
        public Dictionary<string, bool> gameFlags = new Dictionary<string, bool>();
    }

    /// <summary>
    /// ゲーム設定ScriptableObject
    /// </summary>
    [CreateAssetMenu(fileName = "Game Configuration", menuName = "NegabokuRPG/Game Configuration")]
    public class GameConfiguration : ScriptableObject
    {
        [Header("パーティ設定 - 2人固定システム")]
        public int maxPartySize = GameConstants.MAX_PARTY_SIZE;
        public int initialPartySize = GameConstants.INITIAL_PARTY_SIZE;
        
        [Header("初期値")]
        public int initialGold = GameConstants.INITIAL_GOLD;
        public int initialLevel = GameConstants.INITIAL_LEVEL;
        
        [Header("システム設定")]
        public bool autoSaveEnabled = true;
        public float autoSaveInterval = 300f; // 5分
        
        [Header("デバッグ")]
        public bool debugMode = false;
        public bool unlockAllContent = false;
    }
}