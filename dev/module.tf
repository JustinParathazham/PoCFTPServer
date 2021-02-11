data "aws_availability_zones" "available" {
  provider = aws.industrial_shared

  state = "available"
}

data "aws_ec2_transit_gateway" "enterprise_transit_gateway"{
  provider = aws.enterprise_transit

  id = data.terraform_remote_state.shared_edge.outputs.enterprise_transit_gateway_id
}

data "aws_ec2_transit_gateway" "industrial_transit_gateway"{
  provider = aws.industrial_shared

  id = data.terraform_remote_state.shared_edge.outputs.industrial_transit_gateway_id
}

data "aws_ec2_transit_gateway" "rms_transit_gateway"{
  provider = aws.industrial_shared

  id = local.rms_transit_gateway_id
}

module "secrets" {
  source = "../../modules/secrets"

  providers = {
    aws = aws.industrial_shared
  }

  application_code = local.application_code
  index            = 1
  environment      = lower(local.environment)

  secrets_manager_prefix = "administration/enr-infrastructure"

  secrets_recovery_window = local.secrets_recovery_window

  tunnel_configs = local.tunnel_configs

  tags = var.default_tags
}

module "edge_layer" {
  source = "../../modules/edge_layer"

  providers = {
    aws = aws.industrial_shared
  }

  vpc_cidr = local.edge_cidr

  application_code = local.application_code
  index            = 1
  environment      = lower(local.environment)

  industrial_transit_gateway = data.aws_ec2_transit_gateway.industrial_transit_gateway

  pfsense_elastic_ip   = aws_eip.pfsense_appliance_ip
  fortigate_elastic_ip = aws_eip.fortigate_cluster_ip

  internal_landing_subnet_az1_cidr = local.internal_landing_subnet_az1_cidr
  external_landing_subnet_az1_cidr = local.external_landing_subnet_az1_cidr
  internal_landing_subnet_az2_cidr = local.internal_landing_subnet_az2_cidr
  external_landing_subnet_az2_cidr = local.external_landing_subnet_az2_cidr
  private_subnet_az1_cidr          = local.private_subnet_az1_cidr
  private_subnet_az2_cidr          = local.private_subnet_az2_cidr
  public_subnet_az1_cidr           = local.public_subnet_az1_cidr
  public_subnet_az2_cidr           = local.public_subnet_az2_cidr
  ha_mgmt_subnet_az1_cidr          = local.ha_mgmt_subnet_az1_cidr
  ha_mgmt_subnet_az2_cidr          = local.ha_mgmt_subnet_az2_cidr
  ha_sync_subnet_az1_cidr          = local.ha_sync_subnet_az1_cidr
  ha_sync_subnet_az2_cidr          = local.ha_sync_subnet_az2_cidr
  availability_zone_1              = data.aws_availability_zones.available.names[0]
  availability_zone_2              = data.aws_availability_zones.available.names[1]

  tags = var.default_tags

  rms_references     = {
    # RMS Simulator
    (local.rms_simulator_cidr) = module.rms_simulator.transit_gateway,
    # RMS
    (local.rms_cidr) = data.aws_ec2_transit_gateway.rms_transit_gateway
  }
  enr_spoke_vpc_cidr = local.enr_spoke_vpc_cidr
  pf_asset_cidr      = local.pf_asset_cidr
  fg_asset_cidr      = local.fg_asset_cidr

  vpn_gateway_key_pair_name       = local.vpn_gateway_admin_key_pair_name
  vpn_gateway_admin_user          = module.secrets.vpn_gateway_admin_username
  vpn_gateway_admin_private_key   = module.secrets.vpn_gateway_admin_private_key
  vpn_gateway_admin_public_key    = module.secrets.vpn_gateway_admin_public_key
  vpn_gateway_admin_password_hash = module.secrets.vpn_gateway_admin_password_hash
  vpn_gateway_admin_password      = module.secrets.vpn_gateway_admin_password
  vpn_api_key                     = module.secrets.vpn_api_key

  tunnel_configs = local.simulator_tunnel_configs
  asset_endpoints = local.simulator_endpoints

  trusted_source_cidrs = local.trusted_source_cidrs
}

module "enr_spoke" {
  source = "../../modules/enr-spoke"

  providers = {
    aws                    = aws.enr
    aws.industrial_transit = aws.industrial_shared
    aws.enterprise_transit = aws.enterprise_transit
  }

  application_code = "enrf"
  index            = 1
  environment      = lower(local.environment)

