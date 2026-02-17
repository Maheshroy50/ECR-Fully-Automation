# ECS Fully Automation Guide (EC2 Launch Type)

This guide details how to deploy your Strapi application on **AWS ECS using EC2 instances** (for maximum control and cost check) and a cost-optimized **RDS (db.t3.micro, Single-AZ)**.

## Architecture Highlights

-   **Compute**: ECS running on **EC2 instances** (t2.micro managed via Auto Scaling Group).
-   **Database**: RDS Postgres (**db.t3.micro**, **Single-AZ**) to minimize costs.
-   **Registry**: Existing ECR repository `strapi-fargate-app`.
-   **CI/CD**: Fully automated GitHub Actions workflow (Build -> Deploy).

## Prerequisites

1.  **AWS Account**: Active account.
2.  **Terraform State**: S3 bucket `mahesh-strapi-terraform-state` exists in `us-east-1`.
3.  **ECR Repo**: Repository `strapi-fargate-app` exists.

## Secrets Required in GitHub

Go to **Settings** > **Secrets and variables** > **Actions** and adds these secrets:

| Secret Name | Description | Example Value |
| :--- | :--- | :--- |
| `AWS_ACCESS_KEY_ID` | CI/CD User Access Key | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | CI/CD User Secret Key | `wJalr...` |
| `TF_VAR_DB_PASSWORD` | **RDS Password** | `strong_password...` |
| `TF_VAR_JWT_SECRET` | Strapi Secret | `...` |
| `TF_VAR_ADMIN_JWT_SECRET` | Strapi Secret | `...` |
| `TF_VAR_API_TOKEN_SALT` | Strapi Secret | `...` |
| `TF_VAR_APP_KEYS` | Strapi Keys | `key1,key2...` |

> **Tip**: You can assume the variables I generated in `terraform/terraform.tfvars` are good to use.

## Terraform Variables

The following Terraform variables will be used. You can set them in `terraform.tfvars` locally or as environment variables in CI/CD.

| Variable | Description |
| :--- | :--- |
| `project_name` | Name of the project (e.g., `my-strapi`) |
| `db_password` | **CRITICAL**: Password for the RDS instance. |
| `jwt_secret` | Strapi JWT Secret |
| `api_token_salt` | Strapi API Token Salt |
| `app_keys` | Strapi App Keys (comma separated) |

## Deployment Workflow

1.  **Fully Automated**:
    -   Push code to `main`.
    -   **Step 1: Build**: Docker builds image and pushes to ECR `strapi-fargate-app`.
    -   **Step 2: Deploy**: Terraform updates the ECS Service to run the new image on your EC2 instances.

2.  **No Manual Steps**:
    -   The pipeline handles everything.

## Troubleshooting

-   **Instance Connectivity**: If ECS tasks fail to start, check if the EC2 instances in the Auto Scaling Group have registered with the cluster.
-   **Database Connection**: Ensure the `rds_sg` allows traffic from `ecs_sg`.


