# VPC
output "vpc_id" {
  description = "The ID of the VPC"
  value       = "${module.vpc.vpc_id}"
}

# CIDR blocks
output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = ["${module.vpc.vpc_cidr_block}"]
}

# Subnets
output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = ["${module.vpc.private_subnets}"]
}

output "ec2_public_ip" {
  value = aws_instance.lab_ec2.*.public_ip
}

output "aws_ram_resource_share" {
  value = aws_ram_resource_share.arn_for_hcp.arn
}