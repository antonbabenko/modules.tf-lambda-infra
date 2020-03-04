# modules.tf-infra

This repository contains Terraform configurations required to provision AWS infrastructure for modules.tf:

- ALB
- ACM
- S3 bucket for downloads
- Route53 zone
- IAM permissions

## Usage

1. Copy file `terraform.tfvars.sample` into `terraform.tfvars` and put correct values there. This file may contain secrets, so be careful.
2. Use Terraform as usual: `terraform init && terraform apply`
3. Once AWS infrastructure is created, serverless framework application (modules.tf-lambda) can be deployed. Go to `modules.tf-lambda` project for more information.


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Providers

| Name | Version |
|------|---------|
| aws | ~> 2.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| dl\_bucket\_name | Name of S3 bucket for downloads (should not include route53\_zone\_name) | `string` | n/a | yes |
| name | Name or prefix for many related resources | `string` | n/a | yes |
| public\_subnets | List of existing public subnets to use | `list(string)` | n/a | yes |
| route53\_zone\_name | Zone name for ALB and ACM | `string` | n/a | yes |
| ssm\_app | Prefix to use in SSM key | `string` | n/a | yes |
| ssm\_stage | Stage name to use in SSM key | `string` | n/a | yes |
| thundra\_api\_key | Thundra API key (secret) | `string` | n/a | yes |
| vpc\_cidr | VPC CIDR block | `string` | n/a | yes |
| vpc\_id | Existing VPC ID to use | `string` | `""` | no |

## Outputs

No output.

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## License

This work is licensed under MIT License. See LICENSE for full details.

Copyright (c) 2020 Anton Babenko
