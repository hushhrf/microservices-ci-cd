# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  count      = var.enable_rds ? 1 : 0
  name       = "${var.cluster_name}-db-subnet-group"
  subnet_ids = local.subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-db-subnet-group"
    }
  )
}

# RDS Parameter Group (Optional - for PostgreSQL tuning)
resource "aws_db_parameter_group" "main" {
  count  = var.enable_rds ? 1 : 0
  name   = "${var.cluster_name}-postgres-params"
  family = "postgres15"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_statement"
    value = "all"
  }

  tags = var.tags
}

# RDS Instance
resource "aws_db_instance" "main" {
  count                  = var.enable_rds ? 1 : 0
  identifier             = "${var.cluster_name}-postgres"
  engine                 = "postgres"
  engine_version         = "15.10"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  storage_encrypted       = false

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  parameter_group_name   = aws_db_parameter_group.main[0].name

  multi_az                = false
  backup_retention_period = 0
  skip_final_snapshot      = true

  enabled_cloudwatch_logs_exports = []
  performance_insights_enabled    = false

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-postgres"
    }
  )
}

