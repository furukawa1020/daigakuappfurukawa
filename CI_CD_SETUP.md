# CI/CD セットアップ

このリポジトリには GitHub Actions を使用した CI/CD パイプラインが設定されています。

## ワークフロー

### Android CI/CD (.github/workflows/android-ci.yml)

このワークフローは以下のイベントで自動実行されます：
- `main` または `develop` ブランチへのプッシュ
- `main` または `develop` ブランチへのプルリクエスト
- 手動トリガー（workflow_dispatch）

#### 実行内容

1. **環境セットアップ**
   - Ubuntu 最新版
   - JDK 17 (Temurin)
   - Android SDK
   - Gradle キャッシュ

2. **ビルドプロセス**
   - Gradle wrapper の検証
   - プロジェクトのビルド
   - Lint チェック（エラーでも継続）
   - ユニットテスト実行（エラーでも継続）
   - Debug APK のビルド
   - Release APK のビルド

3. **アーティファクト**
   - Debug APK（30日間保存）
   - Release APK（30日間保存）
   - Lint 結果（7日間保存）
   - テスト結果（7日間保存）

## ローカルでのビルド

```bash
# Gradle wrapper を使用してビルド
./gradlew build

# Debug APK をビルド
./gradlew assembleDebug

# Release APK をビルド
./gradlew assembleRelease

# Lint チェックを実行
./gradlew lint

# ユニットテストを実行
./gradlew test
```

## 必要な要件

- JDK 17
- Android SDK (API 34)
- Gradle 8.9 以上

## トラブルシューティング

### ワークフローが実行されない

新しいワークフローや初回実行の場合、GitHub Actions の承認が必要な場合があります。
リポジトリの Settings > Actions で承認してください。

### ビルドエラー

- Android SDK のバージョンを確認してください
- `local.properties` ファイルに正しい SDK パスが設定されていることを確認してください
- Gradle キャッシュをクリアしてみてください: `./gradlew clean`
