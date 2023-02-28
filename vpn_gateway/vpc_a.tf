module "testvpc_a" {
  name                 = "vpngw-testvpc-a"
  source               = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v3.19.0"
  cidr                 = var.testvpc_a_cidr
  azs                  = [for az in var.az : format("%s%s", var.region, az)]
  public_subnets       = [cidrsubnet(var.testvpc_a_cidr, 9, 0), cidrsubnet(var.testvpc_a_cidr, 9, 1), cidrsubnet(var.testvpc_a_cidr, 9, 2)]
  private_subnets      = [cidrsubnet(var.testvpc_a_cidr, 9, 10), cidrsubnet(var.testvpc_a_cidr, 9, 11), cidrsubnet(var.testvpc_a_cidr, 9, 12)]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
}

// ec2
resource "aws_security_group" "testvpc_a" {
  name_prefix = "vpngw-testvpc-a"
  vpc_id      = module.testvpc_a.vpc_id
}

resource "aws_security_group_rule" "testvpc_a_ingress_ssh" {
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  security_group_id = aws_security_group.testvpc_a.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "testvpc_a_ingress_icmp" {
  from_port         = -1
  to_port           = -1
  protocol          = "ICMP"
  security_group_id = aws_security_group.testvpc_a.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "testvpc_a_ingress_4500_udp" {
  from_port         = 4500
  to_port           = 4500
  protocol          = "UDP"
  security_group_id = aws_security_group.testvpc_a.id
  type              = "ingress"
  cidr_blocks = [
    //    format("%s/32", aws_customer_gateway.testvpn.ip_address),
    "0.0.0.0/0",
  ]
}

resource "aws_security_group_rule" "testvpc_a_egress_all" {
  from_port         = 0
  to_port           = 0
  protocol          = "ALL"
  security_group_id = aws_security_group.testvpc_a.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_instance" "testvpc_a" {
  ami                         = data.aws_ami.ami.id
  instance_type               = "t3.micro"
  source_dest_check           = false
  subnet_id                   = module.testvpc_a.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.testvpc_a.id]
  key_name                    = aws_key_pair.main.id
  associate_public_ip_address = true
  user_data                   = <<EOF
#cloud-config
repo_upgrade: none
packages:
  - tmux
  - openswan
write_files:
  - path: /etc/sysctl.conf
    content: |
      net.ipv4.ip_forward = 1
      net.ipv4.conf.default.rp_filter = 0
      net.ipv4.conf.default.accept_source_route = 0
  - path: /etc/ipsec.d/aws.conf
    content:
  - path: /etc/ipsec.d/aws.secrets
    content:
run_commands:
  - sysctl -p
EOF


  root_block_device {
    delete_on_termination = true
  }

  tags = {
    Name = "vpngw-testvpc-a"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

output "instance_testvpc_a_public_ip" {
  value = aws_instance.testvpc_a.public_ip
}

output "instance_testvpc_a_private_ip" {
  value = aws_instance.testvpc_a.private_ip
}

output "instance_testvpc_a_id" {
  value = aws_instance.testvpc_a.id
}
