variable "linux_ami" {}
variable "windows_ami" {}
variable "instance_type" {}
variable "private_subnets" {
  type        = list(string)
}
variable "iam_instance_profile" {}
variable "linux_name" {}
variable "windows_name" {}
variable "k8s_version" {}
variable "k8s_build" {}
variable "vpc_id" {}
variable "eks_cluster_name" {}
variable "eks_cluster_endpoint" {}
variable "eks_cluster_ca_data" {}
variable "aws_region" {}