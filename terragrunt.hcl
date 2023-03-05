generate "versions" {
	contents = <<-EOF
		terraform {
			required_version = "~> 1.3"

			required_providers {
				aws = {
					source  = "hashicorp/aws"
					version = "~> 4.56"
				}
				docker = {
					# * Version 2.18 introduces .dockerignore whitelist pattern
					source  = "kreuzwerker/docker"
					version = "~> 2.18"
				}
			}
		}
	EOF
	if_exists = "skip"
	path = "versions.tf"
}
