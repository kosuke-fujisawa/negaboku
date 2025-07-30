namespace NegabokuRPG.Domain.Specifications
{
    /// <summary>
    /// 仕様パターンの基本インターフェース
    /// ビジネスルールの評価とカプセル化を行う
    /// </summary>
    /// <typeparam name="T">評価対象の型</typeparam>
    public interface ISpecification<T>
    {
        /// <summary>
        /// 仕様を満たすかどうかを評価
        /// </summary>
        /// <param name="candidate">評価対象</param>
        /// <returns>仕様を満たす場合true</returns>
        bool IsSatisfiedBy(T candidate);
    }
}