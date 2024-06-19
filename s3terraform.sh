#!/bin/bash
#
#
#   This script is created by Harish and this script deploys your html page to aws s3
#
#
echo -e "\e[32m +Installing required packages\e[0m"
sudo apt install figlet lolcat
echo 
figlet -f slant The Deployer AWS S3| lolcat
echo
echo -e "\e[32m +Installing Terraform\e[0m"
if ! [ -f terraform ]
then
wget https://releases.hashicorp.com/terraform/1.8.5/terraform_1.8.5_linux_amd64.zip
unzip terraform_1.8.5_darwin_amd64.zip 
sudo cp terraform /usr/bin
rm -rf terraform_1.8.5_darwin_amd64.zip
echo
fi
echo -e "\e[32m +Installing Terraform\e[0m"
echo
echo -e "\e[32m +Installing AWS cli \e[0m"
sudo apt install awscli
echo 

echo -e "\e[32m +Authenticate your AWS account \e[0m"
sudo aws configure
echo

echo -e "\e[32m +Enter the bucket name: \e[0m"
read name
echo

# Write to main.tf
cat <<- EOL > main.tf
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.54.1"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}
resource "aws_s3_bucket" "example" {
  bucket = "$name"

  tags = {
    Name        = "$name"
    Environment = "Dev"
  }
}
resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.example.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "example" {
  depends_on = [
    aws_s3_bucket_ownership_controls.example,
    aws_s3_bucket_public_access_block.example,
  ]

  bucket = aws_s3_bucket.example.id
  acl    = "public-read"
}
resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.example.id
  key    = "index.html"
  source = "index.html"
  acl = "public-read"
    content_type = "text/html"
}
resource "aws_s3_object" "error" {
  bucket = aws_s3_bucket.example.id
  key    = "error.html"
  source = "error.html"
  acl = "public-read"
  content_type = "text/html"
} 
resource "aws_s3_bucket_website_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

output "domain" {
  value = aws_s3_bucket.example.website_endpoint
}
EOL

echo "main.tf has been created with the provided configuration."

echo -e "\e[32m +Initialising \e[0m"
terraform init
echo

echo -e "\e[32m +Changes to be made \e[0m"
terraform plan
echo

terraform apply -auto-approve
terraform apply -auto-approve

echo "stop hosting? (y/n)"
read ans
if [ $ans == y ]
then
terraform destroy -auto-approve
figlet -f slant Thank you! | lolcat
fi