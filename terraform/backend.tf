terraform {
  backend "s3" {
    bucket = "mahesh-strapi-terraform-state"
    key    = "strapi/terraform.tfstate"
    region = "us-east-1"
    # dynamodb_table = "terraform-lock" # Optional: Add this if you create a DynamoDB table for locking
    encrypt = true
  }
}
