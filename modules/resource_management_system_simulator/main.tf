# Define specific provider for the industrial transit account

provider "aws" {
  alias = "edge"
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Definition of the RMS VPC

resource "aws_vpc" "rms_vpc" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge({
    Name = "asvc${var.environment}${var.application_code}${format("%02d",var.index)}"
  }, var.tags)
}

# Single subnet

resource "aws_subnet" "rms_subnet" {

  vpc_id                   = aws_vpc.rms_vpc.id
  cidr_block               = var.vpc_cidr
  map_public_ip_on_launch  = true

  tags = merge(
    {
      Name = "assn${var.environment}${var.application_code}${format("%02d", var.index)}"
    },
    var.tags,
  )
}

# Internet Gateway to provide internet access from the VPC.
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.rms_vpc.id

  tags = merge({
    Name = "asig${var.environment}${var.application_code}01"
  },
    var.tags,
  )
}

# Definition of the default route table of the RMS VPC
# This includes routes that are used by the public subnets.

resource "aws_default_route_table" "r" {
  default_route_table_id = aws_vpc.rms_vpc.default_route_table_id

  tags = merge({
    Name = "asrt${var.environment}${var.application_code}01"
  }, var.tags)
}

# Internet Gateway route: Default routes to the internet gateway
# for public internet access

resource "aws_route" "igw_route" {
  route_table_id          = aws_vpc.rms_vpc.default_route_table_id
  destination_cidr_block  = "0.0.0.0/0"
  gateway_id              = aws_internet_gateway.gw.id
}

# Route to edge VPC
resource "aws_route" "edge_route" {
  route_table_id         = aws_vpc.rms_vpc.default_route_table_id
  destination_cidr_block = var.edge_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.rms_transit_gateway.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.rms_vpc_attachment]
}

# Route to the managed assets
resource "aws_route" "asset_route" {
  for_each = toset(var.asset_cidrs)

  route_table_id         = aws_vpc.rms_vpc.default_route_table_id
  destination_cidr_block = each.key
  transit_gateway_id     = aws_ec2_transit_gateway.rms_transit_gateway.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.rms_vpc_attachment]
}

# Route to the ENR Spoke VPC
resource "aws_route" "enr_spoke_route" {
  route_table_id         = aws_vpc.rms_vpc.default_route_table_id
  destination_cidr_block = var.enr_spoke_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.rms_transit_gateway.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.rms_vpc_attachment]
}

resource "aws_security_group" "simulator_group" {
  name = "simulator_group"
  description = "Security group for RMS simulator"
  vpc_id = aws_vpc.rms_vpc.id

  ingress {
    description = "RDP from anywhere"
    from_port = 3389
    to_port = 3389
    protocol = "tcp"
    cidr_blocks = var.trusted_source_cidrs
  }

  ingress {
    description = "SSH from anywhere"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = var.trusted_source_cidrs
  }

  ingress {
    description = "ICMP"
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
  {
    Name = "assg${var.environment}${var.application_code}${format("%02d", var.index)}"
  },
  var.tags,
  )
}

resource "aws_key_pair" "monitoring_relay_admin_key_pair" {
  key_name   = var.admin_key_pair_name
  public_key = var.admin_public_key
}

resource "aws_instance" "simulator" {
  ami           = var.ami_id
  instance_type = var.instance_type

  key_name = aws_key_pair.monitoring_relay_admin_key_pair.key_name

  subnet_id = aws_subnet.rms_subnet.id

  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.simulator_group.id]

  tags = merge(
    {
      Name = "asrs${var.environment}${var.application_code}${format("%02d", var.index)}"
    },
    var.tags,
  )
}

# RMS Transit Gateway
resource "aws_ec2_transit_gateway" "rms_transit_gateway" {
  description = "Transit Gateway allowing interaction with RMS infrastructure"

  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  auto_accept_shared_attachments  = "enable"

  tags = merge({
    Name = "astg${lower(var.environment)}${var.application_code}${format("%02d",var.index)}-rms"
  }, var.tags)
}

resource "aws_ram_resource_share" "rms_transit_gateway" {

  name     = "RMS Transit Gateway"
  allow_external_principals = true

  tags = {
    description = "Transit Gateway allowing interaction with Total IDS ENR infrastructure"
  }
}

resource "aws_ram_resource_association" "rms_transit_gateway" {
  resource_arn       = aws_ec2_transit_gateway.rms_transit_gateway.arn
  resource_share_arn = aws_ram_resource_share.rms_transit_gateway.arn
}

data "aws_caller_identity" "edge_account" {
  provider = aws.edge
}

resource "aws_ram_principal_association" "rms_sender_invite" {
  principal          = data.aws_caller_identity.edge_account.account_id
  resource_share_arn = aws_ram_resource_share.rms_transit_gateway.arn
}

# Add some wait time before accepting request as it can
# takes some minutes to propagate on AWS side
resource "time_sleep" "ram_invite_propagation" {
  create_duration = "120s"

  triggers = {
    # This sets up the dependency on the RAM association
    resource_association = aws_ram_resource_association.rms_transit_gateway.resource_arn
    principal_association = aws_ram_principal_association.rms_sender_invite.resource_share_arn
    resource_share_arn = aws_ram_resource_share.rms_transit_gateway.arn
  }

  depends_on = [
    aws_ram_resource_share.rms_transit_gateway,
    aws_ram_principal_association.rms_sender_invite,
    aws_ram_resource_association.rms_transit_gateway,
  ]
}

resource "aws_ram_resource_share_accepter" "receiver_accept" {
  provider = aws.edge

  share_arn = time_sleep.ram_invite_propagation.triggers["resource_share_arn"]
}

# Wait for TGW to be shared to provide its ID down the line
data "aws_ec2_transit_gateway" "rms_transit_gateway" {
  id = aws_ec2_transit_gateway.rms_transit_gateway.id

  depends_on = [aws_ram_resource_share_accepter.receiver_accept]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "rms_vpc_attachment" {
  subnet_ids         = [aws_subnet.rms_subnet.id]
  transit_gateway_id = aws_ec2_transit_gateway.rms_transit_gateway.id
  vpc_id             = aws_vpc.rms_vpc.id

  transit_gateway_default_route_table_propagation = true

  tags = merge({
    Name = "asat${var.environment}${var.application_code}${format("%02d", var.index)}-rms-attachment"
  }, var.tags)
}

# Routing

# Create routes for asset cidrs
resource "aws_ec2_transit_gateway_route" "rms_asset_route" {
  for_each = toset(var.asset_cidrs)

  destination_cidr_block         = each.key
  transit_gateway_attachment_id  = var.edge_tgw_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.rms_transit_gateway.association_default_route_table_id
}

# Route to ENR Spoke VPC
resource "aws_ec2_transit_gateway_route" "rms_spoke_route" {
  destination_cidr_block         = var.enr_spoke_vpc_cidr
  transit_gateway_attachment_id  = var.edge_tgw_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.rms_transit_gateway.association_default_route_table_id
}
