
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = "~> 1.8"
}

# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs
# https://docs.aws.amazon.com/cli/latest/userguide/cli-authentication-user.html 
provider "aws" {
  region  = var.AWS_REGION
}