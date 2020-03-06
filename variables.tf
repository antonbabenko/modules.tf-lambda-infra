variable "allowed_account_ids" {
  description = "List of allowed AWS acount ids where infrastructure will be created"
  type        = list(string)
}

variable "aws_region" {
  description = "AWS region where infrastructure will be created"
  type        = string
  default     = "eu-west-1"
}

variable "name" {
  description = "Name or prefix for many related resources"
  type        = string
  default     = "modulestf"
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

variable "route53_env_hosts" {
  description = "List of Route53 names (subdomains) for prod and dev environments"
  type        = list(string)
  default     = []
}

variable "create_dl_bucket" {
  description = "Whether to create S3 bucket for downloads"
  type        = bool
  default     = false
}

variable "dl_bucket_name" {
  description = "Name of S3 bucket for downloads (should not include route53_zone_name)"
  type        = string
  default     = null
}

variable "thundra_api_key" {
  description = "Thundra API key (secret)"
  type        = string
  default     = null
}

variable "ssm_prefix" {
  description = "Prefix to use in SSM key"
  type        = string
  default     = "modulestf"
}
