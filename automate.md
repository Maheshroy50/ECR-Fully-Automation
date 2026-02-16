# Automate Strapi Deployment with GitHub Actions

This guide explains how to set up and use the automated deployment pipeline for your Strapi application on AWS.

## 1. Prerequisites

Before running the pipelines, ensure you have the following secrets added to your GitHub Repository Settings (`Settings` -> `Secrets and variables` -> `Actions`).

### Required Secrets

| Secret Name | Description |
| :--- | :--- |
| `DOCKER_USERNAME` | Your Docker Hub username. |
| `DOCKER_PASSWORD` | Your Docker Hub password or Access Token (recommended). |
| `AWS_ACCESS_KEY_ID` | Your AWS Access Key ID. |
| `AWS_SECRET_ACCESS_KEY` | Your AWS Secret Access Key. |

> [!NOTE]
> **Docker Hub Repository Name**: The workflows are now configured to use **`maheshbhoopathirao/strapi-app`**.
> ensure your `DOCKER_USERNAME` secret matches the user who has push access to this repository.

> [!IMPORTANT]
> **Terraform State Management**: The project is now configured to use an **S3 remote backend**.
>
> File: `terraform/backend.tf`
> ```hcl
> terraform {
>   backend "s3" {
>     bucket = "mahesh-strapi-terraform-state"
>     key    = "strapi/terraform.tfstate"
>     region = "us-east-1"
>   }
> }
> ```
>
> **Action Required**: Ensure the GitHub Actions runner has permissions to access this S3 bucket. Since we are using standard AWS credentials (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`), ensure the IAM user associated with these keys has `s3:ListBucket`, `s3:GetObject`, and `s3:PutObject` permissions on the `mahesh-strapi-terraform-state` bucket.

## 2. CI Pipeline (Build & Push)

**File**: `.github/workflows/ci.yml`

### Triggers
- Automatically runs on every `push` to the `main` branch.
- Ignores changes in `terraform/` folder and `README.md`.

### What it does
1.  Checkouts the code.
2.  Logs in to Docker Hub.
3.  Builds the Docker image from your `Dockerfile`.
4.  Pushes the image to Docker Hub with tags: `latest` and `sha-<commit_hash>`.

## 3. CD Pipeline (Deploy)

**File**: `.github/workflows/terraform.yml`

### Triggers
- **Manual Trigger**: You must go to the **Actions** tab in GitHub, select **CD - Deploy with Terraform**, and click **Run workflow**.

### Inputs
- **Docker Image Tag**: Enter the specific tag you want to deploy (e.g., `sha-83a3f...` or `latest`). Defaults to `latest`.

### What it does
1.  Checkouts the code.
2.  Sets up AWS credentials.
3.  Runs `terraform init`.
4.  Runs `terraform plan` injecting your Docker Hub credentials and the image tag.
5.  Runs `terraform apply` to update the EC2 instance's user data script with the new image tag.

**Note**: Updating the EC2 user data usually requires an instance replacement or a reboot to take effect effectively. Using `user_data` updates force a replacement if configured, or you might need to use a different approach (like SSH'ing into the box) for zero-downtime deployments. The current Terraform setup will likely replace the instance if the user data changes, which causes downtime but ensures a .

## 4. How to Verify Deployment

1.  **Check Actions Tab**: Ensure both workflows complete successfully.
2.  **AWS Console**: Check your EC2 dashboard. You should see the instance launching or running.
3.  **access Strapi**: Visit `http://<EC2_PUBLIC_IP>:1337` (or port 80 if Nginx is configured correctly).

## 5. Destroy Infrastructure

**File**: `.github/workflows/destroy.yml`

### Triggers
- **Manual Trigger only**: Go to **Actions** -> **Destroy Infrastructure** -> **Run workflow**.

### What it does
- Runs `terraform destroy -auto-approve` to completely remove all AWS resources created by this project (EC2, Security Groups, Key Pairs, etc.).
- **Warning**: This action is irreversible. All data on the EC2 instance will be lost.

