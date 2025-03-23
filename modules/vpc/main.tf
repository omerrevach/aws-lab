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

module "iam" {
  source = "./modules/iam"

  iam_role_name             = "ec2-ssm-role"
  iam_instance_profile_name = "ec2-ssm-profile"
}

module "ec2" {
  source = "./modules/ec2"

  linux_ami            = var.linux_ami
  windows_ami          = var.windows_ami
  instance_type        = var.instance_type
  private_subnets      = module.vpc.private_subnets
  iam_instance_profile = module.iam.ec2_instance_profile
  linux_name           = var.linux_name
  windows_name         = var.windows_name
  k8s_version          = var.k8s_version
  k8s_build            = var.k8s_build
}