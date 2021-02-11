module "administration_secrets" {
  source = "./modules/administration-secrets"

  application_code = var.application_code
  environment      = var.environment
  index            = var.index

  secrets_manager_prefix = "${var.secrets_manager_prefix}/administration"

  secrets_recovery_window = var.secrets_recovery_window

  tags = var.tags
}

module "asset_secrets" {
  source = "./modules/asset-secrets"

  application_code = var.application_code
  environment      = var.environment
  index            = var.index

  secrets_manager_prefix = "${var.secrets_manager_prefix}/assets"

  tunnel_configs = var.tunnel_configs

  secrets_recovery_window = var.secrets_recovery_window

  tags = var.tags
}