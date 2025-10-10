VPC_NAME="NC2-VPC"
AWS_REGION="eu-west-1"
AWS_AVAILABILITY_ZONE="c"                  # possible values : a,b,c
KEY_PAIR_NAME="my-ssh-key"
VPC_CIDR="172.17.0.0/16"                   # avoid any CIDR that contain 192.168.5.0/24
PUBLIC_SUBNET_CIDR="172.17.0.0/24"         # between /16 and /25. default value /28
PRIVATE_SUBNET_MGMT_CIDR="172.17.1.0/24"   # NC2 cluster nodes subnet. between /16 and /25. default value /25
PRIVATE_SUBNET_PC="172.17.2.0/24"          # Prism Central Subnet. between /16 and /28. default value /28
PRIVATE_SUBNET_FVN="172.17.3.0/24"         # Flow Networking entry subnet. between /16 and /24. default value /24
PRIVATE_SUBNET_TGW="172.17.5.0/24"         # Transit Gateway subnet. between /16 and /25. default value /24
PRIVATE_SUBNET_JUMPBOX="172.17.4.0/24"     # A subnet for one or more jumpbox
WINDOWS_SERVER_2025_ENGLISHFULLBASE_AMI_ID="ami-05e885aafb1fdb4dd"    # this is the AMI ID of Windows Server 2025 in the AWS region 
ENABLE_VPC_ENDPOINT_S3=1                   # Keep this at 1 for optimizing network cost if you are using S3 (cluster hibernate, MST...)
ENABLE_JUMBOX_VM=0                         # Possible values : 0=no, 1=yes
ENABLE_NLB_JUMBOX_VM=0                     # Possible values : 0=no, 1=yes
ON_PREM_CIDR="10.0.0.0/16"               # should not overlap with VPC_CIDR.  CIDR of on premises networks
ON_PREM_GATEWAY_IP="1.2.3.4"               # Public IP of on-premises VPN Gateway. If behind a NAT device, use the Public IP of the NAT device
TUNNEL1_PRESHARED_KEY="abcdefgh"           # in AWS VPN Connection, can only contain alphanumeric, period and underscore characters
