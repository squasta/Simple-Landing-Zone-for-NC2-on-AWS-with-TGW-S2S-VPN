
# One subnet for Jumpbox VM(s) to access the cluster / prism central and prism element
resource "aws_subnet" "Terra-Private-Subnet-Jumpbox" {
  count               = var.ENABLE_JUMBOX_VM
  vpc_id                  = aws_vpc.Terra-VPC.id
  cidr_block              = var.PRIVATE_SUBNET_JUMPBOX  # CIDR requirements: /16 and /25 including both
  availability_zone       = join("", [var.AWS_REGION,var.AWS_AVAILABILITY_ZONE])                      

  tags = {
    ## join function https://developer.hashicorp.com/terraform/language/functions/join
    Name = join("", ["NC2-PrivateSubnet-Jumbox-",var.AWS_REGION,var.AWS_AVAILABILITY_ZONE])
  }
}


# Route Table Association for Private Subnet Jumpbox
resource "aws_route_table_association" "Terra-Private-Route-Table-Association-Jumbox" {
  count          = var.ENABLE_JUMBOX_VM
  subnet_id      = aws_subnet.Terra-Private-Subnet-Jumpbox[0].id
  route_table_id = aws_route_table.Terra-Private-Route-Table.id
}


data "aws_ami" "Terra-Windows_Latest" {
  count       = var.ENABLE_JUMBOX_VM
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2025-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_instance" "Terra-Jumbox-Windows-Server" {
    # Change to a valid Windows Server AMI ID for your region
    # to get latest Windows Server AMI ID, visit https://aws.amazon.com/windows/ and click on "Launch instance"
    # aws ec2 describe-images --region eu-central-1 --owners amazon --filters "Name=name,Values=Windows_Server-2022-English-Full-Base-*" "Name=state,Values=available" --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" --output text
    count         = var.ENABLE_JUMBOX_VM
    # ami           = var.WINDOWS_SERVER_2025_ENGLISHFULLBASE_AMI_ID   
    ami          = data.aws_ami.Terra-Windows_Latest[0].id
    instance_type = "t3.medium"     # t3.medium has 8 GB of RAM

    subnet_id = aws_subnet.Terra-Private-Subnet-Jumpbox[0].id

    tags = {
        Name = "WindowsServerJumbox-NC2"
    }

    key_name = var.KEY_PAIR_NAME

    # user_data = <<-EOF
    #                         <powershell>
    #                         # Add any custom PowerShell script you want to run on startup
    #                         </powershell>
    #                         EOF

  # Do not replace the instance just because a newer AMI becomes "latest"
  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_security_group" "Terra-Jumbox-sg" {
    count       = var.ENABLE_JUMBOX_VM
    name        = "Jumbox-windows_sg"
    description = "Allow RDP traffic to Jumpbox"
    vpc_id      = aws_vpc.Terra-VPC.id

    ingress {
        from_port   = 3389
        to_port     = 3389
        protocol    = "tcp"
        # cidr_blocks = ["0.0.0.0/0"] # Adjust CIDR block as needed for security
        cidr_blocks = ["192.146.154.3/32"] # Adjust CIDR block as needed for security
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_network_interface_sg_attachment" "Terra-sg-attachment" {
    count                = var.ENABLE_JUMBOX_VM
    security_group_id    = aws_security_group.Terra-Jumbox-sg[0].id
    network_interface_id = aws_instance.Terra-Jumbox-Windows-Server[0].primary_network_interface_id
}


# Expose Jumbox to the Internet through an AWS Network Load Balancer (NLB)

# Create a Network Load Balancer (NLB)
resource "aws_lb" "Terra-NLB-Jumbox" {
  count              = var.ENABLE_NLB_JUMBOX_VM
  name               = "NLB-Jumbox"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.Terra-Public-Subnet.id]
  security_groups    = [aws_security_group.Terra-Jumbox-sg[0].id]

  tags = {
    Name = "NLB-Jumbox"
  }
}

# Create a Target Group for the EC2 instance
resource "aws_lb_target_group" "Terra-LB-Target-Group-Jumbox" {
  count       = var.ENABLE_NLB_JUMBOX_VM
  name        = "rdp-target-group"
  port        = 3389
  protocol    = "TCP"
  vpc_id      = aws_vpc.Terra-VPC.id
  target_type = "instance"
  health_check {
    protocol = "TCP"
  }
}

# Attach the EC2 instance to the Target Group
resource "aws_lb_target_group_attachment" "Terra-Target-Group-Attachment-jumbox" {
  count          = var.ENABLE_NLB_JUMBOX_VM
  target_group_arn = aws_lb_target_group.Terra-LB-Target-Group-Jumbox[0].arn
  target_id        = aws_instance.Terra-Jumbox-Windows-Server[0].id
  port             = 3389
}

# Create a Listener for the NLB to forward RDP traffic
resource "aws_lb_listener" "nlb_listener" {
  count             = var.ENABLE_NLB_JUMBOX_VM
  load_balancer_arn = aws_lb.Terra-NLB-Jumbox[0].arn
  port              = 3389
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Terra-LB-Target-Group-Jumbox[0].arn
  }
}



# output "Jumbox-IP-External-NLB" {
#   value = aws_lb.Terra-NLB-Jumbox[0].dns_name
# }