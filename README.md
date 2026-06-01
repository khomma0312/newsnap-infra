# newsnap-infra

NewsSnap アプリケーションの AWS インフラを管理する Terraform リポジトリ。

アプリケーションコードは別リポジトリ（`newsnap`）を参照。

## 構成

```
newsnap-infra/
├── infra-spec.md    # インフラ仕様ドキュメント
├── main.tf          # モジュール呼び出し
├── variables.tf     # 入力変数
├── outputs.tf       # 出力値
└── modules/
    ├── vpc/
    ├── cognito/
    ├── rds/
    ├── alb/
    ├── ecs/
    └── s3-cloudfront/
```

詳細は [`infra-spec.md`](./infra-spec.md) を参照。

## 使い方

```bash
# 適用したい環境のディレクトリに移動する
cd environment/<環境名>
terraform init
terraform plan
terraform apply
```
