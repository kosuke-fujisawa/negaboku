# アーキテクチャ設計書

## 設計思想・原則

### アーキテクチャ設計思想
- **DDD（ドメイン駆動設計）とクリーンアーキテクチャを併用**: ゲームロジックを中心とした設計
- **依存方向の統一**: ドメイン → アプリケーション → UI の一方向依存
- **ドメイン層の独立性**: ゲームロジック（戦闘・関係値・イベント管理）を完結させ、UIや入出力に依存しない設計
- **テスタビリティ重視**: 外部依存を排除したユニットテスト可能な設計

### 移植性・拡張性
- **初期ターゲット**: Windows環境での安定動作を最優先
- **将来的移植性**: Mac/Linuxへの移植を視野に入れたOS依存処理の抽象化
- **インターフェース駆動**: プラットフォーム固有処理は抽象化インターフェース経由で実装
- **データ駆動設計**: ゲームデータを外部化し、容易な拡張・変更を可能にする

## レイヤー構成

### Domain層（最重要）
- **責任**: 戦闘ロジック、関係値変動ロジック、イベント条件判定
- **依存関係**: 他レイヤーに一切依存しない純粋なビジネスロジック
- **実装内容**:
  - ダメージ計算、技発動条件、勝敗判定
  - 関係値変動ロジック、レベル判定
  - 分岐条件の評価ロジック

### Application層（制御）
- **責任**: バトル進行制御、イベント制御、ユースケース実装
- **依存関係**: Domainに依存、InfrastructureとUIには依存しない
- **実装内容**:
  - 戦闘フロー管理、ターン制御
  - イベント進行、選択肢処理
  - 具体的な機能実行手順

### Infrastructure層（データ）
- **責任**: データロード、セーブ管理、外部連携
- **依存関係**: Domainのインターフェースを実装
- **実装内容**:
  - JSON/CSVからのゲームデータ読み込み
  - 進行状況・関係値の永続化
  - ファイルシステム、Unity固有機能への接続

### UI層（表示）
- **責任**: 表示制御、入力処理
- **依存関係**: ApplicationとPresentationに依存
- **実装内容**:
  - Unity標準の表示システム活用
  - プレイヤー操作の受付と変換
  - ゲーム状態の視覚化

## プラットフォーム抽象化

### 条件付きコンパイル
- `#if UNITY_STANDALONE_WIN` の適切な使用
- プラットフォーム固有処理の分離

### インターフェース設計
```csharp
public interface IPlatformService
{
    string GetSaveDataPath();
    void ShowNotification(string message);
}

#if UNITY_STANDALONE_WIN
public class WindowsPlatformService : IPlatformService { }
#elif UNITY_STANDALONE_OSX  
public class MacPlatformService : IPlatformService { }
#endif
```

### Unity設定統一
- **Scripting Backend**: IL2CPP（両プラットフォーム対応）
- **API Compatibility Level**: .NET Standard 2.1
- **入力システム**: New Input System使用（クロスプラット対応）