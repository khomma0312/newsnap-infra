# NewsSnap インフラ仕様ドキュメント

## 概要

NewsSnap アプリケーションを支える AWS インフラを Terraform で管理するリポジトリ。  
フロントエンド（静的サイト）・バックエンド（コンテナ）・データベース・認証の各リソースをモジュール分割して定義する。

アプリケーション仕様は別リポジトリ（newsnap）の `app-spec.md` を参照。

---

## AWSアーキテクチャ

```
ユーザー
  │
  ├─[HTTPS]─► CloudFront（WAF）─► S3（フロントエンド静的ファイル）
  │                │
  │                └─[HTTPS + X-Custom-Header]─► ALB ─► ECS Fargate（バックエンド Hono）
  │                                                          │
  │                                                          ├─► RDS PostgreSQL（記事・タグ）
  │                                                          ├─► AWS Bedrock（Claude 要約生成）
  │                                                          └─► NewsAPI（外部 API）
  │
認証フロー:
  ユーザー ──► Cognito Hosted UI ──► /callback（フロントエンド）
                                         └─► バックエンド /auth/token（トークン交換）
```

ALB はデフォルトで 403 を返し、CloudFront が付与する `X-Custom-Header` が一致するリクエストのみ
ECS へフォワードする（直接アクセス防止）。

---

## 使用AWSサービス

| サービス | 用途 |
|---|---|
| S3 | フロントエンド静的ファイルのホスティング |
| CloudFront | S3 への CDN・HTTPS 終端・WAF 統合 |
| WAF | CloudFront へのマネージドルール適用（us-east-1） |
| ALB | バックエンドへの HTTPS ルーティング（CloudFront 経由のみ許可） |
| ECS Fargate | バックエンドコンテナの実行（プライベートサブネット） |
| ECR | バックエンド Docker イメージのレジストリ |
| RDS（PostgreSQL 16）| 記事・タグ・リレーションの永続化 |
| Amazon Cognito | ユーザー認証（Hosted UI + JWT） |
| AWS Bedrock | Claude による記事要約生成 |
| Secrets Manager | DB パスワードの管理 |
| SSM Parameter Store | NewsAPI キーの管理 |
| Route53 | DNS レコード管理 |
| ACM | HTTPS 証明書（CloudFront 用: us-east-1、ALB 用: ap-northeast-1） |
| VPC | ネットワーク分離・NAT Gateway・SG 管理 |

---

## Terraform モジュール構成

