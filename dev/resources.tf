resource "aws_eip" "pfsense_appliance_ip" {
  provider = aws.industrial_shared

  vpc      = true

  tags = {
    Name = "pfSense IP"
  }
}

resource "aws_eip" "fortigate_cluster_ip" {
  provider = aws.industrial_shared

  vpc      = true

  tags = {
    Name = "FortiGate Cluster IP"
  }
}

resource "aws_key_pair" "asset_simulator_key_pair" {
  provider = aws.industrial_shared

  key_name   = local.simulator_key_pair_name
  public_key = module.simulator_secrets.vpn_gateway_admin_public_key
}