  vpc_cidr             = local.enr_spoke_vpc_cidr
  private_subnet_cidrs = [local.enr_spoke_subnet_cidr_az1, local.enr_spoke_subnet_cidr_az2]

  availability_zone_names = data.aws_availability_zones.available.names

  monitoring_cidrs     = local.monitoring_cidrs
  edge_vpc_cidr        = local.edge_cidr
  asset_cidrs          = [local.pf_asset_cidr, local.fg_asset_cidr]


  industrial_transit_gateway = data.aws_ec2_transit_gateway.industrial_transit_gateway
  enterprise_transit_gateway = data.aws_ec2_transit_gateway.enterprise_transit_gateway
  edge_vpc_attachment        = module.enr_spoke.industrial_transit_gateway_attachment

  monitoring_relays_admin_key_pair_name = local.monitoring_relay_key_pair_name
  monitoring_relays_admin_public_key    = module.secrets.relay_admin_public_key
  monitoring_username                   = local.monitoring_username
  monitoring_authorized_key             = module.secrets.monitoring_public_key

  tcp_monitoring_ports = [22, 2222]  # todo: modularize ports
  udp_monitoring_ports = []  # todo: modularize ports

  tags = var.default_tags

  trusted_source_cidrs = local.trusted_source_cidrs
}

module "simulator_secrets" {
  source = "../../modules/simulator-secrets"

  providers = {
    aws = aws.industrial_shared
  }

  application_code = "enrs"
  index            = 1
  environment      = lower(local.environment)

  secrets_manager_prefix = "test/enr-simulators"

  secrets_recovery_window = local.secrets_recovery_window


  tags = var.default_tags
}

module "asset_simulator" {
  for_each = module.secrets.tunnel_configs["ipsec_tunnels"]

  source = "../../modules/asset_simulator"

  # Deploy asset simulator in edge account to ensure sufficient public IPs are available
  providers = {
    aws = aws.industrial_shared
  }

  name             = "Test 1"
  preshared_key    = each.value["psk"]

  vpn_gateway_public_ip   = aws_eip.fortigate_cluster_ip.public_ip
  vpn_admin_password_hash = module.simulator_secrets.vpn_gateway_admin_password_hash
  admin_key_pair_name     = aws_key_pair.asset_simulator_key_pair.key_name
  admin_user              = module.simulator_secrets.vpn_gateway_admin_username
  admin_private_key       = module.simulator_secrets.vpn_gateway_admin_private_key

  vpc_cidr         = each.value["remote_cidr"]
  front_subnet     = cidrsubnet(each.value["remote_cidr"], 1, 0)  # first subnet
  back_subnet      = cidrsubnet(each.value["remote_cidr"], 1, 1)  # second subnet

  # Create one asset simulator for each asset endpoint associated with the VPN tunnel
  endpoint_ids = [
    for endpoint_id, endpoint_config in local.asset_endpoints:
      endpoint_id
      if endpoint_config["vpn_id"] == each.key
  ]

  edge_cidr = local.edge_cidr

  router_ami_id = "ami-07184e4ae40b15459"
  asset_ami_id  = "ami-0f0e9aa0c811cead7"

  application_code = "enrs"
  index            = 1 + index(keys(module.secrets.tunnel_configs["ipsec_tunnels"]), each.key)
  environment      = lower(local.environment)

  trusted_source_cidrs = local.trusted_source_cidrs

  tags     = var.default_tags
}


module "rms_simulator" {
  # Deploy asset simulator in ENR Spoke account to ensure different account from edge
  providers = {
    aws = aws.enr
    aws.edge = aws.industrial_shared
  }

  source = "../../modules/resource_management_system_simulator"

  application_code = "rmss"
  index            = 1
  environment      = lower(local.environment)

  vpc_cidr           = local.rms_simulator_cidr
  edge_cidr          = local.edge_cidr
  asset_cidrs        = [local.pf_asset_cidr, local.fg_asset_cidr]
  enr_spoke_vpc_cidr = local.enr_spoke_vpc_cidr
  ami_id             = "ami-06025825d80cfcbc0"

  admin_key_pair_name = local.simulator_key_pair_name
  admin_public_key    = module.simulator_secrets.vpn_gateway_admin_public_key
  tags                = var.default_tags

  trusted_source_cidrs = local.trusted_source_cidrs

  edge_tgw_attachment = module.edge_layer.rms_tgw_attachment[local.rms_simulator_cidr]
}
