module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc.cidr
  
  azs =  var.availability_zones
  private_subnets = var.private_subnets
  public_subnets = var.public_subnets

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway
  enable_dns_hostnames = true
  enable_dns_support = true

  private_subnet_tags = var.private_subnet_tags
  public_subnet_tags  = var.public_subnet_tags
}
