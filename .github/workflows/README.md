# shared-handson 専用 Terraform All-in-One Actions

## 概要

- shared-handson の AWS アカウントに対して Terraform で IaC する為の Github Actions のテンプレート
- Discord の通知機能がついてる
- パブリックリポジトリでもプライベートリポジトリでも、shared-handsonのGithub Organizationsに所属していればOK
- 原則の考え方として、利用者はインフラ部分を意識しなくてもよい作りになっている。
  - AWS への認証
  - バックエンド(tfstate を保存する先の S3)


# 使い方

## 適用方法

以下のフォルダやファイルを使いたいリポジトリの直下に丸ごとコピーすれば OK。

- .github/actions フォルダ
- .github/workflows フォルダ
- .gitignore ファイル(既存のファイルがある場合は上書きコピーせずに追記すること)

## Terraform コードの配置場所

Terraform のコード（.tf ファイル）は `terraform` フォルダに配置する必要がある。  
**terraform フォルダが無かったら plan 時にエラーになる**  

```
プロジェクトルート/
├── .gitignore             ←コピーor追記するファイル
├── .github/
│   ├── actions/           ←コピーするフォルダ
│   └── workflows/         ←コピーするフォルダ
├── terraform/             ←自分で作ってこの中にコードを配置する
│   ├── main.tf
│   ├── variables.tf
│   └── その他の.tfファイル
│
└── 他のフォルダ
    └── 他のファイル
```

## AWS への認証および、バックエンド(tfstate を保存する先の S3)

Github Actions側で自動制御するため、**Terraformのコード内にはそれに関連する記述は入れないこと**  
例えば、以下のようなコードを入れると予期せぬ挙動をする恐れが高い。  
```hcl
provider "aws" {
  access_key = "AKIAIOSFODNN7EXAMPLE"
  secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
  assume_role {
    role_arn = "arn:aws:iam::<自分のAWSアカウントID>:role/<スイッチロール先のIAMロール名>"
}
```

```hcl
terraform {
  backend "s3" {
    bucket = "example-s3"
    region = "ap-north-east-1"
  }
}
```

勘違いしやすいポイントではあるが、**リソースを展開する先のリージョンの設定は入れること**

```hcl
provider "aws" {
  region = "ap-northeast-1"
}
```


## tfvars（変数ファイル）の利用方法

tfvars は GitHub Secrets から渡す設計となっている。  
**terraform ディレクトリに\*.tfvars が存在すると plan 時にエラーになる**  
リポジトリの Secrets に `TF_VARS` を設定すると、自動的に利用されるようになっている。  
使い方は以下。

- tfvars の中身をそのまま Github Secrets に張り付ける
- Github Secrets 名は必ず`TF_VARS`にすること
- `TF_VARS` が空の場合は自動的にスキップされる
- 設定した変数は Terraform の validation チェックが実行される

例）

```hcl
# TF_VARS の内容例
environment   = "prod"
instance_type = "t3.micro"
db_password   = "your-secure-password"
```

## terraform-plan

main ブランチへのプルリクで自動的に起動される。  
成功したら terraform plan の結果がプルリクのコメントで出力されるので待つ。  
失敗したら失敗理由がプルリクのコメントで出力されて、自動的にプルリクがクローズする。

## terraform-apply

プルリクをマージしたら自動的に起動される。  
terraform-plan が終わってから実行すること。じゃないと失敗する。  
終わったら Discord チャンネルに通知される。

## terraform-destroy-plan

Github Actions を手動実行で破棄内容を確認する。  
終わったら Discord チャンネルに通知される。  
結果は Workflow を直接見る。

1. Github のリポジトリページ
2. 画面内の Actions タブ
3. 左メニューから 「Terraform Manual - destroy plan」
4. 「Run workflow」のドロップダウンメニュー
5. 「Branch: main」
6. 「Run workflow」の緑ボタンで実行

## terraform-destroy-exec

Github Actions を手動実行で破棄を実行する。  
終わったら Discord チャンネルに通知される。  
結果は Workflow を直接見る。

1. Github のリポジトリページ
2. 画面内の Actions タブ
3. 左メニューから 「Terraform Manual - destroy exec」
4. 「Run workflow」のドロップダウンメニュー
5. 「Branch: main」
6. 「Run workflow」の緑ボタンで実行

# TIPS

## Terraform 実行の無効化

プロジェクトルートに `no_terraform` で始まるファイル名のファイル（大文字小文字問わず、拡張子任意）を配置すると、Terraform の実行を無効化できます。

例:

- `no_terraform`
- `NO_TERRAFORM`
- `No_Terraform.txt`
- `no_terraform.md`

この機能により：

- **terraform-plan**: plan は通常通り実行されますが、PR コメントに「apply しない」旨の警告が表示されます
- **terraform-apply**: apply が完全にスキップされ、Discord 通知も送信されません

Terraform を再度有効にするには、該当ファイルを削除してください。

## 認証の仕組み

shared-handson の Organizations 共用の Secrets にパラメータを埋め込んでいる。  
Organizations 内のリポジトリであれば、どこでも参照して認証できる仕組み。

### メンテが必要な Secrets

以下は Organizaions の共用 secrets として登録しているが変動値の為、メンテが必要。

- GH_DC_USERMAP
  - Github と Discord のユーザー ID のマッピング
  - メンバーが増えたらメンテナンスする
  - Discord のユーザー ID は開発者モードを ON にしてユーザー右クリック
  - 例)
    ```
    {
      "githubname1": "012345678901234567",
      "githubname2": "9876543210987654321"
    }
    ```

### メンテが不要な Secrets

以下は全て Organizaions の共用 secrets として登録していて固定値の為、基本的には新規登録などは不要。

- AWS_IAM_ROLE
  - 展開先の AWS の IAM ロールの ARN
  - 例）　`arn:aws:iam::xxxxxxxxxxxx:role/IAM-ROLE`
- AWS_TF_STATE_BUCKET
  - バックエンドとして使う S3 のバケット名
  - 例) `tf-state-xxxxxxxxxxxx`
- DC_WEBHOOK_GHAC
  - 通知先の Discord チャンネルの Webhook URL
  - 例) `https://discord.com/api/webhooks/xxxxxxxxxxxxxxxxxxx/xxxxxxxxxxxxxxxxxxx`

### オプションの Secrets

以下は必要に応じて設定する optional な secrets。

- TF_VARS
  - Terraform の変数ファイル（tfvars）の内容
  - HCL 形式で変数を記述する
  - 設定されていない場合は自動的にスキップされる
  - 例）
    ```hcl
    environment       = "production"
    instance_type     = "t3.medium"
    enable_monitoring = true
    ```
