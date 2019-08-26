#!/bin/bash

###########################################################################################################
# Define Functions:
###########################################################################################################

#####################################################
# Function: create AWS prereqs (VPC, subnets, security group, db subnet)
#####################################################


log "Installing AWS_CLI"
aws_cli_version=`aws --version 2>&1`
log "Current CLI version: $aws_cli_version"
if [[ $aws_cli_version = *"aws-cli"* ]]; then
    log "AWS CLI already installed. Skipping"
    return
fi

if [ $machine = 'Linux' ]; then
	yum -y install unzip
fi 

curl -s -O "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip"
unzip awscli-bundle.zip
./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
rm -rf awscli-bundle*
log "Done installing AWS CLI"
