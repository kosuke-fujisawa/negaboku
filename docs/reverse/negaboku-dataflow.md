# Negaboku データフロー設計（逆生成）

## 分析日時
2025-01-05 01:00:00

## ゲームフロー概要

### メインゲームループ
```mermaid
flowchart TD
    A[アプリケーション起動] --> B[MainMenu.tscn]
    B --> C[新規ゲームボタン]
    C --> D[GameManager.start_new_game]
    D --> E[WorkingTextScene.tscn]
    E --> F[シナリオ読み込み]
    F --> G[関係値システム初期化]
    G --> H[ユーザー選択待ち]
    H --> I{選択肢タイプ}
    I -->|テキスト進行| J[次のシーン]
    I -->|関係値変更| K[RelationshipSystem更新]
    I -->|バトル発生| L[BattleSystem起動]
    J --> H
    K --> H
    L --> M[バトル結果]
    M --> H
```

## 関係値システムフロー

### 関係値変更プロセス
```mermaid
sequenceDiagram
    participant U as ユーザー
    participant UI as UIコンポーネント
    participant GM as GameManager
    participant RS as RelationshipSystem
    participant BS as BattleSystem
    participant Scene as テキストシーン
    
    U->>UI: 選択肢クリック
    UI->>GM: choice_selected Signal
    GM->>RS: modify_relationship()
    RS->>RS: 関係値計算・更新
    RS->>GM: relationship_changed Signal
    RS->>GM: relationship_level_changed Signal
    GM->>BS: 関係値変更通知
    GM->>Scene: UI更新指示
    Scene->>U: 関係値変更結果表示
```

### 関係値計算フロー
```mermaid
flowchart TD
    A[選択肢選択] --> B[関係値変更量決定]
    B --> C{現在の関係値}
    C --> D[MIN_VALUE=-25でクランプ]
    C --> E[MAX_VALUE=100でクランプ]
    D --> F[新しい関係値設定]
    E --> F
    F --> G[関係レベル判定]
    G --> H{レベル変更あり？}
    H -->|Yes| I[relationship_level_changed Signal]
    H -->|No| J[relationship_changed Signal]
    I --> K[UI・システム更新]
    J --> K
```

## バトルシステムフロー

### ターン制戦闘プロセス
```mermaid
stateDiagram-v2
    [*] --> IDLE : 戦闘システム初期化
    IDLE --> PREPARING : battle_started Signal
    PREPARING --> IN_PROGRESS : パーティ・敵初期化完了
    IN_PROGRESS --> ActionSelect : ターン開始
    ActionSelect --> SkillCheck : スキル選択
    SkillCheck --> RelationshipCheck : 関係値依存スキル？
    RelationshipCheck --> SkillExecute : 条件満足
    RelationshipCheck --> ActionSelect : 条件不満足
    SkillExecute --> DamageCalc : ダメージ計算
    DamageCalc --> TurnEnd : 結果反映
    TurnEnd --> IN_PROGRESS : 次のターン
    TurnEnd --> ENDING : 戦闘終了条件
    ENDING --> [*] : battle_ended Signal
```

### 関係値連動スキルシステム
```mermaid
flowchart TD
    A[スキル発動要求] --> B[関係値チェック]
    B --> C{スキルタイプ}
    C -->|COOPERATION| D[親密レベル必要]
    C -->|CONFLICT| E[対立レベル必要]
    C -->|NORMAL/MAGIC| F[常時使用可能]
    D --> G{関係値 >= 50}
    E --> H{関係値 <= -50 & 特定ペア}
    G -->|Yes| I[共闘技発動]
    G -->|No| J[発動失敗]
    H -->|Yes| K[対立技発動]
    H -->|No| J
    F --> L[通常スキル発動]
    I --> M[高威力+追加効果]
    K --> N[ハイリスクハイリターン]
    L --> O[標準効果]
```

## シナリオシステムフロー

### マークダウンファイル処理フロー
```mermaid
flowchart TD
    A[scene01.md読み込み要求] --> B[ScenarioLoader.force_reload]
    B --> C[キャッシュクリア]
    C --> D[MarkdownParser.parse_markdown_file]
    D --> E[ファイル存在チェック]
    E --> F[FileAccess.open]
    F --> G[get_as_text]
    G --> H[行ごと解析]
    H --> I{行タイプ判定}
    I -->|コマンド| J[_parse_command_line]
    I -->|スピーカー| K[_parse_speaker_text]
    I -->|テキスト| L[ParsedElement.TEXT]
    I -->|セパレーター| M[ParsedElement.SEPARATOR]
    J --> N[ParsedElement.COMMAND]
    K --> O[ParsedElement.SPEAKER]
    N --> P[解析結果配列]
    O --> P
    L --> P
    M --> P
    P --> Q[構文検証]
    Q --> R[ScenarioData構築]
    R --> S[キャッシュ保存]
    S --> T[UI表示用データ変換]
```

