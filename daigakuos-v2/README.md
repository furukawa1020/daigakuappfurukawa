# DaigakuAPP - 自分だけの最高の自己管理アプリへの旅

![Version](https://img.shields.io/badge/version-2.0.0-blue)
![Platform](https://img.shields.io/badge/platform-Flutter-02569B)
![Status](https://img.shields.io/badge/status-Active-success)

> **"毎日アップデートして、いつか自分だけの最高の自己管理アプリを作る"**

---

## 📖 ストーリー

### 始まり - The Origin

このプロジェクトは、一人の学生の「もっと効率的に自己管理したい」という純粋な願いから生まれました。

市販の自己管理アプリは数多くあれど、**自分の学習スタイルにぴったり合うものは見つからなかった**。そこで思いついたのが、

> 「自分で作れば、自分に完璧にフィットするアプリが作れるはずだ」

という、シンプルかつ野心的なアイデアでした。

### Phase 1: DaigakuOS (Kotlin/Android) - 2025年初頭

最初のバージョンは **Kotlin** と **Android ネイティブ** で開発されました。

**主な機能:**
- ⏱️ セッションタイマー
- 📊 基本的な統計
- 🏫 キャンパス判定（Geofencing）
- 💾 Room Database

**学んだこと:**
- Android開発の基礎
- MVVMアーキテクチャ
- Hilt依存性注入
- JetpackCompose UI

**課題:**
- コードの複雑化
- メンテナンスの困難さ
- プラットフォーム依存

### Phase 2: 大転換 - Flutter への移行（2026年2月1日）

**なぜFlutter？**

1. **クロスプラットフォーム**: いつかiOSやWebにも展開したい
2. **開発速度**: ホットリロードで反復が早い
3. **モダンなUI**: Material Design 3への完全対応
4. **成長機会**: 新しい技術スタックの習得

この決断により、プロジェクトは **DaigakuAPP v2.0** として生まれ変わりました。

### 開発の軌跡 - 2026年2月1日〜5日（5日間の激闘）

#### Day 1-2: 基盤構築
```
✅ Flutter プロジェクト初期化
✅ Riverpod state management 導入
✅ SQLite database 設計
✅ 基本的なタイマー機能実装
```

#### Day 3: 機能拡充
```
✅ 統計・可視化機能（fl_chart）
✅ カレンダービュー（table_calendar）
✅ データエクスポート（JSON/CSV/SQL）
✅ Geolocation統合
```

#### Day 4: UI/UX 革命
```
✅ Glassmorphism デザイン
✅ 日本語完全対応
✅ Premium animations（flutter_animate）
✅ Confetti エフェクト
```

#### Day 5: ビルドとの戦い
```
⚔️ Riverpod v2 → v3 migration
⚔️ flutter_local_notifications 互換性問題
⚔️ file_picker v1 embedding エラー
✅ 最終的に実機インストール成功！
```

---

## 🎯 現在の機能

### ✅ 完全実装済み

| 機能 | 説明 | 状態 |
|------|------|------|
| ⏱️ **セッションタイマー** | 学習時間の計測と記録 | ✅ 完成 |
| 📊 **統計ダッシュボード** | 日次・週次の集計とグラフ | ✅ 完成 |
| 📅 **カレンダービュー** | 学習履歴のカレンダー表示 | ✅ 完成 |
| 🏫 **キャンパス検出** | GPS自動判定でポイント変動 | ✅ 完成 |
| 💎 **ポイントシステム** | レベル・経験値・連続記録 | ✅ 完成 |
| 🗂️ **ノード管理** | 学習テーマの自動整理 | ✅ 完成 |
| 📤 **データエクスポート** | JSON/CSV/SQL形式対応 | ✅ 完成 |
| 🔒 **WakeLock** | セッション中の画面常時ON | ✅ 完成 |
| 🌏 **完全日本語化** | すべてのUIが日本語 | ✅ 完成 |
| 🎨 **Premium UI** | Glassmorphism & Animations | ✅ 完成 |

### ⏳ 開発中・課題

| 機能 | 状態 | 理由 |
|------|------|------|
| 🔔 **通知機能** | ❌ 保留中 | Android SDK 35互換性問題 |
| 📥 **データインポート** | ❌ 保留中 | file_picker v1 embedding エラー |

---

## 🛠️ 技術スタック

### Frontend
- **Framework**: Flutter 3.38.5
- **State Management**: Riverpod 3.2.1
- **UI**: Material Design 3 + Glassmorphism

### Data & Storage
- **Database**: sqflite 2.3.2
- **Local Storage**: shared_preferences 2.2.0

### Features & Libraries
```yaml
geolocator: 14.0.2        # GPS位置情報
fl_chart: 1.1.1           # 統計グラフ
table_calendar: 3.1.0     # カレンダーUI
flutter_animate: 4.5.0    # アニメーション
confetti: 0.8.0           # お祝いエフェクト
wakelock_plus: 1.1.0      # 画面常時ON
share_plus: 12.0.1        # データ共有
google_fonts: 8.0.1       # タイポグラフィ
```

---

## 📈 統計（開発5日目時点）

### コードメトリクス
- **総ファイル数**: 15+
- **総行数**: ~3,000行
- **コミット数**: 20+
- **Issue解決数**: 10+

### 開発時間
- **設計・計画**: 4時間
- **実装**: 12時間
- **デバッグ**: 8時間
- **ドキュメント**: 2時間
- **合計**: ~26時間

---

## 🚀 今後のロードマップ

### Phase 3: 機能完成（2026年2月中）
- [ ] 通知機能の復活（プラグイン更新待ち）
- [ ] データインポート代替実装
- [ ] 詳細な学習分析レポート
- [ ] カスタムテーマ機能

### Phase 4: クラウド統合（2026年3月）
- [ ] Firebase Authentication
- [ ] Firestore データ同期
- [ ] 複数デバイス対応
- [ ] データバックアップ自動化

### Phase 5: AI & Analytics（2026年4月）
- [ ] 学習パターン分析
- [ ] 最適な学習時間提案
- [ ] モチベーション予測
- [ ] パーソナライズド推奨

### Phase 6: エコシステム拡張（2026年5月〜）
- [ ] Web版（Flutter Web）
- [ ] Desktop版（Windows/Mac/Linux）
- [ ] ブラウザ拡張機能
- [ ] スマートウォッチ対応

---

## 💡 開発哲学

### 1. **継続的進化**
毎日使って、毎日改善する。完璧を目指すのではなく、昨日より良くなることを目指す。

### 2. **データ駆動**
感覚ではなく、データに基づいて自己管理。すべての学習セッションを記録し、可視化する。

### 3. **シンプルさ**
複雑な設定や操作は不要。タップ一つでセッション開始、タップ一つで記録完了。

### 4. **プライバシー第一**
データはすべてローカルに保存。あなたのデータはあなただけのもの。

### 5. **美しさ**
機能だけでなく、見た目も大切。使っていて楽しくなるUIを追求。

---

## 🏆 達成したマイルストーン

- [x] ✅ **2026/02/01** - プロジェクト開始、Flutter移行決定
- [x] ✅ **2026/02/02** - 基本機能実装完了
- [x] ✅ **2026/02/03** - 統計・可視化機能追加
- [x] ✅ **2026/02/04** - Premium UI実装、日本語化完了
- [x] ✅ **2026/02/05** - 実機ビルド成功、初回リリース！

---

## 🤝 学んだ教訓

### 技術面
1. **Riverpod v3移行**: Legacy import が必要（StateProvider）
2. **Android SDK互換性**: 最新SDKとプラグインの互換性に注意
3. **V1/V2 Embedding**: Flutter V2への完全移行が重要
4. **ビルド最適化**: 依存関係の慎重な選択が安定性を左右

### 開発プロセス
1. **小さく始める**: MVPから始めて、徐々に機能追加
2. **テストを怠らない**: 実機テストは早めに、頻繁に
3. **ドキュメント化**: 未来の自分のためにメモを残す
4. **エラーと向き合う**: エラーは学びの機会

---

## 📊 プロジェクト構造

```
daigakuos-v2/
├── client/                    # Flutter アプリケーション
│   ├── lib/
│   │   ├── main.dart         # エントリポイント
│   │   ├── database_helper.dart
│   │   ├── calendar_screen.dart
│   │   └── settings_screen.dart
│   ├── pubspec.yaml          # 依存関係
│   └── android/              # Android設定
├── SYSTEM_ARCHITECTURE.md    # システム図
├── README.md                 # このファイル
└── .gemini/                  # 開発履歴・計画
    └── brain/
        ├── task.md
        ├── implementation_plan.md
        └── walkthrough.md
```

---

## 🎓 謝辞

このプロジェクトは、以下の方々・コミュニティの支援なしには実現できませんでした：

- **Flutter チーム** - 素晴らしいフレームワークの提供
- **Riverpod コミュニティ** - 明確なドキュメントとサポート
- **Stack Overflow** - 無数のビルドエラー解決策
- **GitHub Copilot/Gemini** - AIペアプログラミング

そして何より、**自分自身** - 諦めずに続けたこと

---

## 📝 ライセンス

このプロジェクトは個人用途で開発されています。  
コードの一部を参考にする場合は、MIT Licenseに準じます。

---

## 🌟 最後に

**DaigakuAPP** は完成したアプリではありません。  
これは、**毎日進化し続けるプラットフォーム**です。

今日より明日、明日より明後日。  
少しずつ、確実に、自分だけの最高の自己管理アプリへ。

**Let's build the future, one session at a time. 🚀**

---

*Last Updated: 2026-02-05*  
*Version: 2.0.0*  
*Author: furukawa*  
*Repository: [github.com/furukawa1020/daigakuappfurukawa](https://github.com/furukawa1020/daigakuappfurukawa)*
