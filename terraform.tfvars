// VPC
vpc_name           = "aws-lab-vpc"
vpc_cidr = "10.0.0.0/16"


availability_zones = ["eu-north-1a", "eu-north-1b"]

private_subnets = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

public_subnets = [
  "10.0.3.0/24",
  "10.0.4.0/24"
]

enable_nat_gateway   = true
single_nat_gateway   = true

// IAM / SSM
iam_role_name             = "ec2-ssm-role"
iam_instance_profile_name = "ec2-ssm-profile"

// EC2
linux_ami     = "ami-0f65a9eac3c203b54"  // Amazon Linux 2
windows_ami   = "ami-01727d3e89897c9c3"  // Microsoft Windows Server 2022 Base

instance_type = "t3.micro"
linux_name    = "linux_connect_to_eks"
windows_name  = "windows"

k8s_version = "1.31.4"
k8s_build   = "2025-01-10"
