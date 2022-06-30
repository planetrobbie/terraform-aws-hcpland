variable "aws_region" {
  description = "the region where our PoV will be deployed"
  type        = string
  default     = "eu-central-1"
}

variable "availability_zones" {
  description = "A list AZs"
  type        = list
  default     = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "sebastien-hcp-vpc"
}

variable "private_subnets" {
  description = "A list private subnets"
  type        = list
  default     = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
}

variable "ec2_private_ips" {
  description = "Lab Instance Private IP"
  type        = list
  default     = ["10.0.10.10"]
}

variable "public_subnets" {
  description = "A list public subnet cidr blocks"
  type        = list
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}
