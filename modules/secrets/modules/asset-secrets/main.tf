resource "random_password" "pre_shared_keys" {
  for_each = var.tunnel_configs.ipsec_tunnels

  length = 32
  special = false
}

resource "aws_secretsmanager_secret" "pre_shared_keys" {
  for_each = random_password.pre_shared_keys

  name = "${var.secrets_manager_prefix}/${lower(var.environment)}/pre-shared-key/${each.key}"

  recovery_window_in_days = var.secrets_recovery_window

  tags = merge({
    Name        = "assm${var.environment}${var.application_code}${format("%02d",var.index)}-pre-shared-key-${each.key}",
    description = "VPN Pre-Shared Key"
  }, var.tags)
}

resource "aws_secretsmanager_secret_version" "pre_shared_keys" {
  for_each = random_password.pre_shared_keys

  secret_id     = aws_secretsmanager_secret.pre_shared_keys[each.key].id
  secret_string = each.value.result
}

data "aws_secretsmanager_secret_version" "pre_shared_keys" {
  for_each = aws_secretsmanager_secret_version.pre_shared_keys

  secret_id = each.value.secret_id
}
