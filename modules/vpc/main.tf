data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

locals {
  # 利用可能なAZをソートして先頭2つを使用（ソートで順序を固定し、CIDR割り当てをブレなくする）
  azs = slice(sort(data.aws_availability_zones.available.names), 0, 2)

  # キー例: "public-1a", "public-1c"（AZ末尾2文字を使用）
  public_subnets = {
    for i, az in local.azs :
    "public-${substr(az, -2, 2)}" => {
      availability_zone = az
      cidr_block        = "192.168.${i}.0/24"
    }
  }

  private_subnets = {
    for i, az in local.azs :
    "private-${substr(az, -2, 2)}" => {
      availability_zone = az
      cidr_block        = "192.168.${i + 10}.0/24"
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block = "192.168.0.0/16"
  tags       = { Name = "${var.app_name}-vpc" }
}

resource "aws_subnet" "public" {
  for_each          = local.public_subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone
  tags              = { Name = "${var.app_name}-${each.key}" }
}

resource "aws_subnet" "private" {
  for_each          = local.private_subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone
  tags              = { Name = "${var.app_name}-${each.key}" }
}

# ── インターネットゲートウェイ ────────────────────────────────

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.app_name}-igw" }
}

# ── パブリックルートテーブル ──────────────────────────────────

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${var.app_name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# ── NAT Gateway（1AZ構成・コスト最適化）────────────────────────

resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]
  tags       = { Name = "${var.app_name}-nat-eip" }
}

# values() はキーの辞書順で返るため "public-1a" が先頭となり決定的
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = values(aws_subnet.public)[0].id
  tags          = { Name = "${var.app_name}-nat" }
}

# ── プライベートルートテーブル ────────────────────────────────

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = { Name = "${var.app_name}-private-rt" }
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# ── セキュリティグループ ─────────────────────────────────────────────────────
# ALB → ECS → RDS の順で参照し合う連鎖のため、同一モジュール内でまとめて作成する。

resource "aws_security_group" "alb" {
  name   = "${var.app_name}-alb"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs" {
  name   = "${var.app_name}-ecs"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds" {
  name   = "${var.app_name}-rds"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group_rule" "rds_from_ecs" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.ecs.id
  description              = "Allow ECS to connect to RDS"
}

# ── S3 Gateway Endpoint（無料・ECRイメージレイヤーのNATデータ処理費を節約）──

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
  tags              = { Name = "${var.app_name}-s3-endpoint" }
}
