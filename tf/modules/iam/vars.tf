variable "iam_role_name" {
  description = "IAM role name for EC2"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile name for EC2"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}
