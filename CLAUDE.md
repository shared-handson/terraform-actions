# CLAUDE.md

## プロジェクト概要

このプロジェクトは、shared-handson 組織専用の GitHub Actions を使用した Terraform CI/CD パイプライン自動化システムです。AWS OIDC 認証、S3 バックエンド、Discord 通知を統合し、完全に自動化されたインフラストラクチャデプロイメントを提供します。

## 主要機能

### Terraform ワークフロー

- **terraform-plan**: PR での Terraform plan 実行、PR コメントでの結果表示、S3バックエンドチェック、tfvarsファイルチェック
- **terraform-apply**: main ブランチマージ時の Terraform apply 自動実行、no_terraform チェック付き
- **terraform-destroy-plan**: 手動実行での Terraform destroy plan 確認
- **terraform-destroy-exec**: 手動実行での Terraform destroy 実行

### Terraform 実行制御機能

- `no_terraform*`ファイル（大文字小文字問わず、拡張子任意）による実行制御
- terraform ディレクトリ内の `*.tfvars` ファイル存在時のエラーハンドリング
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
- GitHub Secrets からの自動 `gh-secrets.auto.tfvars` ファイル生成
- AWS OIDC 認証による安全な AWS アクセス

## ファイル構成

```
.github/
├── actions/
│   ├── setup/
│   │   └── action.yml             # 共通セットアップ（AWS認証、Terraform初期化、backend.tf動的生成）
│   ├── check-no-terraform/
│   │   └── action.yml             # no_terraformファイルチェック
│   ├── check-tfvars/
│   │   └── action.yml             # terraformディレクトリ内tfvarsファイルチェック
│   └── discord-notify/
│       └── action.yml             # Discord通知（状態別通知、ユーザーメンション）
└── workflows/
    ├── terraform-plan.yml         # PR時のplan実行、事前チェック機能
    ├── terraform-apply.yml        # マージ時のapply実行
    ├── terraform-destroy-plan.yml # 手動destroy plan
    ├── terraform-destroy-exec.yml # 手動destroy実行
    └── README.md                  # 詳細な使用方法ガイド
terraform/
├── main.tf                        # AWS Provider設定（v6.0）、S3テストバケット作成
├── terraform.tfvars.example       # tfvars設定例ファイル
└── terraform.tfvars               # 実際のtfvarsファイル（.gitignore対象）
README.md → .github/workflows/README.md  # シンボリックリンク
CLAUDE.md                          # このファイル
yes_terraform.txt                  # 空のファイル（用途不明）
.gitignore                         # Terraform関連ファイル除外設定
```

## Composite Actions 詳細

### setup/action.yml

AWS 認証から Terraform 初期化までの共通処理を担当する包括的なセットアップアクション：

- **AWS OIDC 認証**: IAM ロールの自動 assume
- **Terraform CLI セットアップ**: 指定バージョン（v1.12.2）のインストール
- **GitHub-Discord マッピング**: ユーザー ID の変換処理
- **tfvars ファイル生成**: TF_VARS から `gh-secrets.auto.tfvars` を自動作成
- **backend.tf 動的生成**: リポジトリ名に基づくS3バックエンド設定ファイル作成
- **Terraform 初期化**: バックエンド設定を含む init 実行

注：フォーマットチェックと変数ファイル検証はコメントアウト済み

### check-no-terraform/action.yml

Terraform 実行の無効化制御：

- プロジェクトルートで `no_terraform*` ファイルの検出（大文字小文字、拡張子問わず）
- 実行制御フラグ（`no-terraform-found`）の出力
- 検出ファイルパス（`no-terraform-file`）の返却

### check-tfvars/action.yml

tfvars ファイル存在チェック：

- terraform ディレクトリ内で `*.tfvars` ファイルの検出（大文字小文字問わず）
- tfvars ファイル発見フラグ（`tfvars-found`）の出力
- 検出ファイルパス（`tfvars-file`）の返却
- tfvars ファイルが存在する場合は plan ワークフローで PR を自動クローズ

### discord-notify/action.yml

Discord 通知システム：

- 成功/失敗/キャンセル状態別の通知（sarisia/actions-status-discord@v1 使用）
- カスタマイズ可能な色設定（成功：青、失敗：赤、キャンセル：黄）
- ユーザーメンション機能（Discord ID 指定）
- Workflow タイトルと説明のカスタマイズ

## 開発時の注意事項

### 重要な制約事項

- **terraform ディレクトリに `*.tfvars` ファイルを直接配置してはいけません**
  - 存在すると plan ワークフローが自動的に PR をクローズします
  - 変数は必ず GitHub Secrets の `TF_VARS` で管理してください

