using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using NegabokuRPG.Characters;

namespace NegabokuRPG.Systems
{
    /// <summary>
    /// セーブ/ロードシステム - クロスプラットフォーム対応
    /// </summary>
    public class SaveSystem : MonoBehaviour
    {
        private static SaveSystem instance;
        public static SaveSystem Instance
        {
            get
            {
                if (instance == null)
                {
                    instance = FindObjectOfType<SaveSystem>();
                    if (instance == null)
                    {
                        var go = new GameObject("SaveSystem");
                        instance = go.AddComponent<SaveSystem>();
                        DontDestroyOnLoad(go);
                    }
                }
                return instance;
            }
        }

        [Header("設定")]
        [SerializeField] private int maxSaveSlots = 10;
        [SerializeField] private string saveFilePrefix = "save_slot_";
        [SerializeField] private string saveFileExtension = ".json";
        [SerializeField] private bool encryptSaveData = true;

        private string saveDirectory;

        // イベント
        public event Action<int> OnSaveCompleted;
        public event Action<int> OnLoadCompleted;
        public event Action<string> OnSaveError;

        private void Awake()
        {
            if (instance == null)
            {
                instance = this;
                DontDestroyOnLoad(gameObject);
                InitializeSaveSystem();
            }
            else if (instance != this)
            {
                Destroy(gameObject);
            }
        }

        /// <summary>
        /// セーブシステム初期化
        /// </summary>
        private void InitializeSaveSystem()
        {
            // プラットフォーム別のセーブディレクトリを設定
            SetupSaveDirectory();
            
            // ディレクトリ作成
            if (!Directory.Exists(saveDirectory))
            {
                Directory.CreateDirectory(saveDirectory);
            }
        }

