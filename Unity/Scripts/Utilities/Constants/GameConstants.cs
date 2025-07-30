using UnityEngine;

namespace NegabokuRPG.Utilities
{
    /// <summary>
    /// ゲーム全体の定数定義
    /// </summary>
    public static class GameConstants
    {
        // パーティシステム
        public const int REQUIRED_PARTY_SIZE = 2;
        public const int MAX_PARTY_SIZE = 2;
        public const int INITIAL_PARTY_SIZE = 2;
        
        // 初期値
        public const int INITIAL_GOLD = 1000;
        public const int INITIAL_LEVEL = 1;
        
        // システム設定
        public const float AUTO_SAVE_INTERVAL = 300f; // 5分
        public const bool AUTO_SAVE_ENABLED = true;
        
        // デバッグ
        public const bool DEBUG_MODE = false;
        public const bool UNLOCK_ALL_CONTENT = false;
    }
}