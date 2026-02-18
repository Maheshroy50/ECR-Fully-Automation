# ECS Fully Automation Guide (Fargate Launch Type)

This guide details how to deploy your Strapi application on **AWS ECS using Fargate** (Serverless) and a cost-optimized **RDS (db.t3.micro, Single-AZ)**.

## Architecture Highlights

-   **Compute**: ECS Fargate (Serverless) running in **Private Subnets**.
    -   **Resources**: 1 vCPU, 2 GB RAM per task.
    -   **Scaling**: Managed by ECS Service (Desired Count: 1).
-   **Database**: RDS Postgres (**db.t3.micro**, **Single-AZ**) in **Private Subnets**.
-   **Networking**:
    -   **Public**: ALB (Internet Facing).
    -   **Private**: Fargate + RDS (No direct Internet access).
    -   **Egress**: NAT Gateway allowed for Fargate (to pull images/logs).
-   **Registry**: Existing ECR repository `strapi-fargate-app`.
-   **CI/CD**: Fully automated GitHub Actions workflow (Build -> Deploy).

## Prerequisites

1.  **AWS Account**: Active account.
2.  **Terraform State**: S3 bucket `mahesh-strapi-terraform-state` exists in `us-east-1`.
3.  **ECR Repo**: Repository `strapi-fargate-app` exists.
4.  **IAM Role**: `ecs_fargate_taskRole` must exist in IAM with `AmazonECSTaskExecutionRolePolicy` attached.

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
| `project_name` | Name of the project (e.g., `strapi-prod`) |
| `db_password` | **CRITICAL**: Password for the RDS instance. |
| `image_tag` | Docker image tag (automatic in CI/CD). |

## Deployment Workflow

1.  **Fully Automated**:
    -   Push code to `main`.
    -   **Step 1: Build**: Docker builds image and pushes to ECR `strapi-fargate-app`.
    -   **Step 2: Deploy**: Terraform updates the ECS Task Definition to point to the new image tag and updates the Service.
    -   **Step 3: Rolling Update**: AWS ECS starts new Fargate tasks and drains old ones automatically.

2.  **No Manual Steps**:
    -   The pipeline handles everything.

## Troubleshooting

-   **Task Stopped**: If tasks start and immediately stop, check **CloudWatch Logs** (`/ecs/strapi-prod`). Common issues:
    -   Database connection failure (check RDS SG).
    -   Missing Environment Variables.
-   **Pull Access Denied**: Ensure `ecs_fargate_taskRole` has `AmazonECSTaskExecutionRolePolicy`.
-   **502 Bad Gateway**: The task is running but Strapi is not responding on port 1337, or the Health Check is failing. Check logs.
