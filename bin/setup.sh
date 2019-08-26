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

#####################################################
# first check if JQ is installed
#####################################################
log "Installing jq"

jq_v=`jq --version 2>&1`
if [[ $jq_v = *"command not found"* ]]; then
  if [[ $machine = "Mac" ]]; then
    sudo curl -L -s -o jq "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64"
  else
    sudo curl -L -s -o jq "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64"
  fi 
  sudo chmod +x ./jq
  sudo cp jq /usr/bin
else
  log "jq already installed. Skipping"
fi

jq_v=`jq --version 2>&1`
if [[ $jq_v = *"command not found"* ]]; then
  log "error installing jq. Please see README and install manually"
  echo "Error installing jq. Please see README and install manually"
  exit 1 
fi  
