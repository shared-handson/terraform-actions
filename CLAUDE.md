# CLAUDE.md

## プロジェクト概要

このプロジェクトは、shared-handson 組織専用の GitHub Actions を使用した Terraform CI/CD パイプライン自動化システムです。AWS OIDC 認証、S3 バックエンド、Discord 通知を統合し、完全に自動化されたインフラストラクチャデプロイメントを提供します。

## 主要機能

### Terraform ワークフロー

- **terraform-plan**: PR での Terraform plan 実行、PR コメントでの結果表示、バックエンドチェック
- **terraform-apply**: main ブランチマージ時の Terraform apply 自動実行、no_terraform チェック付き
- **terraform-destroy-plan**: 手動実行での Terraform destroy plan 確認
- **terraform-destroy-exec**: 手動実行での Terraform destroy 実行

### Terraform 実行制御機能

- `no_terraform*`ファイル（大文字小文字問わず、拡張子任意）による実行制御
- plan 時の PR コメント警告機能
- apply 時の完全スキップ機能
- S3 バックエンドの自動チェックと設定

### 統合通知システム

- Discord 通知によるワークフロー結果の通知（成功/失敗/キャンセル対応）
- PR の自動クローズ機能（失敗時、10秒待機後）
- GitHub-Discord ユーザーマッピングによる個人メンション
- カスタマイズ可能な通知色設定

### セキュアな変数管理

- TF_VARS による安全な Terraform 変数の受け渡し
- GitHub Secrets からの自動 tfvars ファイル生成
- AWS OIDC 認証による安全な AWS アクセス

## ファイル構成

```
.github/
├── actions/
│   ├── setup/
│   │   └── action.yml             # 共通セットアップ（AWS認証、Terraform初期化、フォーマットチェック）
│   ├── check-no-terraform/
│   │   └── action.yml             # no_terraformファイルチェック
│   ├── pr-failure-handler/
│   │   └── action.yml             # PR失敗時の処理（コメント投稿、自動クローズ）
│   └── discord-notify/
│       └── action.yml             # Discord通知（状態別通知、ユーザーメンション）
└── workflows/
    ├── terraform-plan.yml         # PR時のplan実行、バックエンドチェック
    ├── terraform-apply.yml        # マージ時のapply実行
    ├── terraform-destroy-plan.yml # 手動destroy plan
    ├── terraform-destroy-exec.yml # 手動destroy実行
    └── README.md                  # 詳細な使用方法ガイド
terraform/
├── backend.tf                     # S3バックエンド設定
└── main.tf                        # AWS Provider設定、S3テストバケット作成
README.md                          # プロジェクトドキュメント
CLAUDE.md                          # このファイル
```

## Composite Actions 詳細

### setup/action.yml

AWS 認証から Terraform 初期化までの共通処理を担当する包括的なセットアップアクション：

- **AWS OIDC 認証**: IAM ロールの自動 assume
- **Terraform CLI セットアップ**: 指定バージョンのインストール
- **GitHub-Discord マッピング**: ユーザー ID の変換処理
- **tfvars ファイル生成**: TF_VARS からの自動ファイル作成
- **Terraform 初期化**: バックエンド設定を含む init 実行
- **フォーマットチェック**: terraform fmt -check の実行
- **変数ファイル検証**: tfvars の構文チェック

### check-no-terraform/action.yml

Terraform 実行の無効化制御：

- `no_terraform*`ファイルの検出（大文字小文字、拡張子問わず）
- 実行制御フラグの出力
- 検出ファイルパスの返却

### pr-failure-handler/action.yml

PR 失敗時の自動処理：

- 詳細なエラーメッセージの PR コメント投稿
- 修正手順の自動提示
- 10秒待機後の PR 自動クローズ
- 失敗理由の構造化表示

### discord-notify/action.yml

Discord 通知システム：

- 成功/失敗/キャンセル状態別の通知
- カスタマイズ可能な色設定（成功：青、失敗：赤、キャンセル：黄）
- ユーザーメンション機能
- Workflow タイトルと説明のカスタマイズ

## 開発時の注意事項

### テスト方法

- 各ワークフローは実際の PR 作成・マージで動作確認
- `no_terraform`ファイル機能のテスト時は一時的にファイルを作成
- バックエンドチェック機能のテストは S3 バケットアクセス権限を確認

### Lint とタイプチェック

Terraform のフォーマットチェックは setup アクションで自動実行されます：
- `terraform fmt -check`：コードフォーマットの検証
- `terraform validate`：構文と設定の検証

### 依存関係

- **GitHub Actions**: ワークフロー実行環境
- **AWS CLI**: AWS リソースアクセス（OIDC 認証）
- **Terraform**: インフラストラクチャ管理（v1.12.2）
- **Discord Webhook**: 通知システム
- **jq**: JSON 処理（ユーザーマッピング）

## 環境変数・Secrets

### 必須の Organization Secrets

- `AWS_IAM_ROLE`: 展開先 AWS IAM ロールの ARN
- `AWS_TF_STATE_BUCKET`: Terraform ステート保存用 S3 バケット名
- `GH_DC_USERMAP`: GitHub-Discord ユーザーマッピング（JSON 形式）
- `DC_WEBHOOK_GHAC`: Discord 通知用 WebhookURL

### オプションの Organization Secrets

- `TF_VARS`: Terraform 変数定義（HCL 形式、tfvars として自動生成）

### ワークフロー環境変数

- `AWS_REGION`: "ap-northeast-1"
- `TF_VERSION`: "1.12.2"

## Terraform インフラストラクチャ

### backend.tf

S3 バックエンド設定（空ブロック形式）：
- バケット名、キー、リージョンは GitHub Actions から動的設定
- ロックファイル機能有効

### main.tf

テスト用 S3 バケット作成：
- AWS Provider v3.0 使用
- random_pet リソースによるユニークなバケット名生成
- 適切なタグ付け（Name、Environment、ManagedBy）

## TF_VARS 機能

GitHub Secrets に `TF_VARS` を設定することで、安全に Terraform 変数を渡すことができます：

### 設定例

```hcl
environment       = "production"
instance_type     = "t3.medium"
enable_monitoring = true
db_password       = "secure-password"
```

### 動作

1. GitHub Secrets の `TF_VARS` を `from-gh-secrets.tfvars` として出力
2. Terraform コマンド実行時に `-var-file=from-gh-secrets.tfvars` を自動付与
3. 変数ファイルの構文チェックを実行

## 使用方法

### 基本フロー

1. `terraform/` ディレクトリに `.tf` ファイルを配置
2. PR を main ブランチに作成（terraform-plan が自動実行）
3. plan 結果を PR コメントで確認
4. PR をマージ（terraform-apply が自動実行）
5. Discord で結果通知を受信

### no_terraform 機能

Terraform 実行を無効化したい場合：

1. プロジェクトルートに `no_terraform*` ファイルを作成
2. plan は実行されるが、apply は完全スキップ
3. PR に警告コメントが表示

### 手動 destroy

1. GitHub Actions タブ → "Terraform Manual - destroy plan"
2. "Run workflow" → plan 結果を確認
3. "Terraform Manual - destroy exec" → 実際の破棄実行

## ドキュメント

詳細な使用方法は `.github/workflows/README.md` を参照してください。