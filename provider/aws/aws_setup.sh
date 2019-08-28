#!/bin/bash

###########################################################################################################
# import parameters and utility functions 
###########################################################################################################
. $starting_dir/provider/aws/demo.properties
. $starting_dir/provider/aws/prereq_utils.sh
. $starting_dir/provider/aws/.info


###########################################################################################################
# Define Functions:
###########################################################################################################

##########################################################################################################
# Main execution starts here
###########################################################################################################

#####################################################
# check if all necessary parameters have been exported
#####################################################
if [ "${AWS_ACCESS_KEY_ID}" = "" ] || [ "${AWS_SECRET_ACCESS_KEY}" = "" ]; then
  log "AWS credentials have not been exported. Please export AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY and try again. Exiting..."
  exit 1
fi
if [ "${AWS_REGION}" = "" ]; then
  log "AWS_REGION has not been exported.\n\nPlease export AWS_REGION and try again. Exiting..."
  exit 1
fi

#####################################################
#	Step 1: install the AWS cli
#####################################################
install_aws_cli

#####################################################
#       Step 2: install the AWS prereqs
#####################################################
if [ $setup_prereqs = true ]; then 
  create_prereqs
fi

#####################################################
#       Step 3: create ec2 instance 
#####################################################
if [ $setup_onenode = true ]; then
  create_onenode_instance
  check_ec2 ${oneNodeInstanceId:?}
fi
