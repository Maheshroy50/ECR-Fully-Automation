# ECS Fully Automation Guide (Private Fargate Architecture)

This guide details how to deploy your Strapi application on **AWS ECS using Fargate** (Serverless) in a **Private Network Architecture**.

## 🏗️ Architecture Overview

The system is designed for **Maximum Security**:

1.  **Public Layer (Internet Facing)**
    -   **ALB (Load Balancer)**: Lives in the **Public Subnets** of your Default VPC.
    -   **NAT Gateway**: Lives in a Public Subnet. Allows private services to reach AWS (ECR, CloudWatch).
    -   **Traffic Flow**: User -> ALB (Port 80) -> NAT -> Private Network.

2.  **Private Layer (Hidden)**
    -   **ECS Fargate**: Lives in **Private Subnets** (`172.31.200.0/24`, `172.31.201.0/24`). **No Public IP.**
    -   **RDS Database**: Lives in **Private Subnets**. isolated from the internet.
    -   **Security**: ECS only accepts traffic from ALB. RDS only accepts traffic from ECS.

## 📋 Prerequisites

1.  **AWS Account**: Active account.
2.  **Terraform State**: S3 bucket `mahesh-strapi-terraform-state` in `us-east-1`.
3.  **ECR Repo**: `strapi-fargate-app` (us-east-1).
4.  **IAM Role**: `ecs_fargate_taskRole` 
    -   **Policy**: `AmazonECSTaskExecutionRolePolicy`.
5.  **Log Group**: CloudWatch Log Group `/ecs/strapi-prod` 

## 🚀 Deployment Workflow (GitHub Actions)

The process is fully automated via `.github/workflows/ci.yml`.

1.  **Push to `main`**: Triggers the pipeline.
2.  **Build Phase**:
    -   Docker builds the image.
    -   Tags it with the Git Commit SHA.
    -   Pushes to ECR: `811738710312.dkr.ecr.us-east-1.amazonaws.com/strapi-fargate-app:<sha>`
3.  **Deploy Phase**:
    -   Terraform runs `apply`.
    -   Updates the **Task Definition** with the new image tag.
    -   Updates the **ECS Service**.
    -   ECS starts new tasks in the Private Subnets.

## 🔧 Important Configuration

### Terraform Variables
| Variable | Value | Description |
| :--- | :--- | :--- |
| `project_name` | `strapi-prod` | Defines Log Group `/ecs/strapi-prod` |
| `instance_type` | *REMOVED* | Not used for Fargate. |
| `image_tag` | `latest` (or SHA) | dynamic. |

### Logs
-   **Console**: Go to CloudWatch -> Log groups -> `/ecs/strapi-prod`.
-   **Streams**: `ecs/strapi/<task-id>`.

## 🛠️ Troubleshooting

1.  **504 Gateway Timeout**:
    -   Check if the Task is running.
    -   Check **ALB Security Group** (Must allow port 80).
    -   Check **ECS Security Group** (Must allow port 1337 from ALB SG).

2.  **Task Fails to Start (Pending -> Stopped)**:
    -   **Log**: "CannotPullContainerError"? -> Check **NAT Gateway**. Private tasks need NAT to reach ECR.
    -   **Log**: "Connection Timed Out"? -> Check RDS Security Group.

3.  **Database Connection Refused**:
    -   Ensure RDS SG allows traffic on port `5432` from `ecs_sg`.
