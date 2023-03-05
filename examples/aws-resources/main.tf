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

# * Create ECR Repository: later we will push our Docker image to this Repository
resource "aws_ecr_repository" "this" {
	image_tag_mutability = "MUTABLE"
	name = local.example
}

# * Build our Docker image that generates a new tag every 5 minutes
resource "time_rotating" "this" { rotation_minutes = 5 }
resource "docker_image" "this" {
	# Generate an image name that Docker will publish to our ECR instance like:
	# 123456789.dkr.ecr.ca-central-1.amazonaws.com/abcdefghijk:2023-03-21T12-34-56
	# [123456789.dkr.ecr.ca-central-1.amazonaws.com]/[abcdefghijk]:[2023-03-21T12-34-56]
	# [%v]/[%v]:[%v]
	name = format("%v/%v:%v", local.ecr_address, resource.aws_ecr_repository.this.id, formatdate("YYYY-MM-DD'T'hh-mm-ss", resource.time_rotating.this.id))

	build { context = "." }
}

# * Push our Docker image to our AWS ECR Repository
resource "docker_registry_image" "this" { name = resource.docker_image.this.name }
