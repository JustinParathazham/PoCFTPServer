## Terraform Test connection module and FTP Server Family creation test.
## Run by terraform apply -target=module.ftp_family

module "ftp_family" {

    provider "aws" {
    region = "eu-central-1"
    access_key = "ASIATV2VCW3HKRB7QZ6N"
    secret_key = "h4jm/iHyX45o/WsuNrP9uQUGXgWUdND5OxXAKLB"
    }
  
    resource "aws_transfer_server" "FTP-Server" {
    identity_provider_type = "SERVICE_MANAGED"
    logging_role           = aws_iam_role.example.arn

    tags = {
        NAME = "tf-acc-test-transfer-server"
        ENV  = "test"
    }
    }

    resource "aws_iam_role" "FTP-Server-Role" {
    name = "tf-test-transfer-server-iam-role"

    assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Principal": {
                "Service": "transfer.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
            }
        ]
    }
    EOF
    }

    data "aws_transfer_server" "example" {
    server_id = "s-6fdfa12fdd734ad98"
    }

    # resource "aws_iam_role_policy" "FTP-Server-Policy" {
    # name = "tf-test-transfer-server-iam-policy"
    # role = aws_iam_role.example.id

    # policy = <<POLICY
    # {
    #     "Version": "2012-10-17",
    #     "Statement": [
    #         {
    #         "Sid": "AllowFullAccesstoCloudWatchLogs",
    #         "Effect": "Allow",
    #         "Action": [
    #             "logs:*"
    #         ],
    #         "Resource": "*"
    #         }
    #     ]
    # }
    # POLICY
}