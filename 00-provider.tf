provider "aws" {
  region = "ap-northeast-2"
  alias  = "ap-northeast-2"
}

variable "number" {
  type        = string
  default     = "3113" # 학번 변경
}

variable "aws_region" {
  type        = string
  default     = "ap-northeast-2"
}
variable "project_name" {
  default = "gbsw"
}

data "aws_caller_identity" "current" {}