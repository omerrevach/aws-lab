#!/bin/bash

# AWS IAM Cleanup Script
# This script detaches and deletes IAM roles, policies, and related resources
# Set to exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
  local color=$1
  local message=$2
  echo -e "${color}${message}${NC}"
}

# Function to check if AWS CLI is installed
check_aws_cli() {
  print_message "${BLUE}" "Checking AWS CLI installation..."
  if ! command -v aws &> /dev/null; then
    print_message "${RED}" "AWS CLI is not installed. Please install it first."
    exit 1
  fi
  print_message "${GREEN}" "AWS CLI is installed."
  
  # Check AWS credentials
  print_message "${BLUE}" "Checking AWS credentials..."
  if ! aws sts get-caller-identity &> /dev/null; then
    print_message "${RED}" "AWS credentials are not configured properly."
    exit 1
  fi
  print_message "${GREEN}" "AWS credentials are configured."
}

# Function to list and save IAM resources to files for reference
list_resources() {
  print_message "${BLUE}" "Listing and saving IAM resources to files..."
  
  mkdir -p ./iam_backup
  aws iam list-roles --query 'Roles[*].[RoleName,Arn]' --output json > ./iam_backup/all_roles.json
  aws iam list-policies --scope Local --query 'Policies[*].[PolicyName,Arn]' --output json > ./iam_backup/all_policies.json
  aws iam list-instance-profiles --query 'InstanceProfiles[*].[InstanceProfileName,Arn]' --output json > ./iam_backup/all_instance_profiles.json
  
  print_message "${GREEN}" "IAM resources listed and saved to ./iam_backup directory."
}

# Function to delete a specific role and its attached policies
delete_role() {
  local role_name=$1
  
  print_message "${YELLOW}" "Processing role: ${role_name}"
  
  # List attached policies
  attached_policies=$(aws iam list-attached-role-policies --role-name "${role_name}" --query 'AttachedPolicies[*].PolicyArn' --output text)
  
  # Detach all policies from the role
  for policy_arn in $attached_policies; do
    print_message "${BLUE}" "Detaching policy ${policy_arn} from role ${role_name}"
    aws iam detach-role-policy --role-name "${role_name}" --policy-arn "${policy_arn}"
    print_message "${GREEN}" "Policy ${policy_arn} detached from role ${role_name}"
  done
  
  # Delete inline policies
  inline_policies=$(aws iam list-role-policies --role-name "${role_name}" --query 'PolicyNames' --output text)
  for policy_name in $inline_policies; do
    print_message "${BLUE}" "Deleting inline policy ${policy_name} from role ${role_name}"
    aws iam delete-role-policy --role-name "${role_name}" --policy-name "${policy_name}"
    print_message "${GREEN}" "Inline policy ${policy_name} deleted from role ${role_name}"
  done
  
  # Delete instance profiles associated with the role
  instance_profiles=$(aws iam list-instance-profiles-for-role --role-name "${role_name}" --query 'InstanceProfiles[*].InstanceProfileName' --output text)
  for profile_name in $instance_profiles; do
    print_message "${BLUE}" "Removing role ${role_name} from instance profile ${profile_name}"
    aws iam remove-role-from-instance-profile --instance-profile-name "${profile_name}" --role-name "${role_name}"
    print_message "${GREEN}" "Role removed from instance profile ${profile_name}"
    
    print_message "${BLUE}" "Deleting instance profile ${profile_name}"
    aws iam delete-instance-profile --instance-profile-name "${profile_name}"
    print_message "${GREEN}" "Instance profile ${profile_name} deleted"
  done
  
  # Delete the role
  print_message "${BLUE}" "Deleting role ${role_name}"
  aws iam delete-role --role-name "${role_name}"
  print_message "${GREEN}" "Role ${role_name} deleted"
}

# Function to delete a specific policy
delete_policy() {
  local policy_arn=$1
  
  print_message "${YELLOW}" "Processing policy: ${policy_arn}"
  
  # Get policy versions
  versions=$(aws iam list-policy-versions --policy-arn "${policy_arn}" --query 'Versions[?IsDefaultVersion==`false`].VersionId' --output text)
  
  # Delete non-default versions
  for version_id in $versions; do
    print_message "${BLUE}" "Deleting policy version ${version_id} of ${policy_arn}"
    aws iam delete-policy-version --policy-arn "${policy_arn}" --version-id "${version_id}"
    print_message "${GREEN}" "Policy version ${version_id} deleted"
  done
  
  # Delete the policy
  print_message "${BLUE}" "Deleting policy ${policy_arn}"
  aws iam delete-policy --policy-arn "${policy_arn}"
  print_message "${GREEN}" "Policy ${policy_arn} deleted"
}

