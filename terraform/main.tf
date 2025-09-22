# ------------------------------------------------------------------------------
# Terraformの設定
# ------------------------------------------------------------------------------

# この設定ではプロバイダーのバージョンを指定します
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# AWSプロバイダーの設定
# リージョンを指定する必要があります
provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = {
      Owner     = "Github Actions" // 各自の名前に変えること
      ManagedBy = "Terraform"
    }
  }
}

# ------------------------------------------------------------------------------
# リソースの定義
# ------------------------------------------------------------------------------

# 決め打ち文字列を定義するリソース
# tfvarsのテストで使用します。tfvarsを設けない場合はtfactionで固定になります。
variable "bucket_name" {
  type    = string
  default = "tfaction"
}

# ランダムな文字列を生成するためのリソース
# S3バケット名がグローバルで一意である必要があるため、これを使ってユニークな名前を作成します。
resource "random_pet" "bucket_name" {
  length = 2
}

# 決め打ち文字列とランダム文字列を結合
locals {
  merge_s3name = "${var.bucket_name}-prefix-${random_pet.bucket_name.id}"
}

# S3バケットを作成するリソース
resource "aws_s3_bucket" "test_bucket" {
  # random_petリソースを使ってユニークなバケット名を生成します
  # 例: "gentle-cat-terraform-test-bucket"
  bucket = local.merge_s3name
  tags   = { Name = local.merge_s3name }
}

# ------------------------------------------------------------------------------
# 出力 (任意)
# ------------------------------------------------------------------------------

# 作成されたS3バケットの名前を出力します
output "bucket_name" {
  description = "The name of the created S3 bucket."
  value       = aws_s3_bucket.test_bucket.bucket
}
