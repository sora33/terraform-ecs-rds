## 概要
AWS ECS(Fargate), RDS, ALB 構成を作成してみた。

## 実行手順
1. tfstate格納用のS3バケットを作成
2. cd envs/prod
3. backend.tfの「key」を変更
4. 初期化 terraform init
5. 確認  terraform plan
6. 適用  terrafrom apply

## ディレクトリ構成
```
.
├── envs（terraform initなどをするところ）
│   ├── prod
│   │   ├── backend.tf（tfstateの管理場所S3）
│   │   ├── local.tf（ローカル）
│   │   ├── variable.tf（変数）
│   │   ├── main.tf（モジュールを呼び出す）
│   │   ├── provider.tf（リージョン、tagのデフォルト）
│   │   ├── terraform.tfvars（環境変数）
│   │   └── version.tf（terraform,awsのバージョン管理）
│   ├── stg
│   └── test
└── modules（モジュール）
    ├── ecs-alb-rds
    │   ├── alb.tf
    │   ├── ecr.tf
    │   ├── ecs.tf
    │   ├── network.tf
    │   ├── output.tf
    │   ├── rds.tf
    │   ├── route53.tf
    │   └── variable.tf
    ├── iam_role
    │   ├── main.tf
    │   ├── output.tf
    │   └── variable.tf
    └── security_group
        ├── main.tf
        ├── output.tf
        └── variable.tf
```
## デプロイ時の手順
1. 書式を標準化 terraform fmt -recursive
2. 構文や属性の妥当性を検証 terraform validate
3. 適用 terrafrom apply
4. プッシュ git push

## tfstate用のS3を作成
- クラウドで保存するのがセオリー。AWSであればS3が良い。
- バージョニング、暗号化、ブロックパブリックアクセスを設定していればなお良いです。
### 作成
```
aws s3api create-bucket --bucket tfstate-hc-ecs --create-bucket-configuration LocationConstraint=ap-northeast-1
```
### バージョニング
```
aws s3api put-bucket-versioning --bucket tfstate-hc-ecs --versioning-configuration Status=Enabled
```
### 暗号化
```
aws s3api put-bucket-encryption --bucket tfstate-hc-ecs --server-side-encryption-configuration '{
  "Rules": [
    {
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }
  ]
}'
```
### ブロックパブリックアクセス
```
aws s3api put-public-access-block --bucket tfstate-hc-ecs --public-access-block-configuration '{
  "BlockPublicAcls": true,
  "IgnorePublicAcls": true,
  "BlockPublicPolicy": true,
  "RestrictPublicBuckets": true,
}'
```

## ドメインについて（Terraformの責務外）
1. お名前.comなどで取得
2. Route53でホストゾーンを作成
3. お名前.comなどでNSを編集
4. ADM（SSL化）に登録

## RDS作成後はパスワードを変更する
- aws rds modify-db-instance --db-instance-identifier 'example' --master-user-password 'NewMasterPassword!'

## 参考
- 野村 友規「実践Terraform　AWSにおけるシステム設計とベストプラクティス」
- https://github.com/rhythmictech/terraform-aws-alb-ecs-task/blob/v1.10.0/examples/fargate/main.tf
- https://blog.linkode.co.jp/entry/2020/10/15/090000
