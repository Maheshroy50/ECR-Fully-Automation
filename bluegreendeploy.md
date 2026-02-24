# AWS CodeDeploy Blue/Green Deployment Setup

This document explains the architecture and operational flow of the Blue/Green deployment strategy implemented for the Strapi application using AWS ECS Fargate and AWS CodeDeploy.

## 1. What Have We Done?

We transitioned from a rolling update strategy (managed directly by Terraform/ECS) to a **Blue/Green deployment strategy** managed by **AWS CodeDeploy**. 

Here are the specific infrastructure changes we made in our Terraform codebase:

*   **Application Load Balancer (ALB)**:
    *   Replaced the single target group with **two** target groups: `blue` and `green`.
    *   Updated the primary production listener (Port 80) to route traffic to the `blue` target group by default.
    *   Added a test listener (Port 8080) pointing to the `green` target group, allowing us to hit the new deployment internally before shifting production traffic.
*   **ECS Service**:
    *   Changed the deployment controller from `ECS` (default rolling update) to `CODE_DEPLOY`.
    *   Configured the `lifecycle` block in Terraform to **ignore changes** to the `task_definition` and `load_balancer`. This is crucial because CodeDeploy dynamically modifies these settings during a deployment; if Terraform tried to manage them, it would cause conflicts and undo CodeDeploy's work.
*   **AWS CodeDeploy**:
    *   Created a CodeDeploy Application (`strapi-prod-codedeploy-app`).
    *   Created a CodeDeploy Deployment Group (`strapi-prod-codedeploy-group`).
    *   Configured the deployment group to use the **`CodeDeployDefault.ECSCanary10Percent5Minutes`** strategy.
    *   Assigned it a hardcoded IAM Role (`arn:aws:iam::811738710312:role/codedeploy_role`) that has permissions to manage ECS and the ALB.

## 2. How Does It Work?

With CodeDeploy in place, the deployment lifecycle changes significantly. Terraform is now only responsible for provisioning the base infrastructure, while CodeDeploy handles the actual release of new container images.

### The Deployment Flow
When you push new code to the `main` branch, the CI/CD pipeline triggers. A typical CodeDeploy flow involves an `appspec.yaml` and a `taskdef.json` file. Here is how CodeDeploy executes the rollout:

1.  **Provisioning (Green Environment)**: CodeDeploy starts new Fargate tasks using the new container image (the "Green" environment). These tasks register with the Green target group.
2.  **Verification (Optional)**: At this stage, production traffic (Port 80) is still hitting the Blue tasks. However, test traffic (Port 8080) is hitting the Green tasks. You can run automated or manual tests against Port 8080 to ensure the new version is healthy.
3.  **Traffic Shifting (Canary Strategy)**:
    *   Because we selected `CodeDeployDefault.ECSCanary10Percent5Minutes`, CodeDeploy will shift **10% of production traffic** from the Blue target group to the Green target group.
    *   It will wait for **5 minutes**.
    *   If no CloudWatch alarms trigger (and the tasks remain healthy), it will automatically shift the remaining **90% of traffic** to the Green target group.
4.  **Finalization**: Once 100% of traffic is reaching the Green instances, the deployment is considered successful. CodeDeploy marks the Green environment as the new "Production" environment.
5.  **Termination**: CodeDeploy will wait an additional 5 minutes to ensure stability, and then it will automatically **terminate** the old Blue tasks to save costs.

### Rollbacks
If the Green tasks fail to start, or if they crash during the 5-minute canary period, CodeDeploy will automatically:
1. Halt the deployment.
2. Shift 100% of traffic back to the original Blue instances.
3. Terminate the faulty Green instances.

This guarantees **zero-downtime** deployments and automatic recovery in case a bad update is pushed to production!
