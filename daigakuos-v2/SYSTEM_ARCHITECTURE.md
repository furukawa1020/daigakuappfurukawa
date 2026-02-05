# DaigakuAPP システムアーキテクチャ

> 自分専用の究極の自己管理アプリへの道のり

------

## アプリケーション全体像

```mermaid
graph TB
    User[👤 ユーザー] --> UI[📱 Flutter UI]
    UI --> State[🔄 Riverpod State Management]
    State --> DB[(💾 SQLite Database)]
    State --> Location[📍 Geolocator]
    State --> Prefs[⚙️ SharedPreferences]
    
    DB --> Sessions[セッション記録]
    DB --> Nodes[学習ノード]
    DB --> Stats[統計データ]
    
    UI --> Export[📤 データエクスポート]
    Export --> JSON[JSON]
    Export --> CSV[CSV]
    Export --> SQL[SQL]
    
    style User fill:#4F46E5
    style UI fill:#EC4899
    style DB fill:#10B981
```

------

## 技術スタック

```mermaid
graph LR
    subgraph "Frontend"
        Flutter[Flutter 3.38]
        Riverpod[Riverpod v3]
        Material[Material Design 3]
    end
    
    subgraph "State & Logic"
        StateProvider[State Providers]
        AsyncProvider[Async Providers]
        FutureProvider[Future Providers]
    end
    
    subgraph "Data Layer"
        SQLite[sqflite]
        Prefs[shared_preferences]
    end
    
    subgraph "Features"
        Geolocation[geolocator]
        Charts[fl_chart]
        Calendar[table_calendar]
        Animation[flutter_animate]
    end
    
    Flutter --> Riverpod
    Riverpod --> StateProvider
    Riverpod --> AsyncProvider
    StateProvider --> SQLite
    StateProvider --> Prefs
    
    style Flutter fill:#02569B
    style Riverpod fill:#00D9FF
    style SQLite fill:#003B57
```

------

## データフロー

```mermaid
sequenceDiagram
    participant U as ユーザー
    participant UI as UI Layer
    participant State as State Manager
    participant DB as Database
    participant Geo as Geolocation
    
    U->>UI: セッション開始
    UI->>State: startSession()
    State->>State: タイマー起動
    State->>Geo: 位置情報取得
    Geo-->>State: キャンパス判定
    
    U->>UI: セッション終了
    UI->>State: stopSession()
    State->>UI: 記録画面表示
    U->>UI: タイトル入力
    UI->>State: saveSession(title, nodeId)
    State->>DB: INSERT session
    State->>DB: ポイント計算
    DB-->>State: 統計更新
    State-->>UI: 完了通知
    
    U->>UI: 統計画面表示
    UI->>State: データ要求
    State->>DB: クエリ実行
    DB-->>State: 集計データ
    State-->>UI: グラフ描画
```

------

## 機能アーキテクチャ

```mermaid
graph TD
    subgraph "Core Features"
        Timer[⏱️ セッションタイマー]
        Record[📝 記録システム]
        Stats[📊 統計・可視化]
    end
    
    subgraph "Advanced Features"
        Campus[🏫 キャンパス検出]
        Calendar[📅 カレンダービュー]
        Export[📤 データエクスポート]
        WakeLock[🔒 画面常時ON]
    end
    
    subgraph "Data Processing"
        Points[💎 ポイント計算]
        Streak[🔥 連続記録]
        Nodes[🗂️ ノード管理]
    end
    
    Timer --> Record
    Record --> Points
    Points --> Stats
    Campus --> Points
    Stats --> Calendar
    Stats --> Export
    
    style Timer fill:#4F46E5
    style Stats fill:#EC4899
    style Export fill:#10B981
```

------

## データベーススキーマ

```mermaid
erDiagram
    SESSIONS ||--o{ NODES : belongs_to
    SESSIONS {
        int id PK
        datetime start_at
        int minutes
        string draft_title
        int node_id FK
        boolean is_on_campus
        datetime created_at
    }
    
    NODES {
        int id PK
        string name
        int total_minutes
        int session_count
        datetime last_used
        datetime created_at
    }
    
    USER_STATS {
        int total_sessions
        int total_minutes
        int total_points
        int current_streak
        int max_streak
        int level
    }
```

------

## 状態管理パターン

