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

  enable_ipv6 = false

  enable_nat_gateway = true
  single_nat_gateway = false

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

resource "aws_security_group" "lab_sg" {
  name = "sebastien_lab_sg"
  vpc_id = module.vpc.vpc_id
  ingress {
    description      = "Restrict SSH access to the bare minimum soon"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "lab_ec2" {
  ami                         = "ami-0a5b5c0ea66ec560d" # Debian 11 @ eu-central-1
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  key_name                    = "admin"
  vpc_security_group_ids = [aws_security_group.lab_sg.id]
}