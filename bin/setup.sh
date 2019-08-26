#!/bin/bash

#########################################################
# Input parameters
#########################################################

case "$1" in
        aws)
           echo "you chose aws"
            ;;
        azure)
           echo "you chose azure"
            ;;
        gcp)
	   echo "you chose gcp"
            ;;
        *)
            echo $"Usage: $0 {aws|azure|gcp} template-file [docker-device]"
            echo $"example: ./setup.sh azure default_template.json"
            echo $"example: ./setup.sh aws cdsw_template.json /dev/xvdb"
            exit 0
esac

CLOUD_PROVIDER=$1

#########################################################
# utility functions
#########################################################
dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

starting_dir=`pwd`

# logging function
log() {
    echo -e "[$(date)] [$BASH_SOURCE: $BASH_LINENO] : $*"
    echo -e "[$(date)] [$BASH_SOURCE: $BASH_LINENO] : $*" >> $starting_dir/setup-all.log
}
# Load util functions.
#. $starting_dir/bin/utils.sh


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
  if [[ $machine = "Mac" ]]; then
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



#####################################################
#
#####################################################

case "$CLOUD_PROVIDER" in
        aws)
            echo "execute aws code here.  consider moving to a script.  load functions "
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
            ;;
        azure)
           echo "execute azure code here"
            ;;
        gcp)
           echo "execute gcp code here"
            ;;
        *)
            echo "you had a different choice... is this block needed?"
	    ;;
esac


