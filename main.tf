
# Nutanix NC2  pre requisite
# https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Clusters-AWS:aws-clusters-aws-infrastructure-deployment-c.html

# https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2202-NC2-AWS-Networking:configuring-nutanix-cloud-clusters-on-amazon-web-services.html 
# https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Clusters-AWS:aws-clusters-aws-getting-started-c.html
# NC2 CIDR requirements
# You must use the following range of IP addresses for the VPCs and subnets:
# VPC: between /16 and /25, including both
#     Private management subnet: /16 and /25, including both
#     Public subnet: /16 and /25 including both
#     UVM subnets and FlowNetwork: /16 and /25, including both
#         UVM subnet sizing would depend on the number of UVMs that would need to be deployed. 
#         NC2 supports the network CIDR sizing limits enforced by AWS
# Please don't overlap AWS CIDR with your on-premises network CIDR



# An AWS VPC
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
# Ensure you do not use 192.168.5.0/24 CIDR for the VPC to deploy NC2 on AWS
# All Nutanix nodes use that CIDR to communicate between the CVM and the installed hypervisor
# The recommended CIDR range is between /16 and /25
# NC2 supports the network CIDR sizing limits enforced by AWS.
# Ensure the CIDR block is within the private IP ranges

resource "aws_vpc" "Terra-VPC" {

  cidr_block       = var.VPC_CIDR  # CIDR requirements: /16 and /25 including both
  instance_tenancy = "default"
  # if you want to use internal proxy for your NC2 cluster, you need to enable DNS hostnames
  # and DNS support. In any case, NC2 documentation recommends to enable these settings.
  # cf. https://docs.aws.amazon.com/vpc/latest/userguide/vpc-dns.html#vpc-dns-support
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = join("", [var.VPC_NAME,"-",var.AWS_REGION])
  }
}


# NC2 Public Subnet
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet

resource "aws_subnet" "Terra-Public-Subnet" {
  vpc_id                  = aws_vpc.Terra-VPC.id
  cidr_block              = var.PUBLIC_SUBNET_CIDR  # CIDR requirements: /16 and /23 including both
                                            # a /28 CIDR should be enough. It's the value used if VPC is created through NC2 portal wizard
  availability_zone       = join("", [var.AWS_REGION,var.AWS_AVAILABILITY_ZONE])                
  map_public_ip_on_launch = true

  tags = {
    Name = join("", ["NC2-PublicSubnet-",var.AWS_REGION,var.AWS_AVAILABILITY_ZONE])
  }
}


# A private subnet for cluster management traffic
# Shared across multiple clusters for centralized management (except if you have a NC2 cluster with FVN)
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet 

resource "aws_subnet" "Terra-Private-Subnet-Mngt" {
  vpc_id                  = aws_vpc.Terra-VPC.id
  cidr_block              = var.PRIVATE_SUBNET_MGMT_CIDR   # CIDR requirements: /16 and /25 including both
                                             # a /25 CIDR should be enough. It's the value used if VPC is created through NC2 portal wizard
  availability_zone       = join("", [var.AWS_REGION,var.AWS_AVAILABILITY_ZONE])                 

  tags = {
    Name = join("", ["NC2-PrivateMgntSubnet-",var.AWS_REGION,var.AWS_AVAILABILITY_ZONE])
  }
}


# One private subnet for Prism Central VM and MST
# Dedicated to Prism Central for management and orchestration purposes.
# Subnet used for Prism Central and Multicloud Snapshot Technology (MST) is considered as VLAN network in Prism Central / Prism Element
# cf. https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Clusters-AWS:aws-cluster-protect-requirements-c.html
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet  

resource "aws_subnet" "Terra-Private-Subnet-PC" {
  vpc_id                  = aws_vpc.Terra-VPC.id
  cidr_block              = var.PRIVATE_SUBNET_PC  # CIDR requirements: /16 and /25 including both
  availability_zone       = join("", [var.AWS_REGION,var.AWS_AVAILABILITY_ZONE])                      

  tags = {
    ## join function https://developer.hashicorp.com/terraform/language/functions/join
    Name = join("", ["NC2-PrivateSubnet-PC-",var.AWS_REGION,var.AWS_AVAILABILITY_ZONE])
  }
}


