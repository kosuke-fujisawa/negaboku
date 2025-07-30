# Negaboku 設計ドキュメント

このフォルダには、Negabokuプロジェクトの詳細な設計・実装ドキュメントが格納されています。

## ドキュメント一覧

### [development-scope.md](./development-scope.md)
- 開発範囲仕様書
- 必須機能と後回し機能の明確化
- 実装優先度の設定

### [architecture-design.md](./architecture-design.md)  
- アーキテクチャ設計書
- DDD + クリーンアーキテクチャの詳細設計
- レイヤー構成と責任分離
- プラットフォーム抽象化戦略

### [implementation-guidelines.md](./implementation-guidelines.md)
- 実装指針書
- データ形式・管理方針
- テスト戦略とカバレッジ目標
- コーディング規約
- パフォーマンス考慮事項

## 使用方法

開発時は、これらのドキュメントを参照して：

1. **機能開発前**: `development-scope.md` で実装範囲を確認
2. **設計時**: `architecture-design.md` でレイヤー設計を確認
3. **実装時**: `implementation-guidelines.md` で規約・方針を確認

## 更新ルール

- ドキュメントの更新は設置・仕様変更時に実施
- CLAUDE.mdには開発ガイドラインのみ記載
- 詳細な設計内容はこのdocsフォルダで管理