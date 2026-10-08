variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "db_username" {
  description = "PostgreSQL username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "admin_cidr" {
  description = "Public IPv4 CIDR allowed to SSH to EC2. Use your public IP as /32."
  type        = string
}

variable "domain_name" {
  description = "DNS name that points to the EC2 Elastic IP for Caddy HTTPS."
  type        = string
}
