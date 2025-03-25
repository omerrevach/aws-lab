variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "private_subnets" {
  type        = list(string)
  description = "Private subnet IDs"
}

variable "eks_fargate_pod_execution_role_arn" {
  type        = string
  description = "IAM Role ARN for EKS Fargate pods"
}

variable "ec2_ssm_role_arn" {
  description = "IAM role ARN for EC2 (SSM)"
  type        = string
}

