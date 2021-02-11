# VPN admin

resource "tls_private_key" "vpn_gateway_admin" {
  algorithm   = "RSA"
  rsa_bits    = 2048
}

resource "aws_secretsmanager_secret" "vpn_gateway_admin" {
  name = "${var.secrets_manager_prefix}/${lower(var.environment)}/vpn-gateway-admin-key"

  recovery_window_in_days = var.secrets_recovery_window

  tags = merge({
    Name        = "assm${var.environment}${var.application_code}${format("%02d",var.index)}-vpn-gateway-admin-key",
    description = "Private key of the VPN gateway"
  }, var.tags)
}

resource "aws_secretsmanager_secret_version" "vpn_gateway_admin" {
  secret_id     = aws_secretsmanager_secret.vpn_gateway_admin.id
  secret_string = jsonencode({
    private_key = tls_private_key.vpn_gateway_admin.private_key_pem,
    public_key = tls_private_key.vpn_gateway_admin.public_key_openssh
  })
}

data "aws_secretsmanager_secret_version" "vpn_gateway_admin" {
  secret_id = aws_secretsmanager_secret.vpn_gateway_admin.id

  depends_on = [aws_secretsmanager_secret_version.vpn_gateway_admin]
}

resource "random_password" "vpn_gateway_admin_password" {
  length = 30
  special = true
}

resource "aws_secretsmanager_secret" "vpn_gateway_admin_password" {
  name = "${var.secrets_manager_prefix}/${lower(var.environment)}/vpn-gateway-admin"

  recovery_window_in_days = var.secrets_recovery_window

  tags = merge({
    Name        = "assm${var.environment}${var.application_code}${format("%02d",var.index)}-vpn-gateway-admin",
    description = "Credentials of the VPN gateway UI admin"
  }, var.tags)
}

resource "aws_secretsmanager_secret_version" "vpn_gateway_admin_password" {
  secret_id     = aws_secretsmanager_secret.vpn_gateway_admin_password.id
  secret_string = jsonencode({
    username = local.vpn_gateway_admin_username
    password = random_password.vpn_gateway_admin_password.result
  })
}

data "aws_secretsmanager_secret_version" "vpn_gateway_admin_password" {
  secret_id = aws_secretsmanager_secret.vpn_gateway_admin_password.id

  depends_on = [aws_secretsmanager_secret_version.vpn_gateway_admin_password]
}

# trick to extract bcrypt hash of password without triggering
# a refresh due to random salt
# Seen in https://github.com/hashicorp/terraform-provider-random/issues/102
resource "null_resource" "vpn_gateway_admin_password_hash" {
  triggers = {
    password = jsondecode(data.aws_secretsmanager_secret_version.vpn_gateway_admin_password.secret_string)["password"]
    hash = bcrypt(jsondecode(data.aws_secretsmanager_secret_version.vpn_gateway_admin_password.secret_string)["password"])
  }

  lifecycle {
    ignore_changes = [triggers["hash"]]
  }
}

# Monitoring administration-secrets

resource "tls_private_key" "monitoring_user_key" {
  algorithm   = "RSA"
  rsa_bits    = 2048
}

resource "tls_private_key" "relay_admin_key" {
  algorithm   = "RSA"
  rsa_bits    = 2048
}

resource "aws_secretsmanager_secret" "monitoring_user" {
  name = "${var.secrets_manager_prefix}/${lower(var.environment)}/monitoring-user"

  recovery_window_in_days = var.secrets_recovery_window

  tags = merge({
    Name        = "assm${var.environment}${var.application_code}${format("%02d",var.index)}-monitoring-user",
    description = "Private key of the monitoring user"
  }, var.tags)
}

resource "aws_secretsmanager_secret_version" "monitoring_user" {
  secret_id     = aws_secretsmanager_secret.monitoring_user.id
  secret_string = jsonencode({
    private_key = tls_private_key.monitoring_user_key.private_key_pem
    public_key  = tls_private_key.monitoring_user_key.public_key_openssh
  })
}

data "aws_secretsmanager_secret_version" "monitoring_user" {
  secret_id = aws_secretsmanager_secret.monitoring_user.id

  depends_on = [aws_secretsmanager_secret_version.monitoring_user]
}

resource "aws_secretsmanager_secret" "relay_admin" {
  name = "${var.secrets_manager_prefix}/${lower(var.environment)}/relay-admin"

  recovery_window_in_days = var.secrets_recovery_window

  tags = merge({
    Name        = "assm${var.environment}${var.application_code}${format("%02d",var.index+1)}-relay-admin"
    description = "Private key of the monitoring relay admin"
  }, var.tags)
}

resource "aws_secretsmanager_secret_version" "relay_admin" {
  secret_id     = aws_secretsmanager_secret.relay_admin.id
  secret_string = jsonencode({
    private_key = tls_private_key.relay_admin_key.private_key_pem,
    public_key  = tls_private_key.relay_admin_key.public_key_openssh})
}

data "aws_secretsmanager_secret_version" "relay_admin" {
  secret_id = aws_secretsmanager_secret.relay_admin.id

  depends_on = [aws_secretsmanager_secret_version.relay_admin]
}


resource "random_password" "vpn_api_key" {
  length = 30
  special = false
}

resource "aws_secretsmanager_secret" "vpn_api_key" {
  name = "${var.secrets_manager_prefix}/${lower(var.environment)}/vpn-api-key"

  recovery_window_in_days = var.secrets_recovery_window

  tags = merge({
    Name        = "assm${var.environment}${var.application_code}${format("%02d",var.index)}-vpn-api-key",
    description = "Key for using VPN appliance API"
  }, var.tags)
}

resource "aws_secretsmanager_secret_version" "vpn_api_key" {
  secret_id     = aws_secretsmanager_secret.vpn_api_key.id
  secret_string = random_password.vpn_api_key.result
}

data "aws_secretsmanager_secret_version" "vpn_api_key" {
  secret_id = aws_secretsmanager_secret.vpn_api_key.id

  depends_on = [aws_secretsmanager_secret_version.vpn_api_key]
}