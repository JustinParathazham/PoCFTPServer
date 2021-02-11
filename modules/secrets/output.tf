output "vpn_gateway_admin_public_key" {
  description = "Public key in OpenSSH format of the VPN gateway admin key pair"
  value       =module.administration_secrets.vpn_gateway_admin_public_key
}

output "vpn_gateway_admin_private_key" {
  description = "Private key in PEM format of the VPN gateway admin key pair"
  value       = module.administration_secrets.vpn_gateway_admin_private_key
}

output "vpn_gateway_admin_username" {
  description = "The admin username for the VPN gateway UI"
  value       = module.administration_secrets.vpn_gateway_admin_username
}

output "vpn_gateway_admin_password" {
  description = "Admin password for the VPN gateway UI"
  value       = module.administration_secrets.vpn_gateway_admin_password
}

output "vpn_gateway_admin_password_hash" {
  description = "Hash (Blowfish cipher) of the admin password for the VPN gateway UI"
  value       = module.administration_secrets.vpn_gateway_admin_password_hash
}

output "relay_admin_public_key" {
  description = "Public key in OpenSSH format of the relay admin key pair"
  value       = module.administration_secrets.relay_admin_public_key
}

output "monitoring_public_key" {
  description = "Public key in OpenSSH format of the monitoring user key pair"
  value       = module.administration_secrets.monitoring_public_key
}

output "vpn_api_key" {
  description = "Key for using the VPN appliance API"
  value       = module.administration_secrets.vpn_api_key
}

output "tunnel_configs" {
  description = "Object containing the IPSec tunnels to be created including their PSK"
  value       = module.asset_secrets.tunnel_configs
}
