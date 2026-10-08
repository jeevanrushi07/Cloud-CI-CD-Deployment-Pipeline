terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "cloud-cicd-vpc"
  cidr = "10.0.0.0/16"

  azs            = ["ca-central-1a", "ca-central-1b"]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Project     = "Cloud CI/CD Deployment Pipeline"
    Environment = "demo"
  }
}
