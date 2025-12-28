terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Optional: Backend configuration for state management
  # Uncomment and configure if using S3 backend
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "microservices/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

