variable "linux_ami" {
  description = "AMI ID for Linux instances"
  type        = string
}

variable "windows_ami" {
  description = "AMI ID for Windows instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "iam_instance_profile" {
  description = "IAM instance profile name"
  type        = string
}

variable "linux_name" {
  description = "Name tag for Linux instance"
  type        = string
}

variable "windows_name" {
  description = "Name tag for Windows instance"
  type        = string
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
}

variable "k8s_build" {
  description = "Kubernetes build identifier"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

# Add new variables for EKS information
variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_cluster_endpoint" {
  description = "Endpoint URL of the EKS cluster"
  type        = string
}

variable "eks_cluster_ca_data" {
  description = "Certificate authority data for the EKS cluster"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}