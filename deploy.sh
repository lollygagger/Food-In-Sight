#!/bin/bash

# Set project and branch to build
AMPLIFY_APP_ID="d1c2naelj7l2nf"
AMPLIFY_BRANCH_NAME="main"
TERRAFORM_RESOURCE="aws_amplify_branch.main"

# Colors for aesthetics
RESET="\033[0m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"

# Functions to print colored messages
info() {
  echo -e "${BLUE}[INFO]${RESET} $1"
}

success() {
  echo -e "${GREEN}[SUCCESS]${RESET} $1"
}

warning() {
  echo -e "${YELLOW}[WARNING]${RESET} $1"
}

error() {
  echo -e "${RED}[ERROR]${RESET} $1"
}

# Run destroy when script is closed
cleanup() {
  info "Cleaning up: Running terraform destroy..."
  terraform destroy -auto-approve
  success "Terraform destroy completed."
}

# Trap EXIT to ensure `terraform destroy` runs on script exit
trap cleanup EXIT

cd "deployment"

# First check if AWS CLI is already configured and if not then prompt
info "Checking AWS CLI configuration..."
AWS_CONFIGURED=$(aws configure list 2>&1 | grep -c "<not set>")
if [ "$AWS_CONFIGURED" -gt 0 ]; then
  warning "AWS CLI is not fully configured. Starting configuration process..."
  aws configure
  if [ $? -ne 0 ]; then
    error "AWS CLI configuration failed. Exiting."
    exit 1
  else
    success "AWS CLI configured successfully."
  fi
else
  success "AWS CLI is already configured."
fi

# Terraform import to access the existing deployed branch
info "Importing existing Amplify branch into Terraform state..."
if terraform import $TERRAFORM_RESOURCE $AMPLIFY_APP_ID/$AMPLIFY_BRANCH_NAME; then
  success "Successfully imported Amplify branch."
else
  error "Failed to import Amplify branch. Exiting."
  exit 1
fi

# Terraform Plan
info "Planning Terraform changes..."
if terraform plan; then
  success "Terraform plan completed."
else
  error "Terraform plan failed. Exiting."
  exit 1
fi

# Terraform Apply
info "Applying Terraform changes..."
if terraform apply -auto-approve; then
  success "Terraform apply completed."
else
  error "Terraform apply failed. Exiting."
  exit 1
fi

# Loop until closed
info "Terraform apply completed. Press Ctrl+C to exit and clean up resources."
while :; do sleep 1; done