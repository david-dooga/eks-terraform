terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.30.0"
    }
  }
}


provider "aws" {
  # Configuration options
  region = "us-east-1"
}


resource "aws_s3_bucket" "terraform_state" {
  bucket = "apaa-eks-bucket"
  lifecycle {
    prevent_destroy = true # Prevents accidental 'terraform destroy' of the bucket
 }
}


resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}



terraform {
  backend "s3" {
    bucket = "apaa-eks-bucket"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    use_lockfile = true
  }
}
