terraform {
  required_version = "~> 0.12.23"

  required_providers {
    aws    = "~> 2.0"
    random = "~> 2.2"
  }

  backend "remote" {}
}

provider "aws" {
  region              = var.aws_region
  allowed_account_ids = var.allowed_account_ids
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
  zone_name      = trimsuffix(data.aws_route53_zone.this.name, ".")

  tags = {
    Name = var.name
  }

  // Fix for cold-run when ssm_outputs contain unknown values and can't be used in for_each, so using `count` instead .
  number_of_ssm_outputs = 5

  ssm_outputs = [
    {
      key         = "alb_listener_arn"
      value       = aws_lb_listener.https.arn
      description = "ALB listener ARN"
    },
    {
      key         = "prod_route53_record_fqdn"
      value       = aws_route53_record.alb_a[var.route53_env_hosts[0]]["fqdn"]
      description = "FQDN of prod environment"
    },
    {
      key         = "dev_route53_record_fqdn"
      value       = aws_route53_record.alb_a[var.route53_env_hosts[1]]["fqdn"]
      description = "FQDN of dev environment"
    },
    {
      key         = "dl_bucket_id"
      value       = var.create_dl_bucket ? module.dl_bucket.this_s3_bucket_id : var.dl_bucket_name
      description = "Name of S3 bucket for downloads"
    },
    {
      key         = "thundra_api_key"
      value       = var.thundra_api_key
      type        = "SecureString"
      description = "Thundra API Key"
    }
  ]
}

resource "random_pet" "this" {
  length = 1
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

  enable_ipv6                     = true
  assign_ipv6_address_on_creation = true
  public_subnet_ipv6_prefixes     = [for k, v in data.aws_availability_zones.available.names : k]

  tags = local.tags
}

###################
# ACM
###################
module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 2.0"

  domain_name               = local.zone_name
  subject_alternative_names = ["*.${local.zone_name}"]
  zone_id                   = data.aws_route53_zone.this.id

  tags = local.tags
}

###################
# ALB
###################
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"

  name = "${var.name}-${random_pet.this.id}"

  load_balancer_type = "application"

  vpc_id          = local.vpc_id
  subnets         = local.public_subnets
  security_groups = [module.alb_sg.this_security_group_id]
  ip_address_type = "dualstack"

  tags = local.tags
}

#########################################
# Adding 1 HTTPS listener without target group (not supportd by ALB module, yet)
#########################################
resource "aws_lb_listener" "https" {
  load_balancer_arn = module.alb.this_lb_arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = module.acm.this_acm_certificate_arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Have a great day!"
      status_code  = "200"
    }
  }
}
#########################################

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

  create_bucket = var.create_dl_bucket

  bucket              = var.dl_bucket_name
  acl                 = "private"
  force_destroy       = true
  block_public_policy = true

  cors_rule = {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }

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

##################
# Route53 records
##################
resource "aws_route53_record" "alb_a" {
  for_each = toset(var.route53_env_hosts)

  zone_id = data.aws_route53_zone.this.id
  name    = each.key
  type    = "A"

  alias {
    name                   = module.alb.this_lb_dns_name
    zone_id                = module.alb.this_lb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "alb_aaaa" {
  for_each = toset(var.route53_env_hosts)

  zone_id = data.aws_route53_zone.this.id
  name    = each.key
  type    = "AAAA"

  alias {
    name                   = module.alb.this_lb_dns_name
    zone_id                = module.alb.this_lb_zone_id
    evaluate_target_health = false
  }
}

#################
# SSM Parameters
#################
resource "aws_ssm_parameter" "outputs_dev" {
  count = local.number_of_ssm_outputs

  name        = "/${var.ssm_prefix}/dev/${element(local.ssm_outputs, count.index)["key"]}"
  value       = element(local.ssm_outputs, count.index)["value"]
  description = lookup(element(local.ssm_outputs, count.index), "description", null)
  type        = lookup(element(local.ssm_outputs, count.index), "type", "String")
  overwrite   = true
}

resource "aws_ssm_parameter" "outputs_prod" {
  count = local.number_of_ssm_outputs

  name        = "/${var.ssm_prefix}/prod/${element(local.ssm_outputs, count.index)["key"]}"
  value       = element(local.ssm_outputs, count.index)["value"]
  description = lookup(element(local.ssm_outputs, count.index), "description", null)
  type        = lookup(element(local.ssm_outputs, count.index), "type", "String")
  overwrite   = true
}

##########
# Outputs
##########
output "everything" {
  description = "Everything useful for serverless app"
  value = {
    dev  = { for k, v in aws_ssm_parameter.outputs_dev : v.id => v.value },
    prod = { for k, v in aws_ssm_parameter.outputs_prod : v.id => v.value },
  }
}