# One subnet for Flow Virtual Networking
# Subnets used for Flow Virtual Networking (FVN)
# This subnet cannot be shared and only one cluster can be deployed per VPC with Flow Virtual Networking
# https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Clusters-AWS:aws-aws-create-resources-manual-c.html
# https://www.nutanix.com/blog/flow-virtual-networking-is-now-supported-for-nutanix-cloud-clusters-on-aws 
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet  

resource "aws_subnet" "Terra-Private-Subnet-FVN" {
  vpc_id                  = aws_vpc.Terra-VPC.id
  cidr_block              = var.PRIVATE_SUBNET_FVN  # CIDR requirements: /16 and /25 including both
  availability_zone       = join("", [var.AWS_REGION,var.AWS_AVAILABILITY_ZONE])                      

  tags = {
    ## join function https://developer.hashicorp.com/terraform/language/functions/join
    Name = join("", ["NC2-PrivateSubnet-FVN-",var.AWS_REGION,var.AWS_AVAILABILITY_ZONE])
  }
}



# One subnet for Transit Gateway attachment
# This subnet cannot be shared and only one cluster can be deployed per VPC with Transit Gateway
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet  

resource "aws_subnet" "Terra-Private-Subnet-TGW" {
  vpc_id                  = aws_vpc.Terra-VPC.id
  cidr_block              = var.PRIVATE_SUBNET_TGW  # CIDR requirements: /16 and /25 including both
  availability_zone       = join("", [var.AWS_REGION,var.AWS_AVAILABILITY_ZONE])                      

  tags = {
    ## join function https://developer.hashicorp.com/terraform/language/functions/join
    Name = join("", ["NC2-PrivateSubnet-TGW-",var.AWS_REGION,var.AWS_AVAILABILITY_ZONE])
  }
}



# Internet Gateway
# To establish communication between your VPC and the internet
# Instances in the public subnet can communicate directly with the Internet
# https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "Terra-Internet-Gateway" {
  vpc_id = aws_vpc.Terra-VPC.id
  tags = {
    Name = "NC2-InternetGateway"
  }
}


# Elastic IP resource (EIP) - mandatory for AWS NAT Gateway
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip
resource "aws_eip" "Terra-EIP" {
  domain   = "vpc"

  tags = {
    Name = "NC2-EIP"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.Terra-Internet-Gateway]
}


# NAT Gateway
# You can use a NAT gateway so that instances in a private subnet can connect to services
#  outside your VPC but external services cannot initiate a connection with those instances
# cf. https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway
resource "aws_nat_gateway" "Terra-AWS-NAT-GW" {
  allocation_id     = aws_eip.Terra-EIP.id
  subnet_id         = aws_subnet.Terra-Public-Subnet.id
  connectivity_type = "public"
  tags = {
    Name = "NC2-NAT-GW"
  }
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.Terra-Internet-Gateway]

}


# Route Table for Public Subnet
# The route table associated with the public subnet has a default route (0.0.0.0/0)
# pointing to the Internet Gateway (IGW)
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table

resource "aws_route_table" "Terra-Public-Route-Table" {
  vpc_id = aws_vpc.Terra-VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Terra-Internet-Gateway.id
  }

  tags = {
    Name = "NC2-Route-Table-Public"
  }
}


# Route Table Association for Public Subnet
# This route table is associated with the public subnet, enabling instances within
# this subnet to have direct internet access
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "Terra-Public-Route-Table-Association" {
  subnet_id      = aws_subnet.Terra-Public-Subnet.id
  route_table_id = aws_route_table.Terra-Public-Route-Table.id
}


# Route Table for Private Subnet(s)
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
# this is the route table for the private subnets, to go to on-premises network or Internet 
# (communication of cluster with NC2 portal)
# Private Subnets that do not have direct internet access
# Instances in these subnets can communicate with the internet through a NAT gateway.

