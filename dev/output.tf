output "vpc_cidr" {
  description = "CIDR of the edge VPC"
  value       = module.edge_layer.vpc.cidr_block
}

output "simulator_endpoints" {
  value = local.simulator_endpoints
}

output "simulator_tunnel_configs" {
  value = {
    ipsec_tunnels = {
      for tunnel_id, tunnel_config in local.simulator_tunnel_configs["ipsec_tunnels"]:
            # Replace peer IP with router simulator public IP
            tunnel_id => {
              for this_key, this_value in tunnel_config:
                this_key => this_value
                if this_key != "psk"
            }
    }
  }
}

output "fortigate_cluster_ip" {
  description = "Public IP of the public interface of the FortiGate cluster."
  value = aws_eip.fortigate_cluster_ip.public_ip
}

output "active_fortigate_management_ip" {
  description = "Public IP of the management interface of the active FortiGate cluster instance."
  value = module.edge_layer.active_fortigate_management_ip
}
