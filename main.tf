terraform {
  required_version = "~> 0.12.21"

  required_providers {
    aws = "~> 2.0"
  }
}

###################
# Data sources
###################
data "aws_availability_zones" "available" {}

data "aws_route53_zone" "this" {
  name         = var.route53_zone_name
  private_zone = false
}

###################
# Locals
###################
locals {
  vpc_id         = length(var.vpc_id) == 0 ? module.vpc.vpc_id : var.vpc_id
  public_subnets = coalescelist(module.vpc.public_subnets, var.public_subnets)

  ssm_prefix = "/${var.ssm_app}/${var.ssm_stage}/"
  ssm_outputs = {
    alb_listener_arn = {
      description = "ALB listener ARN"
      value       = module.alb.https_listener_arns[0]
    },
    dl_bucket_id = {
      description = "Name of S3 bucket for downloads"
      value       = module.dl_bucket.this_s3_bucket_id
    },
    thundra_api_key = {
      description = "Thundra API Key"
      value       = var.thundra_api_key
      type = "SecureString"
    }
  }

  tags = {
    Name = var.name
  }
}

###################
# VPC
###################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.0"

  create_vpc = length(var.vpc_id) == 0

  name = var.name

  cidr           = var.vpc_cidr
  azs            = [for v in data.aws_availability_zones.available.names : v]
  public_subnets = [for k, v in data.aws_availability_zones.available.names : cidrsubnet(var.vpc_cidr, 8, k)]

  tags = local.tags
}

###################
# ACM
###################
module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 2.0"

  domain_name = trimsuffix(data.aws_route53_zone.this.name, ".")
  zone_id     = data.aws_route53_zone.this.id

  tags = local.tags
}

###################
# ALB
###################
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"

  name = var.name

  load_balancer_type = "application"

  vpc_id          = local.vpc_id
  subnets         = local.public_subnets
  security_groups = [module.alb_sg.this_security_group_id]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = module.acm.this_acm_certificate_arn
      target_group_index = 0
    },
  ]

  target_groups = [
    {
      name_prefix                        = "l1"
      target_type                        = "lambda"
      lambda_multi_value_headers_enabled = false
      health_check = {
        enabled             = true
        interval            = 10
        path                = "/healthz"
        healthy_threshold   = 5
        unhealthy_threshold = 3
        timeout             = 7
        matcher             = 200
      }
    },
  ]

  tags = local.tags
}

#####################
# ALB security group
#####################
module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws//modules/https-443"
  version = "~> 3.0"

  name        = "${var.name}-alb"
  vpc_id      = local.vpc_id
  description = "Security group with HTTPS port open for everyone"

  ingress_cidr_blocks = ["0.0.0.0/0"]

  tags = local.tags
}

#####################
# S3 bucket
#####################
module "dl_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 1.0"

  bucket                         = var.dl_bucket_name
  acl                            = "private"
  force_destroy                  = true

  lifecycle_rule = [
    {
      id      = "delete-all-ancient"
      enabled = true

      expiration = {
        days = 365
      }
    }
  ]
}

#################
# SSM Parameters
#################
resource "aws_ssm_parameter" "outputs" {
  for_each = local.ssm_outputs

  name        = "${local.ssm_prefix}/${each.key}"
  description = lookup(each.value, "description", null)
  value       = each.value.value
  type        = lookup(each.value, "type", "String")
}
