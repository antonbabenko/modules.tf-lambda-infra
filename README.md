# modules.tf-lambda-infra

This repository contains Terraform configurations required to provision AWS infrastructure for modules.tf:

- ALB
- ACM
- S3 bucket for downloads
- Route53 records

## Usage

1. Copy file `terraform.tfvars.sample` into `terraform.tfvars` and put correct values there. This file may contain secrets, so be careful.
2. Use Terraform as usual: `terraform init && terraform apply`
3. Once AWS infrastructure is created, serverless framework application (modules.tf-lambda) can be deployed. Go to `modules.tf-lambda` project for more information.

## Deployments

### cloudcraft

```
$ awsp modules-deploy  # Assume IAM role in correct account
$ make cloudcraft
```

### betajob - development setup

```
$ awsp private-anton  # Assume IAM role in correct account
$ make betajob
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Providers

| Name | Version |
|------|---------|
| aws | ~> 2.0 |
| random | ~> 2.2 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| allowed\_account\_ids | List of allowed AWS acount ids where infrastructure will be created | `list(string)` | n/a | yes |
| aws\_region | AWS region where infrastructure will be created | `string` | `"eu-west-1"` | no |
| create\_dl\_bucket | Whether to create S3 bucket for downloads | `bool` | `false` | no |
| dl\_bucket\_name | Name of S3 bucket for downloads (should not include route53\_zone\_name) | `string` | n/a | yes |
| name | Name or prefix for many related resources | `string` | `"modulestf"` | no |
| public\_subnets | List of existing public subnets to use | `list(string)` | n/a | yes |
| route53\_env\_hosts | List of Route53 names (subdomains) for prod and dev environments | `list(string)` | `[]` | no |
| route53\_zone\_name | Zone name for ALB and ACM | `string` | n/a | yes |
| ssm\_prefix | Prefix to use in SSM key | `string` | `"modulestf"` | no |
| thundra\_api\_key | Thundra API key (secret) | `string` | n/a | yes |
| vpc\_cidr | VPC CIDR block | `string` | n/a | yes |
| vpc\_id | Existing VPC ID to use | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| everything | Everything useful for serverless app |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## License

This work is licensed under MIT License. See LICENSE for full details.

Copyright (c) 2020 Anton Babenko