### シーン表示フロー
```mermaid
sequenceDiagram
    participant WTS as WorkingTextScene
    participant SL as ScenarioLoader
    participant MP as MarkdownParser
    participant UI as UI要素
    participant User as ユーザー
    
    WTS->>SL: _load_markdown_scenario()
    SL->>MP: parse_markdown_file()
    MP->>MP: ファイル読み込み・解析
    MP-->>SL: ParsedElement配列
    SL->>SL: convert_to_text_scene_data()
    SL-->>WTS: 変換済みシーンデータ
    WTS->>WTS: _show_markdown_scene_with_commands()
    WTS->>UI: 背景・キャラクター・テキスト更新
    UI-->>User: シーン表示
    User->>UI: クリック/キー入力
    UI->>WTS: _advance_text()
    WTS->>WTS: 次のシーンデータ取得
```

## UI・入力処理フロー

### ユーザー入力処理
```mermaid
flowchart TD
    A[ユーザー入力] --> B{入力タイプ}
    B -->|マウスクリック| C[_input MouseButton]
    B -->|キーボード| D[_unhandled_input]
    C --> E[_advance_text]
    D --> F{キー判定}
    F -->|ui_accept| E
    F -->|ui_cancel| G[GameManager.return_to_title]
    F -->|その他| H[無視]
    E --> I[シーンデータ更新]
    G --> J[MainMenu遷移]
    I --> K[UI表示更新]
```

### Signal連鎖フロー
```mermaid
graph TD
    A[choice_selected] --> B[GameManager処理]
    B --> C[relationship_changed]
    C --> D[UI更新トリガー]
    D --> E[battle_system連携]
    
    F[dialogue_finished] --> G[次テキスト表示]
    G --> H[sequence_completed]
    
    I[effect_completed] --> J[エフェクト終了処理]
    
    K[scene_changed] --> L[シーン遷移処理]
    L --> M[リソース初期化]
```

## データ永続化フロー

### セーブ・ロードシステム
```mermaid
sequenceDiagram
    participant User as ユーザー
    participant UI as セーブUI
    participant GM as GameManager
    participant FS as FileSystem
    participant RS as RelationshipSystem
    
    User->>UI: セーブ実行
    UI->>GM: save_game()
    GM->>RS: get_all_relationships()
    RS-->>GM: 関係値データDictionary
    GM->>GM: save_data構築
    GM->>FS: FileAccess.open("user://savegame.save")
    GM->>FS: store_string(JSON.stringify(save_data))
    FS-->>GM: 保存完了
    GM-->>UI: セーブ成功通知
    UI-->>User: セーブ完了表示
```

## エラー処理・フォールバックフロー

### ファイル読み込みエラー処理
```mermaid
flowchart TD
    A[ファイル読み込み要求] --> B[ファイル存在チェック]
    B --> C{FileAccess.file_exists}
    C -->|False| D[エラーログ出力]
    C -->|True| E[FileAccess.open]
    E --> F{ファイルオープン成功？}
    F -->|False| D
    F -->|True| G[get_as_text]
    G --> H{内容が空？}
    H -->|True| I[警告ログ + 空文字返却]
    H -->|False| J[正常処理続行]
    D --> K[デフォルトデータ使用]
    I --> K
    K --> L[フォールバック動作]
    J --> M[正常動作]
```

## パフォーマンス最適化フロー

### リソース管理最適化
```mermaid
flowchart TD
    A[リソース要求] --> B{キャッシュ存在？}
    B -->|Yes| C[キャッシュから取得]
    B -->|No| D[新規読み込み]
    D --> E[Object Pool確認]
    E --> F{再利用可能オブジェクト？}
    F -->|Yes| G[プールから取得]
    F -->|No| H[新規作成]
    G --> I[オブジェクト初期化]
    H --> I
    I --> J[キャッシュに保存]
    C --> K[使用]
    J --> K
    K --> L[使用完了]
    L --> M{プール対象？}
    M -->|Yes| N[プールに返却]
    M -->|No| O[解放]
```

## 統合デバッグフロー

### リアルタイムデバッグ機能
```mermaid
sequenceDiagram
    participant Dev as 開発者
    participant Debug as デバッグパネル
    participant RS as RelationshipSystem
    participant UI as ゲームUI
    
    Dev->>Debug: +25ボタンクリック
    Debug->>RS: modify_relationship("player", "partner", 25, "デバッグテスト")
    RS->>RS: 関係値更新処理
    RS->>Debug: relationship_changed Signal
    RS->>UI: UI更新トリガー
    Debug-->>Dev: 変更結果表示
    UI-->>Dev: ゲーム内反映確認
```

---

このデータフローは Godot の Scene + Node + Signal 駆動アーキテクチャを活用し、関係值重視型RPGの特性を反映した疎結合なイベント駆動システムを実現している。リアルタイムデバッグ機能により開発効率を大幅に向上させながら、エラー処理・フォールバック機能で安定性を確保している。