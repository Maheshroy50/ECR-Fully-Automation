# ECS Fully Automation Guide

This guide details how to deploy your Strapi application to AWS ECS Fargate primarily using GitHub Actions and Terraform.

## Prerequisites

1.  **AWS Account**: You need an active AWS account.
2.  **Terraform State Bucket**: You have already created `mahesh-strapi-terraform-state` in `us-east-1`.
3.  **Domain (Optional)**: If you have a domain, we can configure SSL. For now, we will use the ALB DNS name.

## Secrets Required in GitHub

Go to your repository **Settings** > **Secrets and variables** > **Actions** and add the following secrets:

| Secret Name | Description | Example Value |
| :--- | :--- | :--- |
| `AWS_ACCESS_KEY_ID` | CI/CD User Access Key | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | CI/CD User Secret Key | `wJalr...` |
| `TF_VAR_DB_PASSWORD` | Infrastructure: RDS Password | `axPHdr...` |
| `TF_VAR_JWT_SECRET` | Infrastructure: Strapi JWT Secret | `A2AOIZ...` |
| `TF_VAR_ADMIN_JWT_SECRET` | Infrastructure: Admin JWT Secret | `x2+q0g...` |
| `TF_VAR_API_TOKEN_SALT` | Infrastructure: API Token Salt | `CCwVl/...` |
| `TF_VAR_APP_KEYS` | Infrastructure: App Keys | `97J2aB...` |

> **Important**: You can copy the values I generated in `terraform/terraform.tfvars` and paste them into these GitHub Secrets.

## Deployment Workflow

1.  **Fully Automated**:
    -   Push code to `main`.
    -   GitHub Action triggers:
        1.  **Terraform Job**: Runs `terraform apply` to provision/update AWS infrastructure (ECR, ECS, RDS, etc.).
        2.  **Deploy Job**: Builds Docker image, pushes to ECR, and updates the ECS Service.

2.  **No Manual Steps**:
    -   You do NOT need to run Terraform locally. The CI/CD pipeline handles everything.

## Troubleshooting

-   **Initial Run**: The very first run might fail at the "Deploy" stage if the ECS Service takes too long to stabilize because the image doesn't exist yet.
    -   *Fix*: Just re-run the workflow. Once the image is pushed, ECS will pick it up.

## Local Usage

To run Terraform locally:
```bash
cd terraform
export AWS_PROFILE=my-profile
terraform init
terraform plan
terraform apply
```
