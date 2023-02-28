provider "aws" {
  version = "~> 4.0"
  region  = var.region
}

data "aws_ami" "ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "main" {
  key_name_prefix = "test-"
  public_key      = tls_private_key.main.public_key_openssh
}

resource "local_file" "private_ssh_key" {
  filename        = "id_rsa"
  file_permission = "0600"
  content         = tls_private_key.main.private_key_pem
}
