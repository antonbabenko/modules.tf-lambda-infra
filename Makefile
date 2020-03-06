.PHONY: cloudcraft betajob

cloudcraft:
	terraform init -backend-config=cloudcraft/backend.hcl -reconfigure && terraform apply -var-file=cloudcraft/terraform.tfvars

betajob:
	terraform init -backend-config=betajob/backend.hcl -reconfigure && terraform apply -var-file=betajob/terraform.tfvars
