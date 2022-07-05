provider "aws" {
  region = var.aws_region
}

# VPC which is attached to our transit gateway
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"

  name = var.vpc_name

  # The CIDR block for the VPC.
  cidr = "10.0.0.0/16"

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_ipv6                  = true
  public_subnet_ipv6_prefixes  = [0, 1, 2]
  private_subnet_ipv6_prefixes = [3, 4, 5]

  enable_nat_gateway = true
  single_nat_gateway = false
  enable_vpn_gateway = true

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

# Transit Gateway which will be attached to HCP
module "tgw" {
  source = "terraform-aws-modules/transit-gateway/aws"
  count = var.transit_gateway ? 1 : 0

  name        = var.transit_gw_name
  description = "Transit Gateway as an entry point to HCP services"

  transit_gateway_cidr_blocks = ["10.99.0.0/24"]

  # When "true" there is no need for RAM resources if using multiple AWS accounts
  # Breaks HCP accepter resource so shouldn't be set
  # enable_auto_accept_shared_attachments = true

  # When "true", allows service discovery through IGMP
  enable_mutlicast_support = false

  vpc_attachments = {
    vpc = {
      vpc_id       = module.vpc.vpc_id
      subnet_ids   = module.vpc.public_subnets
      dns_support  = true
      ipv6_support = true
    },
  }

  tags = {
    usecase     = "pov"
    environment = "dev"
    owner       = "infra team"
  }
}

# Route to our Transit Gateway for HCP CIDR
resource "aws_route" "to_hcp" {
  route_table_id         = module.vpc.public_route_table_ids[0]
  destination_cidr_block = "172.25.16.0/20"
  transit_gateway_id     = module.tgw[0].ec2_transit_gateway_id
}

# Remote Customer Gateway details for VPN Connectivity
resource "aws_customer_gateway" "cgw" {
  count = var.transit_gateway ? 1 : 0
  bgp_asn    = var.cgw_bgp_asn
  ip_address = var.cgw_ip_address
  type       = "ipsec.1"

  tags = {
    Name = "cgw"
  }
}

# VPN Gateway
module "vpn-gateway" {
  source  = "terraform-aws-modules/vpn-gateway/aws"
  version = "2.12.1"
  count = var.transit_gateway ? 1 : 0

  create_vpn_gateway_attachment = false
  connect_to_transit_gateway    = true

  vpc_id              = module.vpc.vpc_id
  transit_gateway_id  = module.tgw.ec2_transit_gateway_id
  customer_gateway_id = aws_customer_gateway.cgw[0].id

  # tunnel inside cidr & preshared keys (optional)
  tunnel1_inside_cidr   = var.custom_tunnel1_inside_cidr
  tunnel2_inside_cidr   = var.custom_tunnel2_inside_cidr
  tunnel1_preshared_key = var.custom_tunnel1_preshared_key
  tunnel2_preshared_key = var.custom_tunnel2_preshared_key
}

# To allow HCP to attach to our transit gateway
resource "aws_ram_resource_share" "arn_for_hcp" {
  count = var.transit_gateway ? 1 : 0
  name                      = "arn_for_hcp"
  allow_external_principals = true
}

resource "aws_ram_resource_association" "assoc_transit_gw" {
  count = var.transit_gateway ? 1 : 0
  resource_share_arn = aws_ram_resource_share.arn_for_hcp[0].arn
  resource_arn       = module.tgw.ec2_transit_gateway_arn
}


# To remotely access our test instance for troubleshooting
resource "aws_key_pair" "admin" {
  key_name   = "admin"
  public_key = var.ssh_pub_key
}

# Allow remote SSH connectivity and everything outbound
resource "aws_security_group" "lab_sg" {
  name   = "sebastien_lab_sg"
  vpc_id = module.vpc.vpc_id
  ingress {
    description = "Restrict SSH access to the bare minimum soon"
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

# Test instance
resource "aws_instance" "lab_ec2" {
  ami                         = "ami-0a5b5c0ea66ec560d" # Debian 11 @ eu-central-1
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  key_name                    = "admin"
  vpc_security_group_ids      = [aws_security_group.lab_sg.id]
}