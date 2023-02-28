resource "aws_customer_gateway" "main" {
  bgp_asn    = 65000
  ip_address = aws_instance.testvpc_a.public_ip
  type       = "ipsec.1"

  tags = {
    Name = "tgw-test"
  }
}

resource "aws_vpn_connection" "testvpn" {
  customer_gateway_id = aws_customer_gateway.main.id
  transit_gateway_id  = module.tgw_main.ec2_transit_gateway_id
  type                = "ipsec.1"
  static_routes_only  = true

  tags = {
    Name = "tgw-test"
  }
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
