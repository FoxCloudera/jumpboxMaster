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
  echo "az_rg_create_status --> " ${az_rg_create_status}
  echo "AZ_RG_NAME=${OWNER_TAG:?}-rg-cli" >> $starting_dir/provider/azure/.info
  log "New resource group created in ${AZURE_REGION:?} name --> ${OWNER_TAG:?}-rg-cli"

  #####################################################
  # create ssh key pair
  #####################################################
  log "Create the ssh key pair files..."
  mkdir -p $starting_dir/provider/azure/mykeys

  ssh-keygen -t rsa -b 2048 -C ${AZ_USER:?} -f $starting_dir/provider/azure/mykeys/azure_ssh_key -q -P ""
  chmod 0400 $starting_dir/provider/azure/mykeys/azure_ssh_key
  echo "KEY_FILENAME=azure_ssh_key" >> $starting_dir/provider/azure/.info
  echo "KEY_FILE_PATH=${starting_dir}/provider/azure/" >> $starting_dir/provider/azure/.info
  export KEY_FILENAME=azure_ssh_key
  export KEY_FILE_PATH=${starting_dir}/provider/azure/
  

}


  #####################################################
  # Function: delete the prereqs created for the demo
  #####################################################
  terminate_prereqs() {
  log "Deleting resource group ${AZ_RG_NAME:?}..."
  az group delete --name ${AZ_RG_NAME:?} --yes
  mv -f $starting_dir/provider/azure/.info $starting_dir/provider/azure/.info.old.$(date +%s)
  mv -f $starting_dir/provider/azure/mykeys $starting_dir/provider/azure/.mykeys.old.$(date +%s)
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

		# copy the repo file to /etc/yum.repos.d
		cp /app/jumpboxMaster/provider/azure/files/template.azure-cli.repo /etc/yum.repos.d/azure-cli.repo

		#  Install azure-cli
		yum install -y azure-cli
  	fi  
  	log "Done installing Azure CLI"

}

#####################################################
# Function: Azure cli login 
#####################################################
login_azure_cli() {

  if [ "${AZ_USER}" = "" ] || [ "${AZ_PWD}" = "" ]; then
    log "Azure credentials have not been exported. Please export AZ_USER and AZ_PWD and try again. Exiting..."
    exit 1
  else
    az login -u ${AZ_USER:?} -p ${AZ_PWD:?}
  fi

}

#####################################################
# Function to copy key file to a bind mount
#####################################################
replicate_key() {

    # build a unique filename for this pem key
	BIND_FILENAME=${OWNER_TAG}-${AZURE_REGION}-${oneNodeInstanceId}-${ONENODE_PRIVATE_IP}
        echo "BIND_FILENAME=${BIND_FILENAME:?}" >> $starting_dir/provider/azure/.info
	echo "file to copy is --> " ${KEY_FILE_PATH}${KEY_FILENAME}
	echo "listing file contents ..."
	ls ${KEY_FILE_PATH}
	cp ${KEY_FILE_PATH}${KEY_FILENAME} ${BIND_MNT_TARGET}/${BIND_FILENAME}
}

#####################################################
# Function to create instance
#####################################################
create_onenode_instance() {
	log "Create oneNode azure instance"
#	az vm create \
#  --resource-group tlepple-rg-cli \
#  --name tlepple-vm-cli \
#  --image cloudera:cloudera-centos-os:7_4:2.0.7 \
#  --admin-username centos \
#  --ssh-key-values "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDN1x4AA2Kk5g4O1jeemLDwkhkWuTSxDrdfIvegxRXjSX7H3yhn+ha/wqzOP69XAZ+CIKG9ExW4IC/dgwNk367y9hBM5F/ObmHSkr/wJiZ7rR3RG4TTw9K4g6kn2jMHoI9SmxfQWvmJuGLguLpSZ1kncC6emPFsR+lN+7uHB7AI6JJwbW9j1QphfO8GrR0ob0DhuPFQpoMPfL+iaI2Q28yI8p+KXYV63kIHlcGsAZIy5U6MqftC4V2A2dEZZWor/BbNHpxDB09dXzafz3yEZHMKq6+fANb3Tmygc4uAQNc3WUwX8MT/l3nvA8e25XkZqkCEFoiAYlP+JujZLld63zND tlepple@clouderaazure.com" \
#  --data-disk-sizes-gb 20 \
#  --size Standard_DS2_v2 \
#  --storage-sku Standard_LRS \
#  --location westus2 \
#  --public-ip-address-allocation static \
#  --tags owner=tlepple project="personal development" enddate=permanent
	vm-create-output=`az vm create --resource-group ${AZ_RG_NAME:?} --name ${OWNER_TAG:?}-vm-cli --image ${AZURE_IMAGE:?} --admin-username ${SSH_USERNAME:?} --ssh-key-values $starting_dir/provider/azure/mykeys/azure_ssh_key.pub --data-disk-sizes-gb 20 --size ${ONE_NODE_INSTANCE:?} --location ${AZURE_REGION:?} --public-ip-address-allocation static --tags owner=tlepple project="personal development" enddate=permanent`

	echo ${vm-creat-output:?}
#	log "Instance ID: ${oneNodeInstanceId:?}"
#	echo "oneNodeInstanceId=${oneNodeInstanceId:?}" >> $starting_dir/provider/azure/.info
}
