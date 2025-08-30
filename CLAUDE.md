# CLAUDE.md

## プロジェクト概要

このプロジェクトは、GitHub ActionsでTerraformのCI/CDパイプラインを自動化するためのワークフロー集です。

## 主要機能

### Terraformワークフロー
- **terraform-plan**: PRでのTerraform planの実行とPRコメントでの結果表示
- **terraform-apply**: mainブランチマージ時のTerraform applyの自動実行
- **terraform-destroy-plan**: 手動実行でのTerraform destroy planの確認
- **terraform-destroy-exec**: 手動実行でのTerraform destroyの実行

### Terraform実行制御
- `no_terraform*`ファイル（大文字小文字問わず、拡張子任意）による実行制御
- plan時のPRコメント警告機能
- apply時の完全スキップ機能

### 通知機能
- Discord通知によるワークフロー結果の通知
- PRの自動クローズ機能（失敗時）

## ファイル構成

```
.github/
├── actions/
│   ├── setup/                    # 共通セットアップ処理
│   ├── pr-failure-handler/       # PR失敗時の処理
│   ├── discord-notify/           # Discord通知処理
│   └── check-no-terraform/       # no_terraformファイルチェック
└── workflows/
    ├── terraform-plan.yml        # PR時のplan実行
    ├── terraform-apply.yml       # マージ時のapply実行
    ├── terraform-destroy-plan.yml
    └── terraform-destroy-exec.yml
```

## 開発時の注意事項

### テスト方法
- 各ワークフローは実際のPR作成・マージで動作確認
- `no_terraform`ファイル機能のテスト時は一時的にファイルを作成

### Lintとタイプチェック
現在、特定のlint/typecheckコマンドは設定されていません。

### 依存関係
- GitHub Actions
- AWS CLI（IAM Role経由の認証）
- Terraform
- Discord Webhook

## 環境変数・Secrets

### 必須のOrganization Secrets
- `AWS_IAM_ROLE`: 展開先AWS IAMロールのARN
- `AWS_TF_STATE_BUCKET`: Terraformステート保存用S3バケット名
- `GH_DC_USERMAP`: GitHub-Discordユーザーマッピング（JSON形式）
- `DC_WEBHOOK_GHAC`: Discord通知用WebhookURL

### ワークフロー環境変数
- `AWS_REGION`: "ap-northeast-1"
- `TF_VERSION`: "1.12.2"

## Terraformコード配置

Terraformコード（.tfファイル）は `terraform/` ディレクトリに配置する必要があります。