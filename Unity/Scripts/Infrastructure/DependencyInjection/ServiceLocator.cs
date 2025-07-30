using UnityEngine;

namespace NegabokuRPG.Infrastructure.DependencyInjection
{
    /// <summary>
    /// サービスロケーター
    /// Unity環境でのグローバルなサービスアクセスを提供
    /// </summary>
    public static class ServiceLocator
    {
        private static IServiceContainer _container;
        
        /// <summary>
        /// サービスコンテナを初期化
        /// </summary>
        /// <param name="container">使用するサービスコンテナ</param>
        public static void Initialize(IServiceContainer container)
        {
            _container = container;
        }
        
        /// <summary>
        /// デフォルトコンテナで初期化
        /// </summary>
        public static void Initialize()
        {
            _container = new SimpleServiceContainer();
        }
        
        /// <summary>
        /// サービスを解決
        /// </summary>
        /// <typeparam name="T">取得する型</typeparam>
        /// <returns>サービスインスタンス</returns>
        public static T Resolve<T>() where T : class
        {
            if (_container == null)
            {
                Debug.LogError("ServiceLocator is not initialized. Call ServiceLocator.Initialize() first.");
                return null;
            }
            
            return _container.Resolve<T>();
        }
        
        /// <summary>
        /// シングルトンサービスを登録
        /// </summary>
        /// <typeparam name="TInterface">インターフェース型</typeparam>
        /// <typeparam name="TImplementation">実装型</typeparam>
        public static void RegisterSingleton<TInterface, TImplementation>()
            where TImplementation : class, TInterface
            where TInterface : class
        {
            EnsureInitialized();
            _container.RegisterSingleton<TInterface, TImplementation>();
        }
        
        /// <summary>
        /// シングルトンサービスをインスタンス指定で登録
        /// </summary>
        /// <typeparam name="TInterface">インターフェース型</typeparam>
        /// <param name="instance">インスタンス</param>
        public static void RegisterSingleton<TInterface>(TInterface instance)
            where TInterface : class
        {
            EnsureInitialized();
            _container.RegisterSingleton(instance);
        }
        
        /// <summary>
        /// トランジェントサービスを登録
        /// </summary>
        /// <typeparam name="TInterface">インターフェース型</typeparam>
        /// <typeparam name="TImplementation">実装型</typeparam>
        public static void RegisterTransient<TInterface, TImplementation>()
            where TImplementation : class, TInterface
            where TInterface : class
        {
            EnsureInitialized();
            _container.RegisterTransient<TInterface, TImplementation>();
        }
        
        /// <summary>
        /// サービスが登録されているかチェック
        /// </summary>
        /// <typeparam name="T">チェックする型</typeparam>
        /// <returns>登録されている場合true</returns>
        public static bool IsRegistered<T>() where T : class
        {
            if (_container == null) return false;
            return _container.IsRegistered<T>();
        }
        
        /// <summary>
        /// サービスの登録を解除
        /// </summary>
        /// <typeparam name="T">解除する型</typeparam>
        public static void Unregister<T>() where T : class
        {
            EnsureInitialized();
            _container.Unregister<T>();
        }
        
        /// <summary>
        /// 全サービスをクリア
        /// </summary>
        public static void Clear()
        {
            _container?.Clear();
        }
        
        /// <summary>
        /// サービスロケーターをリセット
        /// </summary>
        public static void Reset()
        {
            _container?.Clear();
            _container = null;
        }
        
        /// <summary>
        /// 初期化チェック
        /// </summary>
        private static void EnsureInitialized()
        {
            if (_container == null)
            {
                Initialize(); // デフォルトコンテナで自動初期化
            }
        }
    }
}