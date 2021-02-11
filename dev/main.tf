terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.22"
    }
    fortios = {
      source  = "fortinetdev/fortios"
      version = "1.7"
    }
  }

  backend "s3" {

    bucket = "trad-nonprod-nes-management"
    key    = "enr-fr-infrastructure/dev/terraform.tfstate"
    region = "eu-central-1"

    profile = "trad-nonprod-nes-tools"
  }
}

# Configure the AWS Provider for Industrial Edge Account
provider "aws" {
  alias = "industrial_shared"
  region = "eu-central-1"

  allowed_account_ids = ["646918904450"]
  profile = "trad-nonprod-nes-tools"
}

provider "aws" {
  alias = "enr"
  region = "eu-central-1"

  allowed_account_ids = ["290221653127"]
  profile = "trad-nonprod-enr-fr"
}

provider "aws" {
  alias = "enterprise_transit"
  region = "eu-central-1"

  allowed_account_ids = ["209361602550"]
  profile = "trad-edge-services"
}

data "terraform_remote_state" "shared_edge" {
  backend = "s3"
  config = {
    bucket  = "trad-prod-shared-management"
    key     = "shared-edge/dev/terraform.tfstate"
    region  = "eu-central-1"
    profile = "trad-shared-services"
  }
}
