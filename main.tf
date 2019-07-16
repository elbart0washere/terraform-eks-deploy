###### VARIABLES ######
variable "aws_region" {
  description = "AWS Region"
}
variable "profile" {
  description = "AWS Profile"
}
variable "celula" {
  description = "Celula Name"
}
variable "env" {
  description = "Environment"
}
variable "owner" {
  description = "Deploy owner"
}
variable "key" {
  description = "Key for ssh"
}
variable "aws_azs" {
  type = "list"
  description = "AZ selector"
}
locals {
  name = "${var.celula}_${var.env}"
  eks_name = "${var.eks_name}"
  tags = {
    Name = "${var.celula}_${var.env}"
    Env     = "${var.env}"
    Celula = "${var.celula}"
    Owner = "${var.owner}"
   }
  backend-subnet = {
  Name = "subnet-backend-${var.celula}-${var.env}"
  Env     = "${var.env}"
  Celula = "${var.celula}"
   }
}
###### AWS PROVIDER ######
provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.profile}"
}
terraform {
  required_version = "> 0.12.0"
  backend "s3" {
    bucket  = "YOUR_BUCKET" // if you wanna save state on bucket
    key     = "prd/terraform.tfstate" //S3 path
    region  = "us-east-1" //region of bucket
    profile = "YOURPROFILEHERE" // your aws profile (read aws configure)
  }
}
data "aws_availability_zones" "available" {}
