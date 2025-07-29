# 人間関係値ローグライクRPG - Unity版

UnityとC#で実装された人間関係値によって戦闘が動的に変化するローグライクRPGです。
Windows/Mac対応で、将来の拡張性を考慮した設計になっています。

## プロジェクト構造

```
Assets/
├── Scripts/
│   ├── Core/                    # コアシステム
│   │   ├── GameManager.cs       # ゲーム全体の管理
│   │   ├── SceneController.cs   # シーン遷移管理
│   │   └── EventSystem.cs       # イベントシステム
│   ├── Data/                    # データ定義・ScriptableObject
│   │   ├── Character/           # キャラクター関連データ
│   │   ├── Skills/              # スキル関連データ
│   │   ├── Dungeons/            # ダンジョン関連データ
│   │   └── Items/               # アイテム関連データ
│   ├── Systems/                 # ゲームシステム
│   │   ├── Relationship/        # 関係値システム
│   │   ├── Battle/              # バトルシステム
│   │   ├── Dungeon/             # ダンジョンシステム
│   │   ├── Save/                # セーブシステム
│   │   └── Skill/               # スキルシステム
│   ├── UI/                      # UIシステム
│   │   ├── Menus/               # メニュー画面
│   │   ├── Battle/              # バトル画面
│   │   ├── Dungeon/             # ダンジョン画面
│   │   └── Common/              # 共通UI
│   ├── Characters/              # キャラクター制御
│   │   ├── PlayerCharacter.cs   # プレイヤーキャラクター
│   │   ├── BattleCharacter.cs   # バトル時キャラクター
│   │   └── CharacterController.cs # キャラクター操作
│   └── Utilities/               # ユーティリティ
│       ├── Extensions/          # 拡張メソッド
│       ├── Helpers/             # ヘルパークラス
│       └── Constants/           # 定数定義
├── Scenes/                      # シーンファイル
│   ├── MainMenu.unity           # メインメニュー
│   ├── Battle.unity             # バトル画面
│   ├── Dungeon.unity            # ダンジョン探索
│   └── GameManager.unity        # ゲーム管理シーン
├── Resources/                   # リソースファイル
│   ├── Characters/              # キャラクターデータ
│   ├── Skills/                  # スキルデータ
│   └── Dungeons/                # ダンジョンデータ
├── Prefabs/                     # プレファブ
│   ├── UI/                      # UI部品
│   ├── Characters/              # キャラクター
│   └── Effects/                 # エフェクト
└── StreamingAssets/             # 設定ファイル
    └── Config/                  # ゲーム設定
```

## 技術仕様

### プラットフォーム対応
- **Windows**: x64対応、.NET Standard 2.1
- **Mac**: Intel/Apple Silicon対応
- **将来対応予定**: Linux、モバイル

### アーキテクチャ
- **MVPパターン**: UI分離による保守性向上
- **Singleton**: ゲーム状態管理
- **ScriptableObject**: データ駆動設計
- **Event-driven**: 疎結合なシステム間通信
- **Component System**: Unity標準の拡張可能アーキテクチャ

### パフォーマンス最適化
- **Object Pooling**: メモリ効率化
- **Addressable Assets**: 動的ロード対応
- **Serialization**: 高速セーブ/ロード
- **Coroutines**: 非同期処理

## 拡張性設計

### モジュール化
- 各システムは独立したモジュールとして設計
- インターフェースベースの依存関係
- プラグイン形式での機能追加対応

### データ駆動
- ScriptableObjectによる設定データ化
- JSON/XMLでの外部設定ファイル対応
- ローカライゼーション対応準備

### 将来拡張対応
- マルチプレイヤー対応準備
- VR/AR対応準備
- ストリーミング対応準備
- クラウドセーブ対応準備