# Function to clean up project-specific resources
cleanup_project_resources() {
  local project_prefix=$1
  
  print_message "${BLUE}" "Cleaning up IAM resources with prefix: ${project_prefix}"
  
  # List roles with the project prefix
  roles=$(aws iam list-roles --query "Roles[?starts_with(RoleName, '${project_prefix}')].RoleName" --output text)
  
  # Delete each role
  for role_name in $roles; do
    delete_role "${role_name}"
  done
  
  # List policies with the project prefix
  policies=$(aws iam list-policies --scope Local --query "Policies[?starts_with(PolicyName, '${project_prefix}')].Arn" --output text)
  
  # Delete each policy
  for policy_arn in $policies; do
    delete_policy "${policy_arn}"
  done
  
  # List instance profiles with the project prefix
  profiles=$(aws iam list-instance-profiles --query "InstanceProfiles[?starts_with(InstanceProfileName, '${project_prefix}')].InstanceProfileName" --output text)
  
  # Delete each instance profile (if not already deleted with roles)
  for profile_name in $profiles; do
    print_message "${BLUE}" "Deleting instance profile ${profile_name}"
    # Check if the instance profile has roles
    roles_in_profile=$(aws iam list-instance-profile-roles --instance-profile-name "${profile_name}" --query 'Roles[*].RoleName' --output text 2>/dev/null || echo "")
    
    # Remove roles if they exist
    for role_in_profile in $roles_in_profile; do
      print_message "${BLUE}" "Removing role ${role_in_profile} from instance profile ${profile_name}"
      aws iam remove-role-from-instance-profile --instance-profile-name "${profile_name}" --role-name "${role_in_profile}"
      print_message "${GREEN}" "Role removed from instance profile"
    done
    
    # Delete the instance profile
    aws iam delete-instance-profile --instance-profile-name "${profile_name}"
    print_message "${GREEN}" "Instance profile ${profile_name} deleted"
  done
}

# Delete specific resources by name (common EKS resources)
delete_known_resources() {
  print_message "${BLUE}" "Deleting known EKS and Terraform-created IAM resources..."
  
  # Known roles commonly created by Terraform EKS modules
  known_roles=(
    "ec2-ssm-role"
    "aws-load-balancer-controller"
    "flask-app-role"
    "external-secrets-role"
  )
  
  # Known policies commonly created by Terraform EKS modules
  known_policies=(
    "AWSLoadBalancerControllerIAMPolicy"
    "flask-app-s3-policy"
    "eks-describe-cluster"
    "external-secrets-policy"
  )
  
  # Try to delete known roles
  for role_name in "${known_roles[@]}"; do
    if aws iam get-role --role-name "${role_name}" &>/dev/null; then
      delete_role "${role_name}"
    else
      print_message "${YELLOW}" "Role ${role_name} not found, skipping."
    fi
  done
  
  # Try to delete known policies
  for policy_name in "${known_policies[@]}"; do
    policy_arn=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='${policy_name}'].Arn" --output text)
    if [ -n "${policy_arn}" ]; then
      delete_policy "${policy_arn}"
    else
      print_message "${YELLOW}" "Policy ${policy_name} not found, skipping."
    fi
  done
}

# Helper function to delete the OIDC provider
delete_oidc_provider() {
  # Get all OIDC providers
  oidc_providers=$(aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[*].Arn' --output text)
  
  # Look for EKS OIDC providers
  for provider_arn in $oidc_providers; do
    # Extract the provider URL
    provider_url=$(aws iam get-open-id-connect-provider --open-id-connect-provider-arn "${provider_arn}" --query 'Url' --output text)
    
    # Check if it's an EKS provider
    if [[ "${provider_url}" == *"eks.amazonaws.com"* ]]; then
      print_message "${BLUE}" "Deleting EKS OIDC provider: ${provider_arn}"
      aws iam delete-open-id-connect-provider --open-id-connect-provider-arn "${provider_arn}"
      print_message "${GREEN}" "OIDC provider ${provider_arn} deleted"
    fi
  done
}

# Main execution
main() {
  print_message "${BLUE}" "=== Starting AWS IAM Cleanup ==="
  
  # Check AWS CLI
  check_aws_cli
  
  # Backup current resources
  list_resources
  
  # Ask for confirmation
  print_message "${RED}" "WARNING: This script will delete IAM roles, policies, and instance profiles."
  print_message "${RED}" "Make sure you have backed up any important configurations."
  read -p "Do you want to continue? (y/n): " confirm
  
  if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
    print_message "${YELLOW}" "Cleanup aborted."
    exit 0
  fi
  
  # Ask for project prefix (optional)
  read -p "Enter your project prefix (or press Enter to skip): " project_prefix
  
  if [ -n "${project_prefix}" ]; then
    cleanup_project_resources "${project_prefix}"
  fi
  
  # Delete known resources
  delete_known_resources
  
  # Delete OIDC provider for EKS
  delete_oidc_provider
  
  print_message "${GREEN}" "=== AWS IAM cleanup completed ==="
  print_message "${YELLOW}" "Note: Some resources might still exist if they were not covered by this script."
  print_message "${YELLOW}" "Check the AWS Management Console or use AWS CLI to verify."
}

# Run the main function
main