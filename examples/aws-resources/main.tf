locals { example = "github-1mill-example-terraform-ecs-examples-aws-resources" }

provider "aws" {
	region = "ca-central-1"

	default_tags {
		tags = {
			example = local.example
		}
	}
}

# * Give Docker permission to push images to AWS ECR
data "aws_caller_identity" "this" {}
data "aws_ecr_authorization_token" "this" {}
data "aws_region" "this" {}
provider "docker" {
	registry_auth {
		address  = format("%v.dkr.ecr.%v.amazonaws.com", data.aws_caller_identity.this.account_id, data.aws_region.current.name)
		password = data.aws_ecr_authorization_token.token.password
		username = data.aws_ecr_authorization_token.token.user_name
	}
}

# * Create ECR Repository that we will push our Docker image to
resource "aws_ecr_repository" "this" {
	image_tag_mutability = "MUTABLE"
	name = local.example
}
