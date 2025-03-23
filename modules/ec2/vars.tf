variable "linux_ami" {}
variable "windows_ami" {}
variable "instance_type" {}
variable "iam_instance_profile" {}
variable "private_subnets" {
  type        = list(string)
}
variable "linux_name" {}
variable "windows_name" {}
variable "k8s_version" {}
variable "k8s_build" {}
variable "vpc_id" {}