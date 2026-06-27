# infra/envs/production/provider.tf

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
  }

  backend "s3" {
    bucket         = "stellar-save-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "stellar-save-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "stellar-save"
      ManagedBy = "terraform"
      Env       = "production"
    }
  }
}

# Secondary region provider for cross-region read replica and DR resources.
# Defaults to the same value as the primary region when multi-region is disabled,
# so plans remain valid for single-region deploys.
provider "aws" {
  alias  = "secondary"
  region = var.secondary_aws_region

  default_tags {
    tags = {
      Project   = "stellar-save"
      ManagedBy = "terraform"
      Env       = "production"
    }
  }
}
