module "tgw_main" {
  source      = "github.com/terraform-aws-modules/terraform-aws-transit-gateway.git?ref=v2.9.0"
  name        = "tgw-test"
  description = "tgw-test"
  share_tgw   = false
  vpc_attachments = {
    vpc_b = {
      vpc_id                                          = module.testvpc_b.vpc_id
      subnet_ids                                      = module.testvpc_b.private_subnets
      dns_support                                     = true
      transit_gateway_default_route_table_association = true
      transit_gateway_default_route_table_propagation = true
    }
  }

  tags = {
    Name = "tgw-test"
  }
}

resource "aws_route" "private" {
  for_each               = toset(module.testvpc_b.private_route_table_ids)
  destination_cidr_block = var.testvpc_a_cidr
  route_table_id         = each.key
  transit_gateway_id     = module.tgw_main.ec2_transit_gateway_id
}

resource "aws_ec2_transit_gateway_route" "vpn" {
  destination_cidr_block         = var.testvpc_a_cidr
  transit_gateway_attachment_id  = aws_vpn_connection.testvpn.transit_gateway_attachment_id
  transit_gateway_route_table_id = module.tgw_main.ec2_transit_gateway_association_default_route_table_id
}
