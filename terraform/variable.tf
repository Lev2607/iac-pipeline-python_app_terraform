variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}
variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = "Lev2607"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "iac-pipeline-python_app"
}

variable "github_branch" {
  description = "GitHub repository branch"
  type        = string
  default     = "main"
}

variable "github_token" {
  description = "GitHub token"
  type        = string
  default     = "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"
}