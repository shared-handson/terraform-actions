# secrets

備忘録として記載。  
以下は全て Organizaions の共用 secrets として登録している為  
基本的には新規登録などは不要。

- AWS_IAM_ROLE
  - 展開先の AWS の IAM ロールの ARN
  - 例）　`arn:aws:iam::xxxxxxxxxxxx:role/IAM-ROLE`
- AWS_TF_STATE_BUCKET
  - バックエンドとして使う S3 のバケット名
  - 例) `tf-state-xxxxxxxxxxxx`
- GH_DC_USERMAP
  - Github と Discord のユーザー ID のマッピング
  - 例)
    ```
    {
      "githubname1": "012345678901234567",
      "githubname2": "987654321098765432"
    }
    ```
- DC_WEBHOOK_GHAC
  - 通知先の Discord チャンネルの Webhook URL
  - 例) `https://discord.com/api/webhooks/xxxxxxxxxxxxxxxxxxx/xxxxxxxxxxxxxxxxxxx)`
