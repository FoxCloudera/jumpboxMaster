#!/bin/bash

###########################################################################################################
# Define Functions:
###########################################################################################################

#####################################################
# Functions: create AWS prereqs (VPC, subnets, security group, db subnet)
#####################################################

create_prereqs() {
  if [ -s $starting_dir/provider/aws/.info ]; then
    log "Looks like you have not propertly terminated the previous environment, as there are still entries in .info. Execute first terminate.sh and rerun. Exiting..."
    exit 1
  fi

  #####################################################
  # record main info for the cluster
  #####################################################
#  echo "AWS_REGION=${AWS_REGION:?}" > .info
#  echo "OWNER=${OWNER:?}" >> .info
#  echo "PROJECT='${PROJECT:?}'" >> .info
#  echo "CDH_VERSION=${CDH_VERSION:?}" >> .info

# starting_dir
echo "AWS_REGION=${AWS_REGION:?}" > $starting_dir/provider/aws/.info
echo "OWNER_TAG=${OWNER_TAG:?}" >> $starting_dir/provider/aws/.info
echo "starting_dir=${starting_dir:?}" >> $starting_dir/provider/aws/.info
echo "CLOUD_PROVIDER=${CLOUD_PROVIDER:?}" >> $starting_dir/provider/aws/.info
  #####################################################
  # create VPC
  #####################################################
  if [ "${MY_VPC}" = "" ]; then
    vpc_id=`aws --output json --region ${AWS_REGION:?} ec2 create-vpc --cidr-block 10.0.0.0/16 | jq -r ".Vpc.VpcId"`
    if [ "${vpc_id}" = "" ]; then
      log "VPC could not be created. Most likely the limit has beeen exceeded. Please pick a different region, or use an existing VPC by setting 'export MY_VPC=...' and rerun the script. Exiting..."
      exit 1
    fi
    echo "existingVpc=false" >> $starting_dir/provider/aws/.info
    aws --region ${AWS_REGION:?} ec2 create-tags --resources ${vpc_id:?} --tags Key=owner,Value=${OWNER_TAG:?} Key=Name,Value=${OWNER_TAG:?}-ingest-demo
    log "New VPC in ${AWS_REGION:?} created: ${OWNER_TAG:?}-ingest-demo, ${vpc_id:?}"
  else
    vpc_id="${MY_VPC}"
    echo "existingVpc=true" >> $starting_dir/provider/aws/.info
    log "Existing VPC in ${AWS_REGION:?} used: ${vpc_id:?}"
  fi
  echo "vpc_id=${vpc_id:?}" >> $starting_dir/provider/aws/.info
  aws --region ${AWS_REGION:?} ec2 modify-vpc-attribute --enable-dns-hostnames --vpc-id ${vpc_id:?}
 
  ##################################################### 
  # create public subnets
  #####################################################
  subnet_id=`aws --output json --region ${AWS_REGION:?} ec2 create-subnet --availability-zone ${AWS_REGION:?}a --vpc-id ${vpc_id:?} --cidr-block 10.0.8.0/24 | jq -r ".Subnet.SubnetId"`
  echo "subnet_id=${subnet_id:?}" >> $starting_dir/provider/aws/.info
  log "New Subnet in ${AWS_REGION:?}a created: ${OWNER_TAG:?}-ingest-demo, ${subnet_id:?}"
  aws --region ${AWS_REGION:?} ec2 create-tags --resources ${subnet_id:?} --tags Key=owner,Value=${OWNER_TAG:?} Key=Name,Value=${OWNER_TAG:?}-ingest-demo
 
  ##################################################### 
  # create/get internet gateway
  #####################################################
  igw=`aws --region ${AWS_REGION:?} ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=${vpc_id:?} | jq -r ".InternetGateways[0].InternetGatewayId"`
  if [ "$igw" == "null" ]; then
    igw=`aws --output json --region ${AWS_REGION:?} ec2 create-internet-gateway | jq -r ".InternetGateway.InternetGatewayId"`
    aws --region ${AWS_REGION:?} ec2 attach-internet-gateway --vpc-id ${vpc_id:?} --internet-gateway-id ${igw}
    aws --region ${AWS_REGION:?} ec2 create-tags --resources ${igw:?} --tags Key=owner,Value=${OWNER_TAG:?} Key=Name,Value=${OWNER_TAG:?}-ingest-demo
  fi
  echo "igw=${igw:?}" >> $starting_dir/provider/aws/.info
  log "Internet gateway used: ${igw:?}"
 
  ##################################################### 
  # create route table
  #####################################################
  rtb=`aws --output json --region ${AWS_REGION:?} ec2 create-route-table --vpc-id ${vpc_id:?} | jq -r ".RouteTable.RouteTableId"`
  aws --region ${AWS_REGION:?} ec2 create-route --route-table-id ${rtb:?} --destination-cidr-block 0.0.0.0/0 --gateway-id ${igw:?}
  aws --region ${AWS_REGION:?} ec2 associate-route-table  --subnet-id ${subnet_id:?} --route-table-id ${rtb:?}
  aws --region ${AWS_REGION:?} ec2 create-tags --resources ${rtb:?} --tags Key=owner,Value=${OWNER_TAG:?} Key=Name,Value=${OWNER_TAG:?}-ingest-demo
  echo "rtb=${rtb:?}" >> $starting_dir/provider/aws/.info
  log "Route table used: ${rtb:?}"
 
  ##################################################### 
  # get PEM file
  #####################################################
  aws --region ${AWS_REGION:?} ec2 create-key-pair --key-name ${OWNER_TAG:?}-ingest-demo --query 'KeyMaterial' --output text > $starting_dir/provider/aws/${OWNER_TAG:?}-ingest-demo.pem
  chmod 400  $starting_dir/provider/aws/${OWNER_TAG:?}-ingest-demo.pem

  #####################################################
  # create Security Group
  #####################################################
  sg=`aws --output json --region ${AWS_REGION:?} ec2 create-security-group --group-name ${OWNER_TAG:?}-ingest-demo-SG --description "Security group for Ingest Demo" --vpc-id ${vpc_id:?} | jq -r ".GroupId"`
  aws --region ${AWS_REGION:?} ec2 authorize-security-group-ingress --group-id ${sg:?} --protocol all --port 0-65535 --source-group ${sg:?}
  #  need to add a port 22 access here...
  #  this next one might need to be removed...  its sets the ip allowed to the public ip address of the host running this code.  (jumpbox).
  # orig version 
  aws --region ${AWS_REGION:?} ec2 authorize-security-group-ingress --group-id ${sg:?} --protocol all --port 0-65535 --cidr `curl -s ipinfo.io/ip`/32
  # added this to map to my home ip address and not the jumpbox server
  #aws --region ${AWS_REGION:?} ec2 authorize-security-group-ingress --group-id ${sg:?} --protocol all --port 0-65535 --cidr ${MY_HOME_IP:?}
  aws --region ${AWS_REGION:?} ec2 create-tags --resources ${sg:?} --tags Key=owner,Value=${OWNER_TAG:?} Key=Name,Value=${OWNER_TAG:?}-ingest-demo
  echo "sg=${sg:?}" >> $starting_dir/provider/aws/.info
  log "New Security Group in ${AWS_REGION:?} created: ${OWNER_TAG:?}-ingest-demo-SG, ${sg:?}"

  
}

