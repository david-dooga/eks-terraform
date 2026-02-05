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


terraform {
  backend "s3" {
    bucket = "apaa-eks-bucket"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    use_lockfile = true
  }
}


module "vpc" {
  source = "./modules/vpc"

  region = var.region
  vpc_cidr = var.vpc_cidr
  availability_zones = var.availability_zones
  eks_cluster_name = var.eks_cluster_name
  private_subnet_cidr = var.private_subnet_cidr
  public_subnet_cidr = var.public_subnet_cidr
}


module "eks" {
  source = "./modules/eks"

  region = var.region
  vpc_id = module.vpc.vpc_id
  subnet_id = module.vpc.private_subnet_ids
  eks_cluster_name =  var.eks_cluster_name
  cluster_version = var.cluster_version
  node_groups = var.node_groups
}
