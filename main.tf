provider aws {
  region     = var.aws_region
}

module vpc {
  source = "terraform-aws-modules/vpc/aws"
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
