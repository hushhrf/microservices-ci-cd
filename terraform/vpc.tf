# Hardcoded VPC and Subnets (AWS Academy Survival Mode)
# "Keep it simple, safe, and budget-friendly"

locals {
  vpc_id = "vpc-0c1087c6fc9e749d8"

  subnet_ids = [
    "subnet-00751da57efb90516", # us-east-1a
    "subnet-0a7292eaf10ea0639", # us-east-1b
    "subnet-04b9db96166364b09", # us-east-1c
    "subnet-06b7f457fbd13607a", # us-east-1d
    "subnet-056a7ad9e9da9339c"  # us-east-1f
    # REMOVED us-east-1e (subnet-06da38fb7553a0351) to prevent EKS error
  ]
}
