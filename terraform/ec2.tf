data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "cloud-cicd-ec2-sg"
  description = "Application, HTTPS and IP-restricted SSH"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH from administrator IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }


  ingress {
  description = "Flask application"
  from_port   = 5000
  to_port     = 5000
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}



  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecr_repository" "greeting_app" {
  name                 = "cloud-cicd-greeting-app"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_iam_role" "ec2_role" {
  name = "cloud-cicd-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ecr" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "cloud-cicd-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_eip" "app" {
  domain = "vpc"

  tags = {
    Name    = "cloud-cicd-eip"
    Project = "Cloud CI/CD Deployment Pipeline"
  }
}

resource "aws_instance" "flask_ec2" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = false

user_data = <<-EOF
            #!/bin/bash
            set -eux

            dnf update -y
            dnf install -y docker awscli-2 amazon-ssm-agent

            systemctl enable --now docker
            systemctl enable --now amazon-ssm-agent

            usermod -aG docker ec2-user || true
            EOF

  tags = {
    Name    = "Cloud-CICD-EC2"
    Project = "Cloud CI/CD Deployment Pipeline"
  }
}

resource "aws_eip_association" "app" {
  instance_id   = aws_instance.flask_ec2.id
  allocation_id = aws_eip.app.id
}
