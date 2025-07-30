namespace NegabokuRPG.Domain.ValueObjects
{
    /// <summary>
    /// バトルイベントタイプ
    /// 関係値変動の理由を明確化する
    /// </summary>
    public enum BattleEventType
    {
        /// <summary>
        /// 協力行動 (+25, 相互)
        /// </summary>
        Cooperation,
        
        /// <summary>
        /// 誤射・フレンドリーファイア (-25, 相互)
        /// </summary>
        FriendlyFire,
        
        /// <summary>
        /// 保護行動（庇う）
        /// 保護者: +12, 被保護者: +25
        /// </summary>
        Protection,
        
        /// <summary>
        /// 対立・競争 (-12, 相互)
        /// </summary>
        Rivalry,
        
        /// <summary>
        /// 支援行動 (+12, 相互)
        /// </summary>
        Support
    }
}