```
newsnap-infra/
├── modules/
│   ├── vpc/         # VPC・サブネット・NAT GW・S3 GW エンドポイント・全 SG
│   ├── dns/         # Route53 ゾーン参照・ACM 証明書（CF 用・ALB 用）・DNS 検証レコード
│   ├── waf/         # WAFv2 Web ACL（CLOUDFRONT スコープ・us-east-1）
│   ├── s3/          # フロントエンド S3 バケット
│   ├── cloudfront/  # CloudFront ディストリビューション・OAC・Route53 A レコード
│   ├── alb/         # ALB・HTTPS リスナー・ターゲットグループ・Route53 A レコード
│   ├── cognito/     # User Pool・App Client・Hosted UI ドメイン
│   ├── ecr/         # ECR リポジトリ（イメージ管理は CI/CD 側）
│   ├── ecs/         # ECS クラスター・サービス・IAM ロール・SSM パラメータ
│   └── rds/         # RDS インスタンス・Secrets Manager（DB パスワード）
└── environment/
    └── dev/         # dev 環境エントリポイント
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

### 各モジュールの詳細

#### `vpc`
- CIDR: `192.168.0.0/16`
- パブリックサブネット × 2（ALB・NAT GW 用）
- プライベートサブネット × 2（ECS・RDS 用）
- NAT Gateway（1AZ 構成・コスト最適化）
- S3 Gateway Endpoint（NAT データ処理費の節約）
- セキュリティグループを一括管理（ALB SG / ECS SG / RDS SG の連鎖を同一モジュールで定義）

#### `dns`
- 既存 Route53 ホストゾーンを `data` で参照
- CloudFront 用 ACM 証明書（us-east-1・ワイルドカード SAN 付き）
- ALB 用 ACM 証明書（ap-northeast-1）
- DNS 検証レコードを自動作成
- `zone_domain` を指定することで、サブドメイン環境でも親ゾーンを参照可能

#### `waf`
- スコープ: `CLOUDFRONT`（us-east-1 プロバイダ経由）
- AmazonIpReputationList（Block）
- AWSManagedRulesCommonRuleSet（Count：誤検知監視中）
- AWSManagedRulesKnownBadInputsRuleSet（Block）

#### `s3`
- パブリックアクセス完全ブロック
- CloudFront OAC 経由のアクセスのみ許可（バケットポリシーは cloudfront モジュール側で設定）

#### `cloudfront`
- OAC（Origin Access Control）経由で S3 に接続
- ALB をバックエンドオリジンとして追加（`/api/*` 等は ALB へフォワード）
- CloudFront → ALB 間で `X-Custom-Header` による認証
- WAF Web ACL を紐付け
- Route53 A レコード（エイリアス）を内部で作成

#### `alb`
- インターネット向け ALB（パブリックサブネット）
- HTTPS リスナー（443）のみ・TLS 1.3 ポリシー
- デフォルトアクション: 403 Fixed Response
- `X-Custom-Header` 一致時のみ ECS ターゲットグループへフォワード
- Route53 A レコード（`api.<domain>`）を内部で作成

#### `cognito`
- User Pool（メール認証）
- Hosted UI ドメイン
- App Client（Authorization Code フロー、シークレットあり）

#### `ecr`
- イメージタグ: IMMUTABLE
- スキャン: push 時自動実行
- ライフサイクルポリシー: 未タグ → 1日で削除、タグ付き → 最大 30 件保持

#### `ecs`
- クラスター: Fargate（プライベートサブネット・パブリック IP なし）
- タスク定義は CI/CD が登録、Terraform は `data` で参照
- Secrets Manager: `/{app_name}/db/password`（DB 接続情報）
- SSM Parameter Store: `/{app_name}/news_api_key`（初回 PLACEHOLDER、手動更新）
- IAM タスクロール: Bedrock `InvokeModel` / `InvokeModelWithResponseStream`

#### `rds`
- エンジン: PostgreSQL 16
- インスタンス: `db.t4g.micro`、シングル AZ
- プライベートサブネット配置、ECS SG からの 5432 のみ許可
- 初期パスワードを `random_password` で生成し Secrets Manager に保存
- `ignore_changes` により手動ローテーション後も Terraform が上書きしない

---

## 環境構成

| 環境 | ディレクトリ | ドメイン |
|---|---|---|
| dev | `environment/dev/` | `dev.kh-webdev-nibble.net` |

各環境は `environment/<env>/main.tf` で `locals` に `app_name`・`domain` 等を定義し、
`../../modules/` 以下を呼び出す。Terraform 変数（`variables.tf`）は最小限とし、
機密値は Secrets Manager / SSM で管理する。

---

## シークレット管理

| 値 | 管理場所 | 設定方法 |
|---|---|---|
| DB パスワード | Secrets Manager `/{app_name}/db/password` | 初回は Terraform が自動生成。手動ローテーション可 |
| NewsAPI キー | SSM Parameter Store `/{app_name}/news_api_key` | Terraform が PLACEHOLDER で作成後、手動で更新 |

---

## デプロイ手順

### 初回セットアップ

```bash
cd environment/dev

# S3 バックエンドを使う場合は main.tf の backend ブロックをアンコメント
# バケット名: newsnap-prod-tfstate-113244625788-ap-northeast-1-an

terraform init
terraform plan
terraform apply
```

### apply 後の手動作業

```bash
# NewsAPI キーを SSM に設定
aws ssm put-parameter \
  --name "/newsnap-dev/news_api_key" \
  --value "<YOUR_NEWS_API_KEY>" \
  --type SecureString \
  --overwrite

# アプリ用 DB ユーザーの認証情報を Secrets Manager に設定
# （事前に PostgreSQL でユーザーを作成しておく）
aws secretsmanager put-secret-value \
  --secret-id "/newsnap-dev/db/app_credentials" \
  --secret-string '{"username":"<APP_DB_USER>","password":"<APP_DB_PASSWORD>"}'
```

DB マスターパスワードは Terraform apply 時に自動生成されて Secrets Manager に保存されるため、
追加の手動作業は不要。アプリは `/{app_name}/db/password` を参照する。

アプリ用 DB ユーザー（`/{app_name}/db/app_credentials`）は Terraform が箱のみ作成する。
apply 後に上記コマンドで実際の認証情報を設定すること。
ユーザー自体の作成は Drizzle マイグレーションスクリプトで行う。

### バックエンドのデプロイ（CI/CD）

```bash
# ECR へ push
aws ecr get-login-password --region ap-northeast-1 \
  | docker login --username AWS --password-stdin <ECR_URI>
docker build -t newsnap-backend .
docker tag newsnap-backend:latest <ECR_URI>:latest
docker push <ECR_URI>:latest

# ECS タスク定義を登録してサービスを更新
aws ecs register-task-definition --cli-input-json file://task-def.json
aws ecs update-service \
  --cluster newsnap-dev-cluster \
  --service newsnap-dev-backend \
  --force-new-deployment
```

### フロントエンドのデプロイ

```bash
# S3 に sync
npm run build
aws s3 sync out/ s3://<BUCKET_NAME> --delete

# CloudFront キャッシュを無効化
aws cloudfront create-invalidation --distribution-id <DIST_ID> --paths "/*"
```

---

## 出力値

| 出力名 | 説明 |
|---|---|
| `cloudfront_domain` | フロントエンドの CloudFront ドメイン名 |
| `alb_dns` | バックエンド ALB の DNS 名 |
| `cognito_user_pool_id` | Cognito User Pool ID |
| `cognito_client_id` | Cognito App Client ID |
| `ecr_repository_url` | ECR リポジトリ URL（CI/CD でのイメージ push 先） |
