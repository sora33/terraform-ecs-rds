## 概要
AWS ECS(Fargate), RDS, ALB 構成を作成してみた。

## これに関する記事を書いています。
- [Terraform で、AWS ECS(Fargate), ALB, RDS の構成をコード化した。
](https://qiita.com/hiiragiya/items/00a41f2c340b7d176274)
- [AWS ECS(Fargate), ALB, RDSの構成でRailsデプロイしてみた
](https://qiita.com/hiiragiya/items/7df1af73b6f3e34b63ab)


## 実行手順
1. tfstate格納用のS3バケットを作成
2. cd envs/prod
3. backend.tfの「key」を変更
4. 初期化 terraform init
5. 確認  terraform plan
6. 適用  terrafrom apply

## ディレクトリ構成
ディレクトリ構成は**envs**と**modules**に分かれており、それぞれの環境（本番、ステージング、テスト）で独立した設定を行うことができます。
モジュール分割について、あまり細かく分けると**output**と**variable**が増えて煩雑になるので、根幹となる**ecs-alb-rds**は１つのモジュールとしています。
利用頻度の多い**IAM**や**セキュリティグループ**は、再利用しやすいようにモジュール化しました。
```
.
├── envs （それぞれの環境下で、terraform initなどコマンドを叩く）
│   ├── prod （本番環境）
│   │   ├── backend.tf （tfstateの管理場所S3）
│   │   ├── local.tf （ローカル）
│   │   ├── variable.tf （変数）
│   │   ├── main.tf （モジュールを呼び出して、リソース作成するところ）
│   │   ├── provider.tf （リージョン、tagのデフォルト設定）
│   │   ├── terraform.tfvars （環境変数）
│   │   └── version.tf （terraform,awsのバージョン管理）
│   ├── stg （ステージング環境: prodと同じファイル構成）
│   └── test （テスト環境: prodと同じファイル構成）
└── modules （モジュール）
    ├── ecs-alb-rds （env/hoge/main.tfから利用される）
    │   ├── alb.tf （ロードバランサ、リスナー、セキュリティグループ）
    │   ├── ecr.tf （ECR, ライフサイクルポリシー）
    │   ├── ecs.tf （ECSのクラスター、タスク定義、サービス、ターゲットグループ、セキュリティグループ）
    │   ├── network.tf （VPC, Subnet, route table, Nat Gateway）
    │   ├── output.tf （出力 （ターミナルに表示）したい値）
    │   ├── rds.tf （RDS, セキュリティグループ）
    │   ├── route53.tf （Route53, ACM情報を取得）
    │   └── variable.tf （main.tfで利用時に必要な変数）
    ├── iam_role （modules/ecs-alb-rds/hoge.tfから利用される）
    │   ├── main.tf （リソース定義）
    │   ├── output.tf （出力値）
    │   └── variable.tf （引数）
    └── security_group （modules/ecs-alb-rds/hoge.tfから利用される）
        ├── main.tf （リソース定義）
        ├── output.tf （出力値）
        └── variable.tf （引数）
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