resource "aws_route_table" "Terra-Private-Route-Table" {
  vpc_id = aws_vpc.Terra-VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.Terra-AWS-NAT-GW.id
  }

  # this block should not be useful because we propagate VPN Gateway routes to the private route table
  # # Route to on-premises network via VPN
  # route {
  #   cidr_block = var.ON_PREM_CIDR
  #   gateway_id = aws_vpn_gateway.Terra-VPN-GW.id
  # }

  tags = {
    Name = "NC2-Route-Table-Private"
  }
}


# Route Table Association for Private Subnet Management
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "Terra-Private-Route-Table-Association-Mngt" {
  subnet_id      = aws_subnet.Terra-Private-Subnet-Mngt.id
  route_table_id = aws_route_table.Terra-Private-Route-Table.id
}


# Route Table Association for Private Subnet PC
resource "aws_route_table_association" "Terra-Private-Route-Table-Association-PC" {
  subnet_id      = aws_subnet.Terra-Private-Subnet-PC.id
  route_table_id = aws_route_table.Terra-Private-Route-Table.id
}


# Route Table Association for Private Subnet FVN
resource "aws_route_table_association" "Terra-Private-Route-Table-Association-FVN" {
  subnet_id      = aws_subnet.Terra-Private-Subnet-FVN.id
  route_table_id = aws_route_table.Terra-Private-Route-Table.id
}

# Main route table association for VPC (update 8 october 2025)
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/main_route_table_association
# This resource is used to associate the main route table with the VPC.
# By default, each VPC has a main route table that controls the routing for all sub
# nets that are not explicitly associated with any other route table.
# In this case, we are associating the main route table with the VPC created earlier
resource "aws_main_route_table_association" "a" {
  vpc_id         = aws_vpc.Terra-VPC.id
  route_table_id = aws_route_table.Terra-Private-Route-Table.id
}



### If there is a Web proxy configured #################
# https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Clusters-AWS:aws-aws-clusters-vpc-endpoints-for-s3-c.html
# AWS VPC private endpoints for S3 and EC2 services must be configured when using a proxy server 
# to communicate with the NC2 console.
# These endpoints can connect to AWS Services privately from your VPC without going through the
# public Internet.


# VPC Endpoint for S3
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint
resource "aws_vpc_endpoint" "Terra-VPC-Endpoint-S3" {
  count        = var.ENABLE_VPC_ENDPOINT_S3
  vpc_id       = aws_vpc.Terra-VPC.id
  # The VPC endpoint for S3 must be in the same region as the VPC
  service_name = join("", ["com.amazonaws.",var.AWS_REGION,".s3"])    # ex: "com.amazonaws.us-west-2.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [aws_route_table.Terra-Private-Route-Table.id]
  tags = {
    Environment = "test",
    Name        = "NC2-S3-VPC-Endpoint"
  }
}

# VPC Interface Endpoint for EC2
#  Interface type endpoints cannot function without being assigned to a subnet.
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint
# SUPER IMPORTANT: If you are using an EC2 private endpoint that NC2 did not create, you must manually edit that endpoint
# to add the appropriate security rule while cluster deployment is in progress; otherwise, cluster creation will fail.
# You must add the security rule to the EC2 endpoint after the cluster’s internal management security group has been generated 
# AND before the bare-metal instances are provisioned; otherwise, cluster deployment will fail.
# Sources : https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Clusters-AWS:aws-aws-clusters-vpc-endpoints-for-s3-c.html
# resource "aws_vpc_endpoint" "ec2" {
#   vpc_id            = aws_vpc.Terra-VPC.id
#   service_name      = join("", ["com.amazonaws.",var.AWS_REGION,".ec2"])   # ex: "com.amazonaws.us-west-2.ec2"
#   vpc_endpoint_type = "Interface"
#   subnet_ids = [aws_subnet.Terra-Private-Subnet-Mngt.id]
#     security_group_ids = [aws_security_group.sg1.id]
#     tags = {
#     Environment = "test",
#     Name        = "NC2-EC2-VPC-Endpoint"
#   }
# }

###################################################################

