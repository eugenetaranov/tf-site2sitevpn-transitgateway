resource "aws_customer_gateway" "testvpn" {
  bgp_asn    = 65000
  ip_address = aws_instance.testvpc_a.public_ip
  type       = "ipsec.1"

  tags = {
    Name = "testvpn"
  }
}

resource "aws_vpn_connection" "testvpn" {
  customer_gateway_id = aws_customer_gateway.testvpn.id
  transit_gateway_id  = module.tgw_main.ec2_transit_gateway_id
  type                = "ipsec.1"
  static_routes_only  = true

  tags = {
    Name = "testvpn"
  }
}
