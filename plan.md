### etc_data_processor

### 連携repo
- https://github.com/yhonda-ohishi/server_repo
- https://github.com/yhonda-ohishi/etc_meisai_scraper
- https://github.com/yhonda-ohishi/db_service

## 要件
- grpc
- buffer
- swagger 自動連係
- go moduleで呼び出される
- src, testsフォルダに分類
- testsはsrcに入れない
- commmit時にsrcにtestが入っていないかprecommit hookで確認するようにする
- protoファイルは直接編集禁止
- auto generated file以外のcoverage 100%
- test first 　

### gRPC サービス定義

```protobuf
service DataProcessorService {
    // CSVファイル処理: CSV解析 → DB保存
    rpc ProcessCSVFile(ProcessCSVFileRequest) returns (ProcessCSVFileResponse);
    
    // CSVデータ処理: CSVテキストデータ → DB保存  
    rpc ProcessCSVData(ProcessCSVDataRequest) returns (ProcessCSVDataResponse);
    
    // データ検証のみ（保存しない）
    rpc ValidateCSVData(ValidateCSVDataRequest) returns (ValidateCSVDataResponse);
    
    // ヘルスチェック
    rpc HealthCheck(HealthCheckRequest) returns (HealthCheckResponse);
}
```

### リクエスト・レスポンス定義

#### ProcessCSVFileRequest
```protobuf
message ProcessCSVFileRequest {
    string csv_file_path = 1;     // CSVファイルパス
    string account_id = 2;        // アカウントID
    bool skip_duplicates = 3;     // 重複データをスキップ
}
```

#### ProcessCSVDataRequest
```protobuf
message ProcessCSVDataRequest {
    string csv_data = 1;          // CSVテキストデータ
    string account_id = 2;        // アカウントID  
    bool skip_duplicates = 3;     // 重複データをスキップ
}
```

#### ProcessCSVFileResponse / ProcessCSVDataResponse
```protobuf
message ProcessCSVFileResponse {
    bool success = 1;
    string message = 2;
    ProcessingStats stats = 3;
    repeated string errors = 4;
}

message ProcessCSVDataResponse {
    bool success = 1;
    string message = 2;
    ProcessingStats stats = 3;
    repeated string errors = 4;
}

message ProcessingStats {
    int32 total_records = 1;      // 総レコード数
    int32 saved_records = 2;      // 保存成功レコード数
    int32 skipped_records = 3;    // スキップしたレコード数
    int32 error_records = 4;      // エラーレコード数
}
```

#### ValidateCSVDataRequest
```protobuf
message ValidateCSVDataRequest {
    string csv_data = 1;          // CSVテキストデータ
    string account_id = 2;        // アカウントID
}

message ValidateCSVDataResponse {
    bool is_valid = 1;
    repeated ValidationError errors = 2;
    int32 duplicate_count = 3;
    int32 total_records = 4;
}

message ValidationError {
    int32 line_number = 1;
    string field = 2;
    string message = 3;
    string record_data = 4;
}
```

## データフロー

### 標準処理フロー
```
1. server_repo → etc_meisai_scraper.DownloadSync()
2. etc_meisai_scraper → CSVファイル生成・保存
3. server_repo → etc_data_processor.ProcessCSVFile()
4. etc_data_processor → CSVファイル読み込み・解析
5. etc_data_processor → db_service.CreateETCMeisai()
6. 処理結果を server_repo にレスポンス
```

### CSVデータ直接処理フロー
```
1. server_repo → etc_meisai_scraper.DownloadSync()
2. etc_meisai_scraper → CSVデータを直接レスポンス
3. server_repo → etc_data_processor.ProcessCSVData()
4. etc_data_processor → CSVデータ解析・バリデーション
5. etc_data_processor → db_service.CreateETCMeisai()
6. 処理結果を server_repo にレスポンス
```

### データ検証フロー
```
1. server_repo → etc_data_processor.ValidateCSVData()
2. etc_data_processor → CSVデータ解析・検証（保存しない）
3. 検証結果を server_repo にレスポンス
```

## 役割分担の明確化

### server_repo の役割
- 全体的なオーケストレーション
- etc_meisai_scraper → etc_data_processor の呼び出し順序制御
- リトライ処理・エラーハンドリング
- API Gateway機能

### etc_meisai_scraper の役割  
- Webスクレイピング
- CSVファイル生成・保存
- CSVデータのレスポンス

### etc_data_processor の役割
- CSVファイル読み込み・解析
- CSVデータ変換・バリデーション
- db_serviceへのデータ保存

### db_service の役割
- データベースCRUD操作
- データ永続化

## 依存サービス

### 必須依存サービス
- **db_service**: データベース操作
  - 使用API: `CreateETCMeisai()`, `GetETCMeisai()`, `ListETCMeisai()`

### 設定パラメータ
```go
type Config struct {
    DBServiceAddr   string // db_serviceのアドレス
    MaxBatchSize    int    // 一度に処理する最大レコード数
    ValidateData    bool   // データバリデーション有効化
}
```

## エラーハンドリング

### エラー分類
1. **ファイルアクセスエラー**: CSVファイル読み込み失敗
2. **データ解析エラー**: CSV形式不正、データ欠損
3. **バリデーションエラー**: データ検証失敗
4. **データベースエラー**: db_serviceからのエラー

### エラーレスポンス
- 各エラーは詳細な情報と共にレスポンスに含める
- 部分的な成功（一部レコードのみ保存成功）も適切に報告

## 非機能要件

### パフォーマンス
- 1万件のETCレコード処理: 2分以内
- CSV解析速度: 1MB/秒以上
- メモリ使用量: 処理中も100MB以下

### 可用性
- ヘルスチェック機能提供
- db_service障害時の適切なエラーレスポンス

## 実装優先度

### Phase 1（必須機能）
1. `ProcessCSVFile` - CSVファイル → DB保存
2. `ProcessCSVData` - CSVデータ → DB保存  
3. 基本的なエラーハンドリング

### Phase 2（拡張機能）
1. `ValidateCSVData` - データ検証機能
2. 重複データ検出・スキップ機能
3. 詳細なバリデーション

### Phase 3（最適化）
1. パフォーマンス最適化
2. バッチ処理最適化
3. 詳細なログ出力# ETC Data Processor Service 仕様書

## 概要

CSVデータの解析・変換・データベース保存に特化したマイクロサービス。server_repoから呼び出されるCSV処理専用サービス。

## サービス概要

- **サービス名**: etc_data_processor
- **言語**: Go 1.21+
- **通信プロトコル**: gRPC
- **役割**: CSV解析とデータベース保存
- **ポート管理**: server_repo が担当

## アーキテクチャ

```
[server_repo] → [etc_meisai_scraper] → [etc_data_processor] → [db_service] → MySQL Database
                         ↓                       ↑
                    CSVファイル生成        CSVファイル処理
```

## 主要機能

### 1. CSV解析・変換
- ETCのCSVファイルを構造化データに変換
- データ型変換（文字列→日付、数値等）
- フィールドマッピング

### 2. データベース保存
- db_serviceへのgRPC呼び出し
- データ保存結果の集約・レポート

### 3. データバリデーション
- 必須項目チェック
- データ形式検証
- 重複データ検出

## API仕様

### gRPC サービス定義

```protobuf
service DataProcessorService {
    // 同期処理
    rpc ProcessETCDataSync(ProcessETCDataRequest) returns (ProcessETCDataResponse);
    
    // 非同期処理
    rpc ProcessETCDataAsync(ProcessETCDataRequest) returns (ProcessETCDataAsyncResponse);
    
    // ジョブステータス確認
    rpc
}
```