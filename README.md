# example-terraform-ecs

## How to use

1. Install `docker ~> 20.10.23` and `docker-compose ~> 2.15.1` on your computer.
1. Create `.env` file with `AWS_ACCESS_KEY_ID=xxx` and `AWS_SECRET_ACCESS_KEY=yyy` values
1. To run a single project, run `./scripts/terragrunt/cli.bash plan --terragrunt-working-dir ./examples/aws-resources`.
