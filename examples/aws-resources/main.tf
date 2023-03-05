# * Part 1 - Setup
locals { example = "github-1mill-example-terraform-ecs-examples-aws-resources" }

provider "aws" {
	region = "ca-central-1"

	default_tags {
		tags = { example = local.example }
	}
}

# * Give Docker permission to push images to AWS ECR
data "aws_caller_identity" "this" {}
data "aws_ecr_authorization_token" "this" {}
data "aws_region" "this" {}
locals { ecr_address = format("%v.dkr.ecr.%v.amazonaws.com", data.aws_caller_identity.this.account_id, data.aws_region.this.name) }
provider "docker" {
	registry_auth {
		address  = local.ecr_address
		password = data.aws_ecr_authorization_token.this.password
		username = data.aws_ecr_authorization_token.this.user_name
	}
}

# * Part 2 - Building and pushing docker image
# * Create an ECR Repository: later we will push our Docker Image to this Repository
resource "aws_ecr_repository" "this" { name = local.example }

# * Build our Docker Image that generates a new tag every 5 minutes
resource "time_rotating" "this" { rotation_minutes = 5 }
resource "docker_image" "this" {
	# Generate an image name that Docker will publish to our ECR instance like:
	# 123456789.dkr.ecr.ca-central-1.amazonaws.com/abcdefghijk:2023-03-21T12-34-56
	# {{123456789.dkr.ecr.ca-central-1.amazonaws.com}}/{{abcdefghijk}}:{{2023-03-21T12-34-56}}
	# {{%v}}/{{%v}}:{{%v}}
	name = format("%v/%v:%v", local.ecr_address, resource.aws_ecr_repository.this.id, formatdate("YYYY-MM-DD'T'hh-mm-ss", resource.time_rotating.this.id))

	build { context = "." }
}

# * Push our Image to our Repository
resource "docker_registry_image" "this" { name = resource.docker_image.this.name }

# * Part 3 - Setting up our network
# * Create an AWS Virtual Private Cloud (VPC)
resource "aws_vpc" "this" { cidr_block = "10.0.0.0/16" }

# * Permit resources that we will create later to make and recieve connections to external websites
resource "aws_security_group" "http" {
	description = "Permit incoming HTTP traffic"
	name = "http"
	vpc_id = resource.aws_vpc.this.id

	ingress {
		cidr_blocks = ["0.0.0.0/0"]
		from_port = 80
		protocol = "TCP"
		to_port = 80
	}
}
resource "aws_security_group" "https" {
	description = "Permit incoming HTTPS traffic"
	name = "https"
	vpc_id = resource.aws_vpc.this.id

	ingress {
		cidr_blocks = ["0.0.0.0/0"]
		from_port = 443
		protocol = "TCP"
		to_port = 443
	}
}
resource "aws_security_group" "egress_all" {
	description = "Permit all outgoing traffic"
	name = "egress-all"
	vpc_id = resource.aws_vpc.this.id

	egress {
		cidr_blocks = ["0.0.0.0/0"]
		from_port = 0
		protocol = "-1"
		to_port = 0
	}
}
resource "aws_security_group" "ingress_api" {
	description = "Permit some incoming traffic"
	name = "ingress-node-express"
	vpc_id = resource.aws_vpc.this.id

	ingress {
		cidr_blocks = ["0.0.0.0/0"]
		from_port = 8080
		protocol = "TCP"
		to_port = 8080
	}
}