        /// <summary>
        /// プラットフォーム別セーブディレクトリ設定
        /// </summary>
        private void SetupSaveDirectory()
        {
#if UNITY_EDITOR
            saveDirectory = Path.Combine(Application.persistentDataPath, "Saves");
#elif UNITY_STANDALONE_WIN
            // Windows: Documents/My Games/GameName/Saves
            string documentsPath = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
            string gameFolder = Path.Combine(documentsPath, "My Games", Application.productName);
            saveDirectory = Path.Combine(gameFolder, "Saves");
#elif UNITY_STANDALONE_OSX
            // Mac: ~/Library/Application Support/GameName/Saves
            string appSupportPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), Application.productName);
            saveDirectory = Path.Combine(appSupportPath, "Saves");
#else
            // その他: persistentDataPath使用
            saveDirectory = Path.Combine(Application.persistentDataPath, "Saves");
#endif
        }

        /// <summary>
        /// ゲームデータをセーブ
        /// </summary>
        public bool SaveGame(int slotNumber, GameSaveData saveData)
        {
            try
            {
                if (slotNumber < 1 || slotNumber > maxSaveSlots)
                {
                    OnSaveError?.Invoke($"Invalid save slot: {slotNumber}");
                    return false;
                }

                string filePath = GetSaveFilePath(slotNumber);
                
                // セーブデータにタイムスタンプ追加
                saveData.saveTimestamp = DateTime.Now;
                saveData.gameVersion = Application.version;

                // JSON変換
                string jsonData = JsonUtility.ToJson(saveData, true);

                // 暗号化（オプション）
                if (encryptSaveData)
                {
                    jsonData = EncryptData(jsonData);
                }

                // ファイル書き込み
                File.WriteAllText(filePath, jsonData);

                OnSaveCompleted?.Invoke(slotNumber);
                return true;
            }
            catch (Exception e)
            {
                Debug.LogError($"Save failed: {e.Message}");
                OnSaveError?.Invoke($"Save failed: {e.Message}");
                return false;
            }
        }

        /// <summary>
        /// ゲームデータをロード
        /// </summary>
        public GameSaveData LoadGame(int slotNumber)
        {
            try
            {
                if (slotNumber < 1 || slotNumber > maxSaveSlots)
                {
                    OnSaveError?.Invoke($"Invalid save slot: {slotNumber}");
                    return null;
                }

                string filePath = GetSaveFilePath(slotNumber);
                
                if (!File.Exists(filePath))
                {
                    return null;
                }

                // ファイル読み込み
                string jsonData = File.ReadAllText(filePath);

                // 復号化（オプション）
                if (encryptSaveData)
                {
                    jsonData = DecryptData(jsonData);
                }

                // JSON変換
                GameSaveData saveData = JsonUtility.FromJson<GameSaveData>(jsonData);

                // バージョンチェック
                if (!IsCompatibleVersion(saveData.gameVersion))
                {
                    Debug.LogWarning($"Save data version mismatch: {saveData.gameVersion} vs {Application.version}");
                    // 必要に応じて変換処理
                }

                OnLoadCompleted?.Invoke(slotNumber);
                return saveData;
            }
            catch (Exception e)
            {
                Debug.LogError($"Load failed: {e.Message}");
                OnSaveError?.Invoke($"Load failed: {e.Message}");
                return null;
            }
        }

        /// <summary>
        /// セーブファイルを削除
        /// </summary>
        public bool DeleteSave(int slotNumber)
        {
            try
            {
                if (slotNumber < 1 || slotNumber > maxSaveSlots)
                {
                    return false;
                }

                string filePath = GetSaveFilePath(slotNumber);
                
                if (File.Exists(filePath))
                {
                    File.Delete(filePath);
                    return true;
                }
                return false;
            }
            catch (Exception e)
            {
                Debug.LogError($"Delete save failed: {e.Message}");
                return false;
            }
        }

        /// <summary>
        /// セーブスロット情報を取得
        /// </summary>
        public List<SaveSlotInfo> GetSaveSlotInfos()
        {
            var slotInfos = new List<SaveSlotInfo>();

            for (int i = 1; i <= maxSaveSlots; i++)
            {
                var slotInfo = new SaveSlotInfo
                {
                    slotNumber = i,
                    isOccupied = HasSaveData(i)
                };

                if (slotInfo.isOccupied)
                {
                    try
                    {
                        string filePath = GetSaveFilePath(i);
                        FileInfo fileInfo = new FileInfo(filePath);
                        slotInfo.lastModified = fileInfo.LastWriteTime;

                        // 簡単なヘッダー情報を読み込み
                        var saveData = LoadGame(i);
                        if (saveData != null)
                        {
                            slotInfo.playerName = saveData.playerName;
                            slotInfo.playTime = saveData.playTime;
                            slotInfo.level = saveData.playerLevel;
                            slotInfo.saveTimestamp = saveData.saveTimestamp;
                        }
                    }
                    catch (Exception e)
                    {
                        Debug.LogWarning($"Failed to read save slot {i} info: {e.Message}");
                        slotInfo.isCorrupted = true;
                    }
                }

                slotInfos.Add(slotInfo);
            }

            return slotInfos;
        }

        /// <summary>
        /// セーブデータが存在するかチェック
        /// </summary>
        public bool HasSaveData(int slotNumber)
        {
            if (slotNumber < 1 || slotNumber > maxSaveSlots)
                return false;

            return File.Exists(GetSaveFilePath(slotNumber));
        }

        /// <summary>
        /// セーブをコピー
        /// </summary>
        public bool CopySave(int fromSlot, int toSlot)
        {
            try
            {
                var saveData = LoadGame(fromSlot);
                if (saveData == null) return false;

                return SaveGame(toSlot, saveData);
            }
            catch (Exception e)
            {
                Debug.LogError($"Copy save failed: {e.Message}");
                return false;
            }
        }

        /// <summary>
        /// セーブをエクスポート
        /// </summary>
        public bool ExportSave(int slotNumber, string exportPath)
        {
            try
            {
                string filePath = GetSaveFilePath(slotNumber);
                if (!File.Exists(filePath)) return false;

                File.Copy(filePath, exportPath, true);
                return true;
            }
            catch (Exception e)
            {
                Debug.LogError($"Export save failed: {e.Message}");
                return false;
            }
        }

        /// <summary>
        /// セーブをインポート
        /// </summary>
        public bool ImportSave(string importPath, int slotNumber)
        {
            try
            {
                if (!File.Exists(importPath)) return false;

                string filePath = GetSaveFilePath(slotNumber);
                File.Copy(importPath, filePath, true);
                return true;
            }
            catch (Exception e)
            {
                Debug.LogError($"Import save failed: {e.Message}");
                return false;
            }
        }

        /// <summary>
        /// クイックセーブ
        /// </summary>
        public bool QuickSave(GameSaveData saveData)
        {
            return SaveGame(1, saveData); // スロット1をクイックセーブ用に使用
        }

        /// <summary>
        /// クイックロード
        /// </summary>
        public GameSaveData QuickLoad()
        {
            return LoadGame(1);
        }

        /// <summary>
        /// セーブファイルパスを取得
        /// </summary>
        private string GetSaveFilePath(int slotNumber)
        {
            string fileName = $"{saveFilePrefix}{slotNumber:D2}{saveFileExtension}";
            return Path.Combine(saveDirectory, fileName);
        }

        /// <summary>
        /// データ暗号化（簡易）
        /// </summary>
        private string EncryptData(string data)
        {
            // 簡易的なXOR暗号化
            byte[] dataBytes = System.Text.Encoding.UTF8.GetBytes(data);
            byte key = 0x5A; // 暗号化キー
            
            for (int i = 0; i < dataBytes.Length; i++)
            {
                dataBytes[i] ^= key;
            }
            
            return Convert.ToBase64String(dataBytes);
        }

        /// <summary>
        /// データ復号化（簡易）
        /// </summary>
        private string DecryptData(string encryptedData)
        {
            try
            {
                byte[] dataBytes = Convert.FromBase64String(encryptedData);
                byte key = 0x5A; // 復号化キー
                
                for (int i = 0; i < dataBytes.Length; i++)
                {
                    dataBytes[i] ^= key;
                }
                
                return System.Text.Encoding.UTF8.GetString(dataBytes);
            }
            catch
            {
                // 復号化失敗時は元データをそのまま返す（暗号化されていない古いデータ対応）
                return encryptedData;
            }
        }

        /// <summary>
        /// バージョン互換性チェック
        /// </summary>
        private bool IsCompatibleVersion(string saveVersion)
        {
            if (string.IsNullOrEmpty(saveVersion))
                return true; // 古いセーブデータは互換性ありとみなす

            // バージョン比較ロジック（実装に応じて調整）
            return saveVersion == Application.version;
        }

        /// <summary>
        /// 自動セーブ
        /// </summary>
        public void AutoSave(GameSaveData saveData)
        {
            // 専用の自動セーブスロットを使用
            SaveGame(maxSaveSlots, saveData);
        }

        /// <summary>
        /// セーブディレクトリを開く（デバッグ用）
        /// </summary>
        [ContextMenu("Open Save Directory")]
        public void OpenSaveDirectory()
        {
#if UNITY_EDITOR
            Application.OpenURL("file://" + saveDirectory);
#elif UNITY_STANDALONE_WIN
            System.Diagnostics.Process.Start("explorer.exe", saveDirectory);
#elif UNITY_STANDALONE_OSX
            System.Diagnostics.Process.Start("open", saveDirectory);
#endif
        }
    }

    /// <summary>
    /// ゲームセーブデータ
    /// </summary>
    [Serializable]
    public class GameSaveData
    {
        [Header("セーブ情報")]
        public DateTime saveTimestamp;
        public string gameVersion;
        public int slotNumber;

        [Header("プレイヤー情報")]
        public string playerName;
        public float playTime;
        public int playerLevel;
        public int gold;
        public int orbs;

        [Header("進行状況")]
        public GameProgressData gameProgress;
        public List<CharacterSaveData> partyMembers;
        public Dictionary<string, Dictionary<string, int>> relationships;
        public List<string> unlockedCharacters;
        public List<string> clearedDungeons;
        public List<string> availableDungeons;

        [Header("インベントリ")]
        public List<InventoryItemData> inventory;

        [Header("設定")]
        public bool dlcUnlocked;
        public Dictionary<string, bool> gameFlags;

        public GameSaveData()
        {
            gameProgress = new GameProgressData();
            partyMembers = new List<CharacterSaveData>();
            relationships = new Dictionary<string, Dictionary<string, int>>();
            unlockedCharacters = new List<string>();
            clearedDungeons = new List<string>();
            availableDungeons = new List<string>();
            inventory = new List<InventoryItemData>();
            gameFlags = new Dictionary<string, bool>();
        }
    }

    /// <summary>
    /// ゲーム進行データ
    /// </summary>
    [Serializable]
    public class GameProgressData
    {
        public string currentScene;
        public string currentDungeon;
        public int currentFloor;
        public Vector3 playerPosition;
        public Dictionary<string, bool> storyFlags;
        public Dictionary<string, bool> eventFlags;
        public List<string> endingsSeen;

        public GameProgressData()
        {
            storyFlags = new Dictionary<string, bool>();
            eventFlags = new Dictionary<string, bool>();
            endingsSeen = new List<string>();
        }
    }

    /// <summary>
    /// インベントリアイテムデータ
    /// </summary>
    [Serializable]
    public class InventoryItemData
    {
        public string itemId;
        public int quantity;
        public Dictionary<string, object> itemProperties;

        public InventoryItemData()
        {
            itemProperties = new Dictionary<string, object>();
        }
    }

    /// <summary>
    /// セーブスロット情報
    /// </summary>
    [Serializable]
    public class SaveSlotInfo
    {
        public int slotNumber;
        public bool isOccupied;
        public bool isCorrupted;
        public string playerName;
        public float playTime;
        public int level;
        public DateTime lastModified;
        public DateTime saveTimestamp;

        public string GetFormattedPlayTime()
        {
            int hours = Mathf.FloorToInt(playTime / 3600);
            int minutes = Mathf.FloorToInt((playTime % 3600) / 60);
            return $"{hours:D2}:{minutes:D2}";
        }
    }
}