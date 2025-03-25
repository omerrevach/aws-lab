variable "cluster_name" {}
variable "vpc_id" {}
variable "private_subnets" {
  type        = list(string)
}
variable "eks_fargate_pod_execution_role_arn" {}
variable "ec2_ssm_role_arn" {}

