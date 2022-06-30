provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"

  name = var.vpc_name

  # The CIDR block for the VPC.
  cidr = "10.0.0.0/16"

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_ipv6 = true

  enable_nat_gateway = false
  single_nat_gateway = true

  # Additional tags for the public subnets
  public_subnet_tags = {
    Name = "pov_public"
  }

  # A map of tags to add to all resources
  tags = {
    usecase     = "pov"
    environment = "dev"
    owner       = "infra team"
  }

  # Additional tags for the VPC
  vpc_tags = {
    Name = var.vpc_name
  }
}

resource "aws_key_pair" "admin" {
  key_name   = "admin"
  public_key = var.ssh_pub_key
}

resource "aws_instance" "lab_ec2" {
  ami                         = "ami-065deacbcaac64cf2" # Ubuntu 22.04 LTS @ eu-central-1
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc.private_subnets[0]
  private_ip                  = var.ec2_private_ip
  associate_public_ip_address = true
  key_name                    = "admin"
}