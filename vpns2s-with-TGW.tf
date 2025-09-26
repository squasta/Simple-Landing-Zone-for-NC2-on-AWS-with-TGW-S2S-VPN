

# AWS Transit Gateway
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway
resource "aws_ec2_transit_gateway" "Terra-TGW" {
  description = "NC2 Transit Gateway"
  tags = {
    Name = "NC2-Transit-Gateway"
  }
}


# Define the Customer Gateway representing the on-premises VPN device
# cf. https://registry.Terraform.io/providers/hashicorp/aws/latest/docs/resources/customer_gateway
resource "aws_customer_gateway" "Terra-Customer-GW" {
	ip_address = var.ON_PREM_GATEWAY_IP
	type       = "ipsec.1"
	bgp_asn    = "65000"
	tags = {
		Name = "NC2-Customer-VPN-Gateway-On-Prem"
	}
}

# Create the VPN connection between the Transit Gateway and the Customer Gateway
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_connection 
resource "aws_vpn_connection" "Terra-VPN-Connection" {
	customer_gateway_id = aws_customer_gateway.Terra-Customer-GW.id
  transit_gateway_id  = aws_ec2_transit_gateway.Terra-TGW.id
  type                = aws_customer_gateway.Terra-Customer-GW.type
	static_routes_only  = true   # to propagate on prem routes to AWS Route table 
	tunnel1_preshared_key = var.TUNNEL1_PRESHARED_KEY
	tags = {
		Name = "NC2-VPN-Connection"
	}
}

# A static route to the on-premises network via the VPN connection attached to TGW
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route
resource "aws_ec2_transit_gateway_route" "Terra-TGW-Route-To-On-Prem" {
  destination_cidr_block         = var.ON_PREM_CIDR
  transit_gateway_attachment_id  = aws_vpn_connection.Terra-VPN-Connection.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.Terra-TGW.association_default_route_table_id
}


# Attach the main VPC to the Transit Gateway
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_vpc_attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "Terra-TGW-Attachment" {
  subnet_ids         = [aws_subnet.Terra-Private-Subnet-FVN.id]
  transit_gateway_id = aws_ec2_transit_gateway.Terra-TGW.id
  vpc_id             = aws_vpc.Terra-VPC.id
  tags = {
    Name = "NC2-TGW-Attachment"
  }
}

# A route in the private subnet route table to direct traffic to the Transit Gateway for on-premises CIDR
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route
resource "aws_route" "Terra-Route-To-On-Prem-Via-TGW" {
  route_table_id         = aws_route_table.Terra-Private-Route-Table.id
  destination_cidr_block = var.ON_PREM_CIDR
  transit_gateway_id     = aws_ec2_transit_gateway.Terra-TGW.id
}



# Security group to allow ICMP, RDP and SSH from ON prem CIDR to NC2 AWS VPC
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "Terra-SG-On-Prem" {
  name   = "NC2-SG-On-Prem"
  vpc_id = aws_vpc.Terra-VPC.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ON_PREM_CIDR]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.ON_PREM_CIDR]
  }

  ingress {
    from_port   = -1  # These values allow all ICMP message types and codes, not just specific ones like echo (ping)
    to_port     = -1  # These values allow all ICMP message types and codes, not just specific ones like echo (ping)
    protocol    = "icmp"
    cidr_blocks = [var.ON_PREM_CIDR]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "NC2-SG-On-Prem"
  }
}