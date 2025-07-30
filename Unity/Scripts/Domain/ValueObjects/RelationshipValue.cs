using System;

namespace NegabokuRPG.Domain.ValueObjects
{
    /// <summary>
    /// 関係値オブジェクト（値オブジェクト）
    /// 不変性を保証し、-25～100の範囲で25刻みの5段階システムを実装
    /// </summary>
    public readonly struct RelationshipValue : IEquatable<RelationshipValue>
    {
        // 定数定義
        public const int MIN_VALUE = -25;
        public const int MAX_VALUE = 100;
        public const int DEFAULT_VALUE = 50;
        public const int STEP_SIZE = 25;
        
        // 閾値定義
        public const int INTIMATE_THRESHOLD = 76;    // 親密レベル (100-76)
        public const int FRIENDLY_THRESHOLD = 51;    // 友好レベル (75-51)
        public const int NEUTRAL_THRESHOLD = 26;     // 普通レベル (50-26)
        public const int COLD_THRESHOLD = 1;         // 冷淡レベル (25-1)
        // 敵対レベル (0～-25) は0以下
        
        // スキル発動閾値
        public const int COOPERATION_THRESHOLD = 76; // 共闘技発動
        public const int CONFLICT_THRESHOLD = 0;     // 対立技発動
        
        private readonly int _value;
        
        /// <summary>
        /// 関係値
        /// </summary>
        public int Value => _value;
        
        /// <summary>
        /// 関係レベル
        /// </summary>
        public RelationshipLevel Level => CalculateLevel(_value);
        
        /// <summary>
        /// コンストラクタ（デフォルト値）
        /// </summary>
        public RelationshipValue() : this(DEFAULT_VALUE)
        {
        }
        
        /// <summary>
        /// コンストラクタ（値指定）
        /// </summary>
        /// <param name="value">関係値（-25～100の範囲でクランプされる）</param>
        public RelationshipValue(int value)
        {
            _value = Clamp(value, MIN_VALUE, MAX_VALUE);
        }
        
        /// <summary>
        /// 関係値を加算した新しいインスタンスを返す
        /// </summary>
        /// <param name="amount">加算値</param>
        /// <returns>新しい関係値インスタンス</returns>
        public RelationshipValue Add(int amount)
        {
            return new RelationshipValue(_value + amount);
        }
        
        /// <summary>
        /// 段階単位での変更（25刻み）
        /// </summary>
        /// <param name="steps">段階数（1.0で25、0.5で12～13）</param>
        /// <returns>新しい関係値インスタンス</returns>
        public RelationshipValue AddSteps(float steps)
        {
            int amount = (int)Math.Round(STEP_SIZE * steps);
            return Add(amount);
        }
        
        /// <summary>
        /// 共闘技が使用可能かチェック
        /// </summary>
        /// <returns>親密レベル（76以上）で使用可能</returns>
        public bool CanUseCooperationSkill()
        {
            return _value >= COOPERATION_THRESHOLD;
        }
        
        /// <summary>
        /// 対立技が使用可能かチェック
        /// </summary>
        /// <returns>敵対レベル（0以下）で使用可能</returns>
        public bool CanUseConflictSkill()
        {
            return _value <= CONFLICT_THRESHOLD;
        }
        
        /// <summary>
        /// 関係レベルを計算
        /// </summary>
        /// <param name="value">関係値</param>
        /// <returns>関係レベル</returns>
        private static RelationshipLevel CalculateLevel(int value)
        {
            if (value >= INTIMATE_THRESHOLD) return RelationshipLevel.Intimate;
            if (value >= FRIENDLY_THRESHOLD) return RelationshipLevel.Friendly;
            if (value >= NEUTRAL_THRESHOLD) return RelationshipLevel.Neutral;
            if (value >= COLD_THRESHOLD) return RelationshipLevel.Cold;
            return RelationshipLevel.Hostile;
        }
        
        /// <summary>
        /// 値をクランプする
        /// </summary>
        /// <param name="value">元の値</param>
        /// <param name="min">最小値</param>
        /// <param name="max">最大値</param>
        /// <returns>クランプされた値</returns>
        private static int Clamp(int value, int min, int max)
        {
            if (value < min) return min;
            if (value > max) return max;
            return value;
        }
        
        #region IEquatable<RelationshipValue> 実装
        
        public bool Equals(RelationshipValue other)
        {
            return _value == other._value;
        }
        
        public override bool Equals(object obj)
        {
            return obj is RelationshipValue other && Equals(other);
        }
        
        public override int GetHashCode()
        {
            return _value.GetHashCode();
        }
        
        public static bool operator ==(RelationshipValue left, RelationshipValue right)
        {
            return left.Equals(right);
        }
        
        public static bool operator !=(RelationshipValue left, RelationshipValue right)
        {
            return !left.Equals(right);
        }
        
        #endregion
        
        /// <summary>
        /// 文字列表現
        /// </summary>
        /// <returns>値とレベルの文字列</returns>
        public override string ToString()
        {
            return $"RelationshipValue({_value}, {Level})";
        }
    }
}