variable "dockerhub_username" {
  type        = string
  description = "Docker Hub username"
}

variable "dockerhub_password" {
  type        = string
  description = "Stored in Secrets Manager"
}

variable "github_token" {
  type        = string
  description = "GitHub pat token for source access"
}

variable "pipeline_artifact_bucket" {
  type        = string
  description = "S3 bucket name for CodePipeline artifacts"
}

variable "aws_region" {
  type    = string
  default = "eu-north-1"
}
