namespace NegabokuRPG.Domain.ValueObjects
{
    /// <summary>
    /// 関係レベル（5段階システム: -25～100を25刻み）
    /// </summary>
    public enum RelationshipLevel
    {
        /// <summary>
        /// 敵対 (-25～0)
        /// 対立技が使用可能
        /// </summary>
        Hostile,
        
        /// <summary>
        /// 冷淡 (1～25)
        /// 協力的な行動が制限される
        /// </summary>
        Cold,
        
        /// <summary>
        /// 普通 (26～50)
        /// 標準的な相互作用、基本スキルのみ使用可能
        /// </summary>
        Neutral,
        
        /// <summary>
        /// 友好 (51～75)
        /// 共闘技が発動可能、協力的な選択肢が増加
        /// </summary>
        Friendly,
        
        /// <summary>
        /// 親密 (76～100)
        /// 共闘技が最大威力で発動、特別なイベント選択肢が出現
        /// </summary>
        Intimate
    }
}