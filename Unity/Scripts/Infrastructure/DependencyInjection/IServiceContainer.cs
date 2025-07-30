using System;

namespace NegabokuRPG.Infrastructure.DependencyInjection
{
    /// <summary>
    /// サービスコンテナのインターフェース
    /// 依存性注入の基本機能を提供
    /// </summary>
    public interface IServiceContainer
    {
        /// <summary>
        /// シングルトンサービスを登録
        /// </summary>
        /// <typeparam name="TInterface">インターフェース型</typeparam>
        /// <typeparam name="TImplementation">実装型</typeparam>
        void RegisterSingleton<TInterface, TImplementation>()
            where TImplementation : class, TInterface
            where TInterface : class;
        
        /// <summary>
        /// シングルトンサービスをインスタンス指定で登録
        /// </summary>
        /// <typeparam name="TInterface">インターフェース型</typeparam>
        /// <param name="instance">インスタンス</param>
        void RegisterSingleton<TInterface>(TInterface instance)
            where TInterface : class;
        
        /// <summary>
        /// トランジェントサービスを登録
        /// </summary>
        /// <typeparam name="TInterface">インターフェース型</typeparam>
        /// <typeparam name="TImplementation">実装型</typeparam>
        void RegisterTransient<TInterface, TImplementation>()
            where TImplementation : class, TInterface
            where TInterface : class;
        
        /// <summary>
        /// サービスを解決
        /// </summary>
        /// <typeparam name="T">取得する型</typeparam>
        /// <returns>サービスインスタンス</returns>
        T Resolve<T>() where T : class;
        
        /// <summary>
        /// サービスが登録されているかチェック
        /// </summary>
        /// <typeparam name="T">チェックする型</typeparam>
        /// <returns>登録されている場合true</returns>
        bool IsRegistered<T>() where T : class;
        
        /// <summary>
        /// サービスの登録を解除
        /// </summary>
        /// <typeparam name="T">解除する型</typeparam>
        void Unregister<T>() where T : class;
        
        /// <summary>
        /// 全サービスをクリア
        /// </summary>
        void Clear();
    }
}