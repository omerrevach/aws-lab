variable "dockerhub_username" {
  type = string
}

variable "dockerhub_password" {
  type = string
}

variable "github_repo" {
  type = string
  description = "Format: owner/repo"
}

variable "github_oauth_token" {
  type = string
}
