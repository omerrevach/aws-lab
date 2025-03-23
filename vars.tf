// VPC
variable "vpc_name" {}
variable "vpc_cidr" {}
variable "availability_zones" {}
variable "private_subnets" {}
variable "public_subnets" {}
variable "enable_nat_gateway" {}
variable "single_nat_gateway" {}

// IAM
variable "iam_role_name" {}
variable "iam_instance_profile_name" {}

// EC2
variable "linux_ami" {}
variable "windows_ami" {}
variable "instance_type" {}
variable "linux_name" {}
variable "windows_name" {}
variable "k8s_version" {}
variable "k8s_build" {}