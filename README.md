# newsnap-infra

NewsSnap アプリケーションの AWS インフラを管理する Terraform リポジトリ。

アプリケーションコードは別リポジトリ（`newsnap`）を参照。

## 構成

```
newsnap-infra/
├── infra-spec.md               # インフラ仕様ドキュメント
├── .github/
│   ├── dependabot.yml          # 依存関係の自動更新設定
│   └── workflows/
│       ├── ci.yaml             # PR時: lint / plan / AIレビュー
│       └── deploy.yaml         # push時: lint / plan / apply
├── environment/
│   ├── dev/                    # 開発環境
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── prod/                   # 本番環境
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── modules/
│   ├── vpc/                    # VPC・サブネット・SGなどネットワーク基盤
│   ├── dns/                    # Route53 + ACM証明書
│   ├── waf/                    # WAF (CloudFront用, us-east-1)
│   ├── s3/                     # フロントエンド静的アセット用バケット
│   ├── cloudfront/             # CloudFront + CloudFront Functions (SPAルーティング)
│   ├── ecr/                    # コンテナイメージリポジトリ
│   ├── alb/                    # Application Load Balancer
│   ├── cognito/                # ユーザープール・クライアント
│   ├── rds/                    # PostgreSQL (RDS)
│   ├── rds_scheduler/          # RDS自動停止スケジューラ (dev: 毎週月曜0:00 JST)
│   ├── ecs/                    # ECSクラスタ・サービス・タスク定義
│   ├── ecs_migration/          # DBマイグレーション用ECSタスク
│   ├── bastion/                # 踏み台EC2 (Session Manager経由でアクセス)
│   ├── bastion_scheduler/      # Bastion自動停止スケジューラ (毎日23:00 JST)
│   ├── ssm_runbook/            # SSM Automation: DBユーザー作成Runbook
│   └── iam/                    # CI/CD用IAMポリシー定義 (JSONファイル)
└── iam/
    └── cicd-terraform.json     # Terraform CI/CD実行用IAMポリシー
```

詳細は [`infra-spec.md`](./infra-spec.md) を参照。

## 使い方

適用したい環境のディレクトリに移動し、モジュールインストールなど初期化をする。
```bash
cd environment/<環境名>
terraform init
```

変更差分を確認
```bash
terraform plan
```

変更を反映(CICDにより反映するため、ローカルからは実行不可)
```bash
terraform apply
```