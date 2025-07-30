using NUnit.Framework;
using NegabokuRPG.Infrastructure.DependencyInjection;
using System;

namespace NegabokuRPG.Tests.Infrastructure
{
    /// <summary>
    /// サービスコンテナのテスト（DI導入）
    /// </summary>
    [TestFixture]
    public class ServiceContainerTests
    {
        private SimpleServiceContainer _container;

        [SetUp]
        public void SetUp()
        {
            _container = new SimpleServiceContainer();
        }

        [TearDown]
        public void TearDown()
        {
            _container.Clear();
        }

        [Test]
        public void シングルトン登録_同じインスタンスが返される()
        {
            // Given: シングルトンサービスを登録
            _container.RegisterSingleton<ITestService, TestService>();
            
            // When: 2回解決する
            var instance1 = _container.Resolve<ITestService>();
            var instance2 = _container.Resolve<ITestService>();
            
            // Then: 同じインスタンスが返される
            Assert.IsNotNull(instance1);
            Assert.IsNotNull(instance2);
            Assert.AreSame(instance1, instance2);
        }

        [Test]
        public void シングルトンインスタンス登録_指定したインスタンスが返される()
        {
            // Given: 特定のインスタンスでシングルトン登録
            var specificInstance = new TestService();
            _container.RegisterSingleton<ITestService>(specificInstance);
            
            // When: サービスを解決
            var resolvedInstance = _container.Resolve<ITestService>();
            
            // Then: 指定したインスタンスが返される
            Assert.AreSame(specificInstance, resolvedInstance);
        }

        [Test]
        public void トランジェント登録_異なるインスタンスが返される()
        {
            // Given: トランジェントサービスを登録
            _container.RegisterTransient<ITestService, TestService>();
            
            // When: 2回解決する
            var instance1 = _container.Resolve<ITestService>();
            var instance2 = _container.Resolve<ITestService>();
            
            // Then: 異なるインスタンスが返される
            Assert.IsNotNull(instance1);
            Assert.IsNotNull(instance2);
            Assert.AreNotSame(instance1, instance2);
        }

        [Test]
        public void 未登録サービス解決_例外が発生する()
        {
            // Given: サービスを登録しない
            
            // When & Then: 未登録サービスの解決で例外が発生
            Assert.Throws<InvalidOperationException>(() => 
                _container.Resolve<ITestService>());
        }

        [Test]
        public void IsRegistered_登録済みサービスでtrue()
        {
            // Given: サービスを登録
            _container.RegisterSingleton<ITestService, TestService>();
            
            // When & Then: 登録チェックでtrueが返される
            Assert.IsTrue(_container.IsRegistered<ITestService>());
        }

        [Test]
        public void IsRegistered_未登録サービスでfalse()
        {
            // Given: サービスを登録しない
            
            // When & Then: 登録チェックでfalseが返される
            Assert.IsFalse(_container.IsRegistered<ITestService>());
        }

        [Test]
        public void Unregister_サービス登録を解除できる()
        {
            // Given: サービスを登録
            _container.RegisterSingleton<ITestService, TestService>();
            Assert.IsTrue(_container.IsRegistered<ITestService>());
            
            // When: サービス登録を解除
            _container.Unregister<ITestService>();
            
            // Then: サービスが未登録状態になる
            Assert.IsFalse(_container.IsRegistered<ITestService>());
        }

        [Test]
        public void Clear_全サービスがクリアされる()
        {
            // Given: 複数のサービスを登録
            _container.RegisterSingleton<ITestService, TestService>();
            _container.RegisterTransient<IAnotherService, AnotherService>();
            
            Assert.IsTrue(_container.IsRegistered<ITestService>());
            Assert.IsTrue(_container.IsRegistered<IAnotherService>());
            
            // When: 全サービスをクリア
            _container.Clear();
            
            // Then: 全サービスが未登録状態になる
            Assert.IsFalse(_container.IsRegistered<ITestService>());
            Assert.IsFalse(_container.IsRegistered<IAnotherService>());
        }

        [Test]
        public void 依存関係のあるサービス_正しく解決される()
        {
            // Given: 依存関係のあるサービスを登録
            _container.RegisterSingleton<ITestService, TestService>();
            _container.RegisterTransient<IDependentService, DependentService>();
            
            // When: 依存関係のあるサービスを解決
            var dependentService = _container.Resolve<IDependentService>();
            
            // Then: 依存関係が正しく注入される
            Assert.IsNotNull(dependentService);
            Assert.IsNotNull(((DependentService)dependentService).TestService);
        }

        [Test]
        public void NullインスタンスでのSingleton登録_例外が発生する()
        {
            // Given & When & Then: Nullインスタンスでの登録で例外が発生
            Assert.Throws<ArgumentNullException>(() => 
                _container.RegisterSingleton<ITestService>(null));
        }
    }

    // テスト用のインターフェースと実装クラス
    public interface ITestService
    {
        string GetMessage();
    }

    public class TestService : ITestService
    {
        public string GetMessage()
        {
            return "Test Service";
        }
    }

    public interface IAnotherService
    {
        void DoSomething();
    }

    public class AnotherService : IAnotherService
    {
        public void DoSomething()
        {
            // テスト用の空実装
        }
    }

    public interface IDependentService
    {
        void ProcessWithDependency();
    }

    public class DependentService : IDependentService
    {
        public ITestService TestService { get; }

        public DependentService(ITestService testService)
        {
            TestService = testService;
        }

        public void ProcessWithDependency()
        {
            // 依存関係を使用した処理
            TestService.GetMessage();
        }
    }
}