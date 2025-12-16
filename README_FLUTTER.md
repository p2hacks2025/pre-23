# 思い出掘り起こしアプリ - Flutter版

永久凍土に封印された思い出を発掘するアプリです。

## セットアップ

### 前提条件

- Flutter SDK 3.0.0以上
- Dart SDK 3.0.0以上

### インストール手順

1. 依存関係をインストール:
```bash
flutter pub get
```

2. アプリを実行:
```bash
flutter run
```

## 機能

- **ホーム画面**: 発掘した記憶を表示
- **記憶作成**: 写真とテキストで記憶を封印
- **発掘ゲーム**: ピクセルアートの永久凍土を発掘してアイテムや記憶を発見
- **コレクション**: 発掘したアイテムを確認
- **実績システム**: 発掘回数やアイテム収集で実績を解除
- **プロフィール**: ユーザー情報の設定

## 依存パッケージ

- `shared_preferences`: ローカルデータの保存
- `image_picker`: 画像の選択
- `intl`: 日付のフォーマット
- `http`: ネットワークリクエスト（画像取得用）
- `cached_network_image`: ネットワーク画像のキャッシュ

## プロジェクト構造

```
lib/
├── main.dart                 # エントリーポイント
├── models/                   # データモデル
│   ├── comment.dart
│   ├── memory.dart
│   └── game.dart
├── screens/                  # 画面
│   ├── home_screen.dart
│   ├── memory_post_screen.dart
│   ├── create_memory_screen.dart
│   ├── digging_game_screen.dart
│   ├── collection_screen.dart
│   ├── achievements_screen.dart
│   └── profile_screen.dart
├── services/                 # サービス
│   └── storage_service.dart
└── widgets/                  # 再利用可能なウィジェット
    └── navigation_bar.dart
```

## プラットフォーム固有の設定

### Android

`android/app/src/main/AndroidManifest.xml`に以下の権限を追加する必要がある場合があります:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

### iOS

`ios/Runner/Info.plist`に以下の権限を追加する必要がある場合があります:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>写真を選択するために写真ライブラリへのアクセスが必要です</string>
```

## ライセンス

このプロジェクトは元のReactアプリからFlutterに変換されたものです。

