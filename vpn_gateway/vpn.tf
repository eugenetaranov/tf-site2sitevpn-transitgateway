resource "aws_customer_gateway" "main" {
  bgp_asn    = 65000
  ip_address = aws_instance.testvpc_a.public_ip
  type       = "ipsec.1"

  tags = {
    Name = "vpngw-test"
  }
}

resource "aws_vpn_gateway" "vgw" {
  tags = {
    Name = "vpngw-test"
  }
}

resource "aws_vpn_gateway_attachment" "vpc_b" {
  vpc_id         = module.testvpc_b.vpc_id
  vpn_gateway_id = aws_vpn_gateway.vgw.id
}

resource "aws_vpn_connection" "testvpn" {
  vpn_gateway_id      = aws_vpn_gateway.vgw.id
  customer_gateway_id = aws_customer_gateway.main.id
  type                = "ipsec.1"
  static_routes_only  = true
  tags = {
    Name = "vpngw-test"
  }
}

resource "aws_route" "private" {
  for_each = toset(module.testvpc_b.private_route_table_ids)

  destination_cidr_block = var.testvpc_a_cidr
  route_table_id         = each.key
  gateway_id             = aws_vpn_gateway.vgw.id
}

resource "aws_vpn_connection_route" "vpc_a" {
  destination_cidr_block = var.testvpc_a_cidr
  vpn_connection_id      = aws_vpn_connection.testvpn.id
}

output "configuration" {
  sensitive = true
  value     = <<EOF
ssh -o StrictHostKeyChecking=no -i id_rsa -o UserKnownHostsFile=/dev/null ec2-user@${aws_instance.testvpc_a.public_ip}

sudo -i

cat <<END >/etc/ipsec.d/aws.conf
conn Tunnel1
    authby=secret
    auto=start
    left=%defaultroute
    leftid=${aws_instance.testvpc_a.public_ip}
    right=${aws_vpn_connection.testvpn.tunnel1_address}
    type=tunnel
    ikelifetime=8h
    keylife=1h
    phase2alg=aes128-sha1;modp1024
    ike=aes128-sha1;modp1024
    keyingtries=%forever
    keyexchange=ike
    leftsubnet=${var.testvpc_a_cidr}
    rightsubnet=${var.testvpc_b_cidr}
    dpddelay=10
    dpdtimeout=30
    dpdaction=restart_by_peer
END

cat <<END >/etc/ipsec.d/aws.secrets
${aws_instance.testvpc_a.public_ip} ${aws_vpn_connection.testvpn.tunnel1_address}: PSK "${aws_vpn_connection.testvpn.tunnel1_preshared_key}"
END

systemctl start ipsec

ping ${aws_instance.testvpc_b.private_ip}
>>>
EOF
}
