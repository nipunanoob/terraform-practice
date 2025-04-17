# 🛠️ Terraform AWS Practice

This project is a hands-on practice environment for using [Terraform](https://www.terraform.io/) to provision and manage AWS resources. It follows a modular structure, with each AWS service (e.g., IAM, EC2) in its own folder for clarity and reusability.

---

## 🚀 Getting Started

### 1. Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- AWS CLI configured (`aws configure`)
- IAM user with necessary permissions (IAM, EC2, S3, etc.)

---

### 2. Usage

#### Option A: Run a Single Module

```bash
cd iam
terraform init
terraform plan
terraform apply
```

#### Option B: Use Root to Control Modules

Edit main.tf in the root to include:

module "iam" {
  source = "./iam"
}

module "ec2" {
  source = "./ec2"
}

Then:

```
terraform init
terraform plan
terraform apply
```

### 3. Clean Up

```
terraform destroy
```

## Concepts Practiced so far

- Infrastructure as Code (IaC)
- IAM roles and users

## 🔒 .gitignore Note

Be sure to use a proper .gitignore to avoid committing sensitive data:
```
terraform.tfstate
.terraform/
*.tfvars
*.tfplan
```
