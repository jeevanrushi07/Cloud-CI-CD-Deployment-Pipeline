terraform {
  backend "s3" {
    encrypt = true
    region  = "ap-south-1"
  }
}