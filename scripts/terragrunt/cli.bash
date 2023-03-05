#!/usr/bin/env bash
set -e

function cli() {
	# * Props
	local command=${@:1}

	# * Computed values
	local cli_root=$(dirname $BASH_SOURCE)
	local project_root=$PWD/$cli_root/../../ # * Must be absolute path for Docker Volume

	# * Load CLI environmental variables
	source $cli_root/config.bash

	# * Load .env from project root into the environment if it exists
	local env_file=$project_root/$ENV_FILENAME
	if [[ -f "$env_file" ]]; then
		source $env_file
	fi

	AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
	AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
	COMMAND=$command \
	DIR=$project_root \
	docker compose \
		--file $(dirname $BASH_SOURCE)/docker-compose.yml \
		up \
			--exit-code-from terragrunt \
			terragrunt
}

cli ${@:1} # * Pass through all arguments to function
