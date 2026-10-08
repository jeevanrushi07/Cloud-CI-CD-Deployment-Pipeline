output "ecr_repo_url" {
  value = aws_ecr_repository.greeting_app.repository_url
}

output "ec2_instance_id" {
  value = aws_instance.flask_ec2.id
}

output "elastic_ip" {
  value = aws_eip.app.public_ip
}

output "https_url" {
  value = "https://${var.domain_name}"
}

output "db_endpoint" {
  value = aws_db_instance.postgres.address
}
