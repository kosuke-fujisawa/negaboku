using System;
using System.Collections.Generic;

namespace NegabokuRPG.Infrastructure.DependencyInjection
{
    /// <summary>
    /// シンプルなサービスコンテナ実装
    /// Unity環境で軽量なDIを提供
    /// </summary>
    public class SimpleServiceContainer : IServiceContainer
    {
        private readonly Dictionary<Type, ServiceDescriptor> _services;
        private readonly Dictionary<Type, object> _singletonInstances;
        
        public SimpleServiceContainer()
        {
            _services = new Dictionary<Type, ServiceDescriptor>();
            _singletonInstances = new Dictionary<Type, object>();
        }
        
        public void RegisterSingleton<TInterface, TImplementation>()
            where TImplementation : class, TInterface
            where TInterface : class
        {
            var descriptor = new ServiceDescriptor
            {
                InterfaceType = typeof(TInterface),
                ImplementationType = typeof(TImplementation),
                Lifetime = ServiceLifetime.Singleton,
                Instance = null
            };
            
            _services[typeof(TInterface)] = descriptor;
        }
        
        public void RegisterSingleton<TInterface>(TInterface instance)
            where TInterface : class
        {
            if (instance == null)
                throw new ArgumentNullException(nameof(instance));
            
            var descriptor = new ServiceDescriptor
            {
                InterfaceType = typeof(TInterface),
                ImplementationType = instance.GetType(),
                Lifetime = ServiceLifetime.Singleton,
                Instance = instance
            };
            
            _services[typeof(TInterface)] = descriptor;
            _singletonInstances[typeof(TInterface)] = instance;
        }
        
        public void RegisterTransient<TInterface, TImplementation>()
            where TImplementation : class, TInterface
            where TInterface : class
        {
            var descriptor = new ServiceDescriptor
            {
                InterfaceType = typeof(TInterface),
                ImplementationType = typeof(TImplementation),
                Lifetime = ServiceLifetime.Transient,
                Instance = null
            };
            
            _services[typeof(TInterface)] = descriptor;
        }
        
        public T Resolve<T>() where T : class
        {
            return Resolve(typeof(T)) as T;
        }
        
        public object Resolve(Type serviceType)
        {
            if (!_services.TryGetValue(serviceType, out var descriptor))
            {
                throw new InvalidOperationException($"Service of type {serviceType.Name} is not registered.");
            }
            
            if (descriptor.Lifetime == ServiceLifetime.Singleton)
            {
                if (_singletonInstances.TryGetValue(serviceType, out var existingInstance))
                {
                    return existingInstance;
                }
                
                if (descriptor.Instance != null)
                {
                    return descriptor.Instance;
                }
                
                var newInstance = CreateInstance(descriptor.ImplementationType);
                _singletonInstances[serviceType] = newInstance;
                return newInstance;
            }
            
            // Transient
            return CreateInstance(descriptor.ImplementationType);
        }
        
        public bool IsRegistered<T>() where T : class
        {
            return _services.ContainsKey(typeof(T));
        }
        
        public void Unregister<T>() where T : class
        {
            var serviceType = typeof(T);
            _services.Remove(serviceType);
            _singletonInstances.Remove(serviceType);
        }
        
        public void Clear()
        {
            _services.Clear();
            _singletonInstances.Clear();
        }
        
        private object CreateInstance(Type implementationType)
        {
            var constructors = implementationType.GetConstructors();
            
            // パラメータなしコンストラクタを優先
            foreach (var constructor in constructors)
            {
                var parameters = constructor.GetParameters();
                if (parameters.Length == 0)
                {
                    return Activator.CreateInstance(implementationType);
                }
            }
            
            // パラメータありコンストラクタの場合、依存関係を解決
            var firstConstructor = constructors[0];
            var parameterInstances = new List<object>();
            
            foreach (var parameter in firstConstructor.GetParameters())
            {
                var parameterInstance = Resolve(parameter.ParameterType);
                parameterInstances.Add(parameterInstance);
            }
            
            return Activator.CreateInstance(implementationType, parameterInstances.ToArray());
        }
    }
    
    /// <summary>
    /// サービス記述子
    /// </summary>
    internal class ServiceDescriptor
    {
        public Type InterfaceType { get; set; }
        public Type ImplementationType { get; set; }
        public ServiceLifetime Lifetime { get; set; }
        public object Instance { get; set; }
    }
    
    /// <summary>
    /// サービスライフタイム
    /// </summary>
    public enum ServiceLifetime
    {
        /// <summary>
        /// シングルトン（アプリケーション全体で1つのインスタンス）
        /// </summary>
        Singleton,
        
        /// <summary>
        /// トランジェント（要求の度に新しいインスタンス）
        /// </summary>
        Transient
    }
}