```mermaid
graph TB
    subgraph "Providers"
        Session[sessionProvider]
        OnCampus[isOnCampusProvider]
        History[historyProvider]
        Stats[userStatsProvider]
        Daily[dailyAggProvider]
        Weekly[weeklyAggProvider]
    end
    
    subgraph "UI Widgets"
        Now[NowScreen]
        Finish[FinishScreen]
        Home[HomeScreen]
        Calendar[CalendarScreen]
        Settings[SettingsScreen]
    end
    
    Session --> Now
    Session --> Finish
    History --> Home
    Stats --> Home
    Daily --> Home
    Weekly --> Home
    History --> Calendar
    
    style Session fill:#4F46E5
    style History fill:#EC4899
    style Stats fill:#10B981
```

------

## 今後の進化

```mermaid
mindmap
  root((DaigakuAPP))
    現在の機能
      セッション管理
      統計・可視化
      データエクスポート
    短期目標
      通知機能復活
        Android SDK対応待ち
      データインポート
        代替実装検討
    中期目標
      クラウド同期
        Firebase統合
      AIによる分析
        学習パターン検出
      SNS連携
        友達と競争
    長期ビジョン
      完全カスタマイズ
        ウィジェット追加
      マルチプラットフォーム
        Web版
        Desktop版
      エコシステム
        ブラウザ拡張
        スマートウォッチ
```

------

## アプリケーションライフサイクル

```mermaid
stateDiagram-v2
    [*] --> Idle: アプリ起動
    Idle --> Running: セッション開始
    Running --> Paused: アプリ最小化
    Paused --> Running: アプリ復帰
    Running --> Recording: 終了ボタン
    Recording --> Idle: 保存完了
    
    Idle --> Viewing: 統計表示
    Viewing --> Idle: ホームに戻る
    
    Idle --> Exporting: エクスポート
    Exporting --> Idle: 完了
    
    note right of Running
        WakeLock有効
        タイマー継続
        位置情報監視
    end note
    
    note right of Recording
        タイトル入力
        ノード選択
        ポイント計算
    end note
```

------

## パフォーマンス最適化

```mermaid
graph LR
    subgraph "最適化戦略"
        A[遅延読み込み] --> B[キャッシング]
        B --> C[バッチ更新]
        C --> D[インデックス活用]
    end
    
    subgraph "実装例"
        E[Provider auto-dispose]
        F[SQLite インデックス]
        G[画像最適化]
        H[Widget再利用]
    end
    
    A --> E
    B --> F
    C --> G
    D --> H
    
    style A fill:#4F46E5
    style E fill:#EC4899
```

------

## セキュリティとプライバシー

```mermaid
graph TD
    subgraph "データ保護"
        Local[ローカルストレージ]
        Encrypt[暗号化検討]
        Backup[バックアップ管理]
    end
    
    subgraph "権限管理"
        Location[位置情報]
        Storage[ストレージ]
        Wake[WakeLock]
    end
    
    Local --> Encrypt
    Encrypt --> Backup
    
    Location -.最小限.-> Local
    Storage -.必要時のみ.-> Local
    Wake -.セッション中のみ.-> Local
    
    style Local fill:#10B981
    style Encrypt fill:#F59E0B
```

------

## 開発ロードマップ

```mermaid
gantt
    title DaigakuAPP 開発計画
    dateFormat  YYYY-MM-DD
    section Phase 1
    基本機能実装           :done, 2026-02-01, 2026-02-04
    UI/UX改善             :done, 2026-02-04, 2026-02-05
    
    section Phase 2
    通知機能修正          :active, 2026-02-05, 7d
    データインポート代替   :2026-02-10, 5d
    
    section Phase 3
    クラウド同期          :2026-02-15, 14d
    AI分析機能           :2026-03-01, 21d
    
    section Phase 4
    Web版開発            :2026-04-01, 30d
    マルチプラットフォーム :2026-05-01, 45d
```

------

## まとめ

**DaigakuAPP** は、日々の自己管理を支える個人専用のプラットフォームです。

### 核となる哲学
- 📊 **データ駆動**: すべての行動を記録し、可視化
- 🎯 **シンプル**: 複雑な設定なしで即座に使える
- 🚀 **継続的進化**: 毎日使いながら改善を重ねる
- 💎 **完全所有**: あなたのデータはあなたのもの

### 現在地
- ✅ 基本機能完成
- ✅ 実機動作確認済み
- ⏳ Android SDK互換性課題対応中

### 未来へ
あなただけの最高の自己管理アプリを、一緒に作り続けましょう。
