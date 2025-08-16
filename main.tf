# ------------------------------------------------------------------------------
# Terraformとプロバイダーの設定
# ------------------------------------------------------------------------------

terraform {
  # この設定ではAWSプロバイダーのバージョン3.0以上が必要であることを示します
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# AWSプロバイダーの設定
# リージョンはGitHub Actionsの環境変数から自動的に引き継がれるため、
# ここで指定する必要はありません。
provider "aws" {}

# ------------------------------------------------------------------------------
# リソースの定義
# ------------------------------------------------------------------------------

# ランダムな文字列を生成するためのリソース
# S3バケット名がグローバルで一意である必要があるため、これを使ってユニークな名前を作成します。
resource "random_pet" "bucket_name" {
  length = 2
}

# S3バケットを作成するリソース
resource "aws_s3_bucket" "test_bucket" {
  # random_petリソースを使ってユニークなバケット名を生成します
  # 例: "gentle-cat-terraform-test-bucket"
  bucket = "${random_pet.bucket_name.id}-terraform-test-bucket"

  tags = {
    Name        = "Terraform Test Bucket"
    Environment = "Test"
    ManagedBy   = "Terraform"
  }
}

# ------------------------------------------------------------------------------
# 出力 (任意)
# ------------------------------------------------------------------------------

# 作成されたS3バケットの名前を出力します
output "bucket_name" {
  description = "The name of the created S3 bucket."
  value       = aws_s3_bucket.test_bucket.bucket
}
