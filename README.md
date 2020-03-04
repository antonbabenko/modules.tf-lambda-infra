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


## License

This work is licensed under MIT License. See LICENSE for full details.

Copyright (c) 2020 Anton Babenko
