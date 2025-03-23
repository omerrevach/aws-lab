module "vpc" {
  source = "../modules/vpc"

  name = var.vpc_name
  cidr = var.vpc_cidr
  
  azs =  var.availability_zones
  private_subnets = var.private_subnets
  public_subnets = var.public_subnets

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway
  enable_dns_hostnames = true
  enable_dns_support = true

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

module "iam" {
  source = "../modules/iam"

  iam_role_name             = var.iam_role_name
  iam_instance_profile_name = var.iam_instance_profile_name
}

module "ec2" {
  source = "../modules/ec2"

  linux_ami            = var.linux_ami
  windows_ami          = var.windows_ami
  instance_type        = var.instance_type
  private_subnets      = module.vpc.private_subnets
  iam_instance_profile = module.iam.ec2_instance_profile
  linux_name           = var.linux_name
  windows_name         = var.windows_name
  k8s_version          = var.k8s_version
  k8s_build            = var.k8s_build
  vpc_id               = module.vpc.vpc_id
}