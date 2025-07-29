using UnityEngine;

namespace NegabokuRPG.Utilities
{
    /// <summary>
    /// 関係値システムの定数定義
    /// </summary>
    public static class RelationshipConstants
    {
        // 基本設定
        public const int MIN_VALUE = -25;
        public const int MAX_VALUE = 100;
        public const int DEFAULT_VALUE = 50;
        public const int STEP_SIZE = 25;
        public const int HALF_STEP_SIZE = 12;
        
        // レベル閾値
        public const int INTIMATE_THRESHOLD = 76;    // 親密レベル (100-76)
        public const int FRIENDLY_THRESHOLD = 51;    // 友好レベル (75-51)
        public const int NEUTRAL_THRESHOLD = 26;     // 普通レベル (50-26)
        public const int COLD_THRESHOLD = 1;         // 冷淡レベル (25-1)
        // 敵対レベル (0～-25) は0以下
        
        // スキル発動閾値
        public const int COOPERATION_THRESHOLD = 76; // 共闘技発動
        public const int CONFLICT_THRESHOLD = 0;     // 対立技発動
        
        // バトルイベント変動値
        public const int LARGE_POSITIVE_CHANGE = 25;  // 大きな協力
        public const int LARGE_NEGATIVE_CHANGE = -25; // 大きな対立
        public const int SMALL_POSITIVE_CHANGE = 12;  // 小さな協力
        public const int SMALL_NEGATIVE_CHANGE = -12; // 小さな対立
        
        // 特殊イベント変動値
        public const int PROTECTION_BENEFICIARY_CHANGE = 25; // 守られた側
        public const int PROTECTION_PROTECTOR_CHANGE = 12;   // 守った側
    }
}