#####################################################
# Function: delete all the prereqs created for the demo
#####################################################
terminate_prereqs() {
  log "Deleting security group ${sg}..."
  aws --region ${AWS_REGION:?} ec2 delete-security-group --group-id ${sg}
  log "Deleting subnet ${subnet_id}..."
  aws --region ${AWS_REGION:?} ec2 delete-subnet --subnet-id ${subnet_id}
  log "Deleting route table ${rtb}..."
  aws --region ${AWS_REGION} ec2 delete-route-table --route-table-id ${rtb}
  if [ "$existingVpc" = "false" ]; then
    log "Detaching internet gateway from VPC..."
    aws --region ${AWS_REGION:?} ec2 detach-internet-gateway --vpc-id ${vpc_id} --internet-gateway-id ${igw}
    log "Deleting internet gateway ${igw}..."
    aws --region ${AWS_REGION:?} ec2 delete-internet-gateway --internet-gateway-id ${igw}
    log "Deleting VPC ${vpc_id}..."
    aws --region ${AWS_REGION:?} ec2 delete-vpc --vpc-id ${vpc_id}
  else
    log "Skipping existing internet gateway and VPC..."
  fi
  log "Deleting key ${OWNER_TAG:?}-ingest-demo..."
  aws --region ${AWS_REGION:?} ec2 delete-key-pair --key-name ${OWNER_TAG:?}-ingest-demo
  mv -f $starting_dir/provider/aws/${OWNER_TAG:?}-ingest-demo.pem $starting_dir/provider/aws/.${OWNER_TAG:?}-ingest-demo.pem.old.$(date +%s)
  mv -f $starting_dir/provider/aws/.info $starting_dir/provider/aws/.info.old.$(date +%s)
  touch $starting_dir/provider/aws/.info
  cd $starting_dir
}











#####################################################
# Function to install aws cli
#####################################################

install_aws_cli() {

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

}

#####################################################
# Function to create instance
#####################################################
create_onenode_instance() {
	log "Create oneNode ec2 instance"
	oneNodeInstanceId=`aws --output json --region ${AWS_REGION:?} ec2 run-instances --image-id ${AMI_ID:?} --key-name ${OWNER_TAG:?}-ingest-demo --security-group-ids ${sg:?} --instance-type ${ONE_NODE_INSTANCE:?} --subnet-id ${subnet_id:?} --associate-public-ip-address | jq -r ".Instances[0].InstanceId"`
	log "Instance ID: ${oneNodeInstanceId:?}"
	aws --region ${AWS_REGION:?} ec2 create-tags --resources ${oneNodeInstanceId:?} --tags Key=owner,Value=${OWNER_TAG:?} Key=Name,Value=ingest-director-${OWNER_TAG:?} Key=ingest-demo,Value=${OWNER_TAG:?} Key=project,Value=${PROJECT_TAG:?}
	echo "oneNodeInstanceId=${oneNodeInstanceId:?}" >> ./.info
}
