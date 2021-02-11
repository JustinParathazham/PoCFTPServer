locals {
  environment      = "D"
  application_code = "enrf"

  monitoring_cidrs               = ["10.94.23.0/24"]
  monitoring_username            = "monitoring"
  monitoring_relay_key_pair_name = "monitoring-dev-key"

  edge_cidr               = "10.156.32.0/23"
  public_subnet_az1_cidr  = "10.156.32.0/26"
  public_subnet_az2_cidr  = "10.156.32.64/26"
  private_subnet_az1_cidr = "10.156.33.0/26"
  private_subnet_az2_cidr = "10.156.33.64/26"
  ha_sync_subnet_az1_cidr = "10.156.32.160/28"
  ha_sync_subnet_az2_cidr = "10.156.32.176/28"
  ha_mgmt_subnet_az1_cidr = "10.156.32.128/28"
  ha_mgmt_subnet_az2_cidr = "10.156.32.144/28"

  internal_landing_subnet_az1_cidr = "10.156.33.128/28"
  external_landing_subnet_az1_cidr = "10.156.33.144/28"  # todo: exchange with internal_landing_subnet_az2_cidr for consistency with documentation
  internal_landing_subnet_az2_cidr = "10.156.33.160/28"  # todo: exchange with external_landing_subnet_az1_cidr for consistency with documentation
  external_landing_subnet_az2_cidr = "10.156.33.176/28"

  vpn_gateway_admin_key_pair_name = "enr-vpn-gateway-dev"

  pf_asset_cidr = "10.156.34.0/27"
  fg_asset_cidr = "10.156.35.0/24"

  enr_spoke_vpc_cidr        = "10.156.0.0/23"
  enr_spoke_subnet_cidr_az1 = "10.156.0.0/24"
  enr_spoke_subnet_cidr_az2 = "10.156.1.0/24"

  secrets_recovery_window = 0  # No secrets recovery

  asset_configuration = yamldecode(file("asset_configuration.yml"))
  tunnel_configs  = local.asset_configuration["tunnel_configurations"]
  asset_endpoints = local.asset_configuration["asset_endpoints"]

  rms_transit_gateway_id = "tgw-0961bdf6b24321dd6"
  rms_cidr = "10.45.0.0/20"

  trusted_source_cidrs = [
    "79.141.85.58/32",      # BearingPoint Geneva Office
    "178.238.164.28/32",    # Max Carrel
    "195.176.149.172/32",   # ITR: Internet Business
    "62.192.0.92/32",       # PLO  Internet Browsing
    "217.169.131.50/32",    # PLO Internet Business
    "217.169.131.68/32",    # WTC Wifi"
  ]
}

# Simulator specific variables
locals {
  rms_simulator_cidr = "10.20.0.0/24"

  simulator_key_pair_name = "simulator-dev-key"

  # Refactor tunnel & endpoint configuration for simulators
  simulator_tunnel_configs = {
    ipsec_tunnels = {
      for tunnel_id, tunnel_config in module.secrets.tunnel_configs["ipsec_tunnels"]:
            # Replace peer IP with router simulator public IP
            tunnel_id => merge(tunnel_config,
                               {peer_ip=module.asset_simulator[tunnel_id].public_ip})
    }
  }
  simulator_endpoints = {
    for endpoint_id, endpoint_config in local.asset_endpoints:
      # Replace asset private IP with asset simulator IP
      endpoint_id => merge(endpoint_config,
                           {target_ip=module.asset_simulator[endpoint_config["vpn_id"]].asset_private_ips[endpoint_id]})
      if contains(keys(local.simulator_tunnel_configs.ipsec_tunnels), endpoint_config["vpn_id"])
  }
}