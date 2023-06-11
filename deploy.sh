#!/usr/bin/env bash
set -e

#include functions
. $(pwd)/functions.bash

# Path to the temporary file
TMP_FILE="/tmp/aws_config.txt"

# Function to prompt for AWS_PROFILE and AWS_DEFAULT_REGION
prompt_configuration() {
  # Prompt for AWS_PROFILE value
  read -p "Enter AWS_PROFILE: " AWS_PROFILE

  # Prompt for AWS_DEFAULT_REGION value
  read -p "Enter AWS_DEFAULT_REGION: " AWS_DEFAULT_REGION

  # Prompt for terragrunt env value
  read -p "Enter environment you want to deploy. Possible values are [test, dev, stage, prod]: " ENV
}

# Function to save the aws configuration to the temporary file
save_configuration() {
  echo "export AWS_PROFILE=\"$AWS_PROFILE\"" >"$TMP_FILE"
  echo "export AWS_DEFAULT_REGION=\"$AWS_DEFAULT_REGION\"" >>"$TMP_FILE"
  echo "export ENV=\"$ENV\"" >>"$TMP_FILE"
  log "Configuration saved."
}

# Function to check if AWS profile exists
check-aws-profile() {
  local profile="$1"

  # Check if the AWS profile exists
  if ! aws configure list-profiles | grep -w ${profile} >/dev/null 2>&1; then
    log "error: AWS profile '$profile' does not exist. Configure profile with aws cli"
    unset AWS_PROFILE
    unset AWS_DEFAULT_REGION
    exit 1
  fi
}

# Check if the temporary file exists
if [[ -f "$TMP_FILE" ]]; then
  # Prompt the user if they want to use the configuration from the previous run
  read -p "Configuration from previous run found. Use it? [Y/n]: " USE_PREVIOUS_CONFIG

  if [[ "$USE_PREVIOUS_CONFIG" =~ ^[Yy]$ || "$USE_PREVIOUS_CONFIG" == "" ]]; then
    # Load the variables from the temporary file
    source "$TMP_FILE"
    check-aws-profile "$AWS_PROFILE"
    log "Using configuration from previous run."
  else
    prompt_configuration
    save_configuration
  fi
else
  prompt_configuration
  save_configuration
fi

# Export the variables
export AWS_PROFILE
export AWS_DEFAULT_REGION
export ENV

function check-packages() {
  log "Checking installed packages"

  # Array of program names
  programs=("terraform" "aws" "terragrunt")

  # Loop through each program
  for program in "${programs[@]}"; do
    # Check if program is installed
    if ! command -v "$program" >/dev/null 2>&1; then
      log "error dependency: $program is not installed."
      exit 1
    fi
  done
}

#execute all
check-aws-profile "${AWS_PROFILE}"
export AWS_ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text --profile ${AWS_PROFILE})
check-env
check-packages
check-docker
check-docker-compose


export TERRAGRUNT_DOWNLOAD=/tmp/.terragrunt-cache
export TF_PLUGIN_CACHE_DIR=$TERRAGRUNT_DOWNLOAD/.plugins
mkdir -p ${TF_PLUGIN_CACHE_DIR}
terragrunt run-all init --terragrunt-non-interactive --terragrunt-working-dir "$(pwd)/terraform/infrastructure/${ENV}"
terragrunt run-all plan --terragrunt-non-interactive  --terragrunt-working-dir "$(pwd)/terraform/infrastructure/${ENV}"
terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir "$(pwd)/terraform/infrastructure/${ENV}"
build-docker-images "linux/amd64"
docker-login

# push docker images to ecr
images=("producer" "consumer-go")
docker-push "${images[@]}"


# gets built frontend code from docker container and copy it to local path
get-frontend-code
# sync frontend to s3
aws s3 sync /tmp/tmp-frontend-${ENV} s3://frontendx-${AWS_ACCOUNT}-${AWS_DEFAULT_REGION}-${ENV} --delete

#get outputs
terragrunt run-all output --terragrunt-working-dir "$(pwd)/terraform/infrastructure/${ENV}"

log "execution done"
