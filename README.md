# ETC Data Processor

ETCデータの処理とバリデーションを行うGoライブラリ

## 概要

このプロジェクトは、ETC（Electronic Toll Collection）の利用明細CSVファイルを解析し、データの処理・バリデーションを行うためのライブラリです。

## 特徴

- ✅ **100%テストカバレッジ**（手書きコード）
- 🔧 **包括的なエラーハンドリング**
- 📊 **詳細なカバレッジレポート**
- 🎨 **色付きテスト結果表示**
- 🚀 **高性能なCSV処理**

## 主要機能

### CSVパーサー
- ETC明細CSVファイルの解析
- ヘッダー付き/なしの両方に対応
- 様々な日付フォーマットサポート
- 車種・料金データの正確な処理

### バリデーション
- CSVデータの完全性チェック
- 必須フィールドの検証
- 重複データの検出
- エラーレポート生成

### サービス層
- gRPCサービスインターフェース
- ファイル処理API
- データ変換機能

## アーキテクチャ

```
src/
├── pkg/
│   ├── handler/     # サービス層とバリデーション
│   └── parser/      # CSVパーサー
├── proto/           # プロトコルバッファ定義
├── cmd/server/      # gRPCサーバー
└── internal/        # 内部パッケージ
```

## テスト戦略

### 関数抽出による徹底テスト
- `ParseVehicleClass`: strconv.Atoiエラーパステスト
- `parseDate`: 日付解析の全エッジケース
- `ValidateRecordsAvailable`: データ存在チェック
- `ProcessRecords`: バリデーションエラー処理

### カバレッジ計測
```bash
./show_coverage.sh
```

### テスト実行
```bash
go test ./tests/...
```

## 使用技術

- **言語**: Go 1.21+
- **プロトコル**: gRPC
- **テスト**: Go標準テストパッケージ
- **カバレッジ**: go tool cover

## 開発者向け

### セットアップ
```bash
git clone <repository>
cd etc_data_processor
go mod download
```

### テスト実行
```bash
# 全テスト実行
go test ./tests/...

# カバレッジ付きテスト
./show_coverage.sh
```

### ビルド
```bash
go build ./src/cmd/server
```

## カバレッジレポート

現在のテストカバレッジ: **100.0%**（手書きコード）

- ✅ 34関数 - 完全テスト済み
- 🔶 0関数 - 部分的カバレッジ
- ⚠️ 0関数 - 未テスト

## ライセンス

MIT License

## 貢献

プルリクエストを歓迎します。大きな変更を行う場合は、まずissueを作成して変更内容について議論してください。