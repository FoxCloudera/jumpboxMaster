#!/bin/bash

###########################################################################################################
# Define Functions:
###########################################################################################################

#####################################################
# Functions: create Azure prereqs (Resource Group & Virtual Machine)
#####################################################

create_prereqs() {
  if [ -s $starting_dir/provider/azure/.info ]; then
    log "Looks like you have not propertly terminated the previous environment, as there are still entries in .info. First execute terminate.sh and rerun. Exiting..."
    exit 1
  fi

  #####################################################
  # record main info for the cluster
  #####################################################
  # starting_dir
  echo "AZURE_REGION=${AZURE_REGION:?}" > $starting_dir/provider/azure/.info
  echo "OWNER_TAG=${OWNER_TAG:?}" >> $starting_dir/provider/azure/.info
  echo "starting_dir=${starting_dir:?}" >> $starting_dir/provider/azure/.info
  echo "CLOUD_PROVIDER=${CLOUD_PROVIDER:?}" >> $starting_dir/provider/azure/.info
 
  #####################################################
  # create resource group
  #####################################################
#  az group create \
#  --location ${AZURE_REGION:?} \
#  --name ${OWNER_TAG:?}-rg-cli \
#  --tags owner=${OWNER_TAG:?}  project="personal development" enddate=permanent

  az_rg_create_status=`az group create --location ${AZURE_REGION:?} --name ${OWNER_TAG:?}-rg-cli --tags owner=${OWNER_TAG:?}  project="personal development" enddate=permanent |jq -r ".properties.provisioningState"`
  if [ "${az_rg_create_status}" != "Succeeded" ]; then
    log "Resource group could not be created."
    exit 1
  fi
  echo "AZ_RG_NAME=${OWNER_TAG:?}-rg-cli" >> $starting_dir/provider/azure/.info
  log "New resource group created in ${AZURE_REGION:?} name --> {OWNER_TAG:?}-rg-cli"
  

}


  #####################################################
  # Function: delete the prereqs created for the demo
  #####################################################
  terminate_prereqs() {
  log "Deleting resource group ${AZ_RG_NAME:?}..."
  az group delete --name ${AZ_RG_NAME:?} --yes
  mv -f $starting_dir/provider/azure/.info $starting_dir/provider/azure/.info.old.$(date +%s)
  touch $starting_dir/provider/azure/.info
  cd $starting_dir

}

#####################################################
# Function to install aws cli
#####################################################

install_azure_cli() {

	#########################################################
	# BEGIN
	#########################################################
	log "BEGIN setup.sh"

	unameOut="$(uname -s)"
	case "${unameOut}" in
	  Linux*)     machine=Linux;;
	  Darwin*)    machine=Mac;;
	  CYGWIN*)    machine=Cygwin;;
	  MINGW*)     machine=MinGw;;
	  *)          machine="UNKNOWN:${unameOut}"
	esac
	log "Current machine is: $machine"

	#####################################################
	# first check if JQ is installed
	#####################################################
	log "Installing jq"

	jq_v=`jq --version 2>&1`
	if [[ $jq_v = *"command not found"* ]]; then
	  if [[$machine = "Mac" ]]; then
	    curl -L -s -o jq "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64"
	  else
	    curl -L -s -o jq "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64"
	  fi 
	  chmod +x ./jq
	  cp jq /usr/bin
	else
	  log "jq already installed. Skipping"
	fi

	jq_v=`jq --version 2>&1`
	if [[ $jq_v = *"command not found"* ]]; then
	  log "error installing jq. Please see README and install manually"
	  echo "Error installing jq. Please see README and install manually"
	  exit 1 
	fi  

	####################################################
 	# then install Azure CLI
	#####################################################
  	log "Installing AZURE_CLI"
  	azure_cli_version=`az --version | grep azure-cli`
  	log "Current CLI version: $azure_cli_version"
  	if [[ ${azure_cli_version} = *"azure-cli"* ]]; then
    		log "Azure CLI already installed. Skipping"
    		return
  	fi
  	if [ $machine = 'Linux' ]; then
		#  Install pre-reqs:
		yum install -y gcc libffi-devel python-devel openssl-devel

		#  Install rpm tool
		yum install -y rpm

		# import the rpm key
		rpm --import https://packages.microsoft.com/keys/microsoft.asc

		# create the repo file location
		sh -c 'echo -e "[azure-cli]
		name=Azure CLI
		baseurl=https://packages.microsoft.com/yumrepos/azure-cli
		enabled=1
		gpgcheck=1
		gpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'

		#  Install azure-cli
		yum install -y azure-cli
  	fi  
  	log "Done installing Azure CLI"

}

