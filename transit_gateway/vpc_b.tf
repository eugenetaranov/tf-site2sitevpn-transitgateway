module "testvpc_b" {
  name                 = "transitgateway-testvpc-b"
  source               = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v3.19.0"
  cidr                 = var.testvpc_b_cidr
  azs                  = [for az in var.az : format("%s%s", var.region, az)]
  public_subnets       = [cidrsubnet(var.testvpc_b_cidr, 9, 0), cidrsubnet(var.testvpc_b_cidr, 9, 1), cidrsubnet(var.testvpc_b_cidr, 9, 2)]
  private_subnets      = [cidrsubnet(var.testvpc_b_cidr, 9, 10), cidrsubnet(var.testvpc_b_cidr, 9, 11), cidrsubnet(var.testvpc_b_cidr, 9, 12)]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
}

// ec2
resource "aws_security_group" "testvpc_b" {
  name_prefix = "transitgateway-testvpc-b"
  vpc_id      = module.testvpc_b.vpc_id
}

resource "aws_security_group_rule" "testvpc_b_ingress_ssh" {
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  security_group_id = aws_security_group.testvpc_b.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "testvpc_b_ingress_icmp" {
  from_port         = -1
  to_port           = -1
  protocol          = "ICMP"
  security_group_id = aws_security_group.testvpc_b.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "testvpc_b_egress_all" {
  from_port         = 0
  to_port           = 0
  protocol          = "ALL"
  security_group_id = aws_security_group.testvpc_b.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_instance" "testvpc_b" {
  ami                         = data.aws_ami.ami.id
  instance_type               = "t3.micro"
  source_dest_check           = false
  subnet_id                   = module.testvpc_b.private_subnets[0]
  vpc_security_group_ids      = [aws_security_group.testvpc_b.id]
  key_name                    = aws_key_pair.main.id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.test.id
  user_data                   = <<EOF
#cloud-config
package_update: true
runcmd:
  - yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
  - systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
  - systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
EOF

  root_block_device {
    delete_on_termination = true
  }

  tags = {
    Name = "transitgateway-testvpc-b"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_iam_instance_profile" "test" {
  name_prefix = "transitgateway-test-"
  role        = aws_iam_role.test.id
}

resource "aws_iam_role" "test" {
  name_prefix        = "transitgateway-test-"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "test" {
  role       = aws_iam_role.test.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

output "instance_testvpc_b_private_ip" {
  value = aws_instance.testvpc_b.private_ip
}

output "instance_testvpc_b_id" {
  value = aws_instance.testvpc_b.id
}
