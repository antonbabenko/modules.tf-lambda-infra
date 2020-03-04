variable "name" {
  description = "Name or prefix for many related resources"
  type        = string
}

variable "route53_zone_name" {
  description = "Zone name for ALB and ACM"
  type        = string
}

variable "vpc_id" {
  description = "Existing VPC ID to use"
  type        = string
  default     = ""
}

variable "public_subnets" {
  description = "List of existing public subnets to use"
  type        = list(string)
  default     = null
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = null
}

variable "dl_bucket_name" {
  description = "Name of S3 bucket for downloads (should not include route53_zone_name)"
  type = string
  default = null
}

variable "thundra_api_key" {
  description = "Thundra API key (secret)"
  type = string
  default = null
}

variable "ssm_app" {
  description = "Prefix to use in SSM key"
  type        = string
}

variable "ssm_stage" {
  description = "Stage name to use in SSM key"
  type        = string
}
