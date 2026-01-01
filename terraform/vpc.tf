# Hardcoded VPC and Subnets (AWS Academy Workaround)
# Bypassing DescribeVpcs permission error by using known IDs

locals {
  vpc_id = "vpc-0c1087c6fc9e749d8"
  subnet_ids = [
    "subnet-0a7292eaf10ea0639",
    "subnet-056a7ad9e9da9339c",
    "subnet-06b7f457fbd13607a",
    "subnet-04b9db96166364b09",
    "subnet-00751da57efb90516"
  ]
}

# Commented out dynamic data sources that trigger permissions errors
/*
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
*/
