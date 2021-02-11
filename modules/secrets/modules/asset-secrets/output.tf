output "tunnel_configs" {
  description = "Object containing the IPSec tunnels to be created including their PSK"
  value       = {
      ipsec_tunnels = {
        for key, value in data.aws_secretsmanager_secret_version.pre_shared_keys:
        key => merge(var.tunnel_configs.ipsec_tunnels[key], {
          psk    = value.secret_string
          psk_id = value.arn
        })
        if contains(keys(var.tunnel_configs.ipsec_tunnels), key)
      }
  }
}