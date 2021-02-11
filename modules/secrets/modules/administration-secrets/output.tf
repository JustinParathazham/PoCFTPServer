output "vpn_gateway_admin_public_key" {
  description = "Public key in OpenSSH format of the VPN gateway admin key pair"
  value       = jsondecode(data.aws_secretsmanager_secret_version.vpn_gateway_admin.secret_string)["public_key"]
}

output "vpn_gateway_admin_private_key" {
  description = "Private key in PEM format of the VPN gateway admin key pair"
  value       = jsondecode(data.aws_secretsmanager_secret_version.vpn_gateway_admin.secret_string)["private_key"]
}

output "vpn_gateway_admin_username" {
  description = "The admin username for the VPN gateway UI"
  value       = jsondecode(data.aws_secretsmanager_secret_version.vpn_gateway_admin_password.secret_string)["username"]
}

output "vpn_gateway_admin_password" {
  description = "Admin password for the VPN gateway UI"
  value       = jsondecode(data.aws_secretsmanager_secret_version.vpn_gateway_admin_password.secret_string)["password"]
}

output "vpn_gateway_admin_password_hash" {
  description = "Hash (Blowfish cipher) of the admin password for the VPN gateway UI"
  value       = null_resource.vpn_gateway_admin_password_hash.triggers["hash"]
}

output "relay_admin_public_key" {
  description = "Public key in OpenSSH format of the relay admin key pair"
  value       = jsondecode(data.aws_secretsmanager_secret_version.relay_admin.secret_string)["public_key"]
}

output "monitoring_public_key" {
  description = "Public key in OpenSSH format of the monitoring user key pair"
  value       = jsondecode(data.aws_secretsmanager_secret_version.monitoring_user.secret_string)["public_key"]
}

output "vpn_api_key" {
  description = "Key for using the VPN appliance API"
  value       = data.aws_secretsmanager_secret_version.vpn_api_key.secret_string
}
