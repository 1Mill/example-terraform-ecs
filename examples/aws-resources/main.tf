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

# * Available AWS Availability Zones that we will route our connections through.
data "aws_availability_zones" "available" { state = "available" }

# * Create an Internet Gateway so that resources running inside our VPC can
# * connect to the internet.
resource "aws_internet_gateway" "this" { vpc_id = resource.aws_vpc.this.id }

# * Create public subnetworks (Public Subnet) so that resources inside our
# * VPC can use these Public Subnets to fetch data from the internet.
resource "aws_route_table" "public" { vpc_id = resource.aws_vpc.this.id }
resource "aws_route" "public" {
	destination_cidr_block = "0.0.0.0/0"
	gateway_id = resource.aws_internet_gateway.this.id
	route_table_id = resource.aws_route_table.public.id
}
resource "aws_subnet" "public" {
	count = 2

	availability_zone = data.aws_availability_zones.available.names[count.index]
	cidr_block = cidrsubnet(resource.aws_vpc.this.cidr_block, 8, count.index)
	vpc_id = resource.aws_vpc.this.id
}
resource "aws_route_table_association" "public" {
	# https://github.com/hashicorp/terraform/issues/22476#issuecomment-547689853
	for_each = { for k, v in resource.aws_subnet.public : k => v.id }

	route_table_id = resource.aws_route_table.public.id
	subnet_id = each.value
}

# * Eventually we will make a private subnetwork (Private Subnet) that will
# * need to connect to external websites. To do this, we must create a NAT
# * Gateway that will route external website requests from our Private
# * Subnet through our Public Subnet.
resource "aws_eip" "this" { vpc = true }
resource "aws_nat_gateway" "this" {
	allocation_id = resource.aws_eip.this.id
	subnet_id = resource.aws_subnet.public[0].id # Just route all requests through one of our Public Subnets.

	depends_on = [resource.aws_internet_gateway.this]
}