### テスト方法

- 各ワークフローは実際の PR 作成・マージで動作確認
- `no_terraform*` ファイル機能のテスト時は一時的にファイルを作成
- S3 バックエンドチェック機能のテストは S3 バケットアクセス権限を確認

### Lint とタイプチェック

Terraform の品質チェック：
- フォーマットチェック（`terraform fmt -check`）は現在無効化済み
- 構文チェック（`terraform validate`）は各ワークフローの init 時に自動実行

### 依存関係

- **GitHub Actions**: ワークフロー実行環境
- **AWS CLI**: AWS リソースアクセス（OIDC 認証）
- **Terraform**: インフラストラクチャ管理（v1.12.2）
- **Discord Webhook**: 通知システム（sarisia/actions-status-discord@v1）
- **jq**: JSON 処理（ユーザーマッピング）

## 環境変数・Secrets

### 必須の Organization Secrets

- `AWS_IAM_ROLE`: 展開先 AWS IAM ロールの ARN
- `AWS_TF_STATE_BUCKET`: Terraform ステート保存用 S3 バケット名
- `GH_DC_USERMAP`: GitHub-Discord ユーザーマッピング（JSON 形式）
- `DC_WEBHOOK_GHAC`: Discord 通知用 WebhookURL

### オプションの Organization Secrets

- `TF_VARS`: Terraform 変数定義（HCL 形式、`gh-secrets.auto.tfvars` として自動生成）

### ワークフロー環境変数

- `AWS_REGION`: "ap-northeast-1"
- `TF_VERSION`: "1.12.2"

## Terraform インフラストラクチャ

### backend.tf（動的生成）

setup action で動的に生成される S3 バックエンド設定：
- バケット名：`AWS_TF_STATE_BUCKET` から取得
- キー：リポジトリ名に基づく（`{REPO_NAME}/terraform.tfstate`）
- リージョン：`AWS_REGION` から取得
- ロックファイル機能有効（`use_lockfile = true`）

### main.tf

AWS Provider v6.0 を使用したテスト用インフラストラクチャ：
- AWS Provider 設定（ap-northeast-1 リージョン）
- default_tags 設定（Owner: "Github Actions", ManagedBy: "Terraform"）
- random_pet リソースによるユニークなバケット名生成
- 変数 `bucket_name`（デフォルト値："tfaction"）
- S3 バケット作成（`{bucket_name}-prefix-{random_pet}` 形式）
- output でバケット名を出力

## TF_VARS 機能

GitHub Secrets に `TF_VARS` を設定することで、安全に Terraform 変数を渡すことができます：

### 設定例

```hcl
bucket_name       = "production"
```

### 動作

1. GitHub Secrets の `TF_VARS` を `gh-secrets.auto.tfvars` として出力
2. Terraform コマンド実行時に自動的に変数ファイルとして読み込まれる
3. 空の場合は自動的にスキップされる

## 使用方法

### 基本フロー

1. `terraform/` ディレクトリに `.tf` ファイルを配置
2. 必要に応じて GitHub Secrets に `TF_VARS` を設定
3. PR を main ブランチに作成（terraform-plan が自動実行）
4. plan 結果を PR コメントで確認
5. PR をマージ（terraform-apply が自動実行）
6. Discord で結果通知を受信

### エラーパターンと対処法

#### tfvars ファイル存在エラー
terraform ディレクトリに `*.tfvars` ファイルが存在する場合：
- plan ワークフローで PR が自動クローズされる
- 対処法：ファイルを削除し、GitHub Secrets の `TF_VARS` を使用する

#### S3 バックエンドエラー
S3 バケットへのアクセスができない場合：
- plan ワークフローで PR が自動クローズされる
- 対処法：AWS IAM ロールの権限とS3バケットの存在を確認

#### Terraform plan エラー
Terraform コードに問題がある場合：
- plan ワークフローで PR が自動クローズされる
- エラー詳細が PR コメントに表示される

### no_terraform 機能

Terraform 実行を無効化したい場合：

1. プロジェクトルートに `no_terraform*` ファイルを作成
2. plan は実行されるが、apply は完全スキップ
3. PR に警告コメントが表示される

### 手動 destroy

1. GitHub Actions タブ → "Terraform Manual - destroy plan"
2. "Run workflow" → plan 結果を確認
3. "Terraform Manual - destroy exec" → 実際の破棄実行

## ドキュメント

詳細な使用方法は `.github/workflows/README.md` を参照してください。