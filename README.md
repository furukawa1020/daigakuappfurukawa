# DaigakunoiikangiOS - Focus Platform (Flutter + Rails)
@
このプロジェクトは、**Flutter** (マルチプラットフォーム・クライアント) と **Ruby on Rails** (中央同期サーバー) で構築された、プレミアムな集中・習慣化プラットフォームです。旧ネイティブ版から完全に移行し、単一のコードベースで高度なゲーミフィケーションを提供します!
※まだまだ調整中です
## アーキテクチャ

### システム構成 🚀

- **Frontend (Client)**: `daigakuos-v2/client` (Flutter)
  - **State Management**: Riverpod (v3 API) / Hooks
  - **Database**: SQLite (sqflite) によるローカルファースト設計
  - **Animation**: flutter_animate によるリッチなユーザー体験
  - **Navigation**: GoRouter による宣言的ルーティング

- **Backend (Server)**: `daigakuos-v2/server` (Ruby on Rails)
  - **API**: RESTful API (JSON)
  - **Real-time**: ActionCable によるグローバルレイドのリアルタイム同期
  - **Logic**: モコ図鑑の配信、ランキング計算、グローバル統計

## 主要機能

1.  **集中タイマー (NowScreen)**
    - 集中時間、グレード評価（S/A/B/C）、報酬計算ロジック。
    - キャンパス内ボーナス（1.5倍）、自宅警備ボーナス（1.2倍）の自動適用。
2.  **モコ・コレクション (Moko Collection)**
    - 累計集中時間に基づいたガチャシステム。
    - 60分ごとに1枚のガチャチケットを獲得。
3.  **ペット成長システム (Pet Evolution)**
    - 累計時間に応じてペット（モコ）が進化。
    - 卵 -> ベビー -> コモコ -> ティーン -> おとな -> マスター。
4.  **グローバル・レイド (Global Raid)**
    - 全ユーザーで協力して巨大なボスに立ち向かう。
    - セッションで獲得したXPがそのままボスへの攻撃力に。
5.  **実績システム (Achievements)**
    - 50種類以上の実績メダル。
    - 解除時のリッチなエフェクトとギャラリー表示。

## セットアップガイド

### 1. Flutterクライアント
```bash
cd daigakuos-v2/client
flutter pub get
flutter run
```

### 2. Railsサーバー
```bash
cd daigakuos-v2/server
bundle install
rails db:migrate
rails s
```
*※ クライアントがエミュレータの場合は `ApiService.dart` の `baseUrl` が `10.0.2.2:3000` を指していることを確認してください。*

## メンテナンス情報

- **バックアップ**: レガシーなネイティブAndroidプロジェクトは `native_android_backup.zip` にアーカイブされています。
- **ライセンス**: プライベート / 個人使用 (Furukawa専用)
