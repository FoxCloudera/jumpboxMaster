#!/bin/bash

# define starting dir
$starting_dir=`pwd`


###########################################################################################################
# import parameters and utility functions 
###########################################################################################################
. $starting_dir/provider/aws/demo.properties
. $starting_dir/provider/aws/prereq_utils.sh
. $starting_dir/provider/aws/.info


# function for logging
log() {
    echo "[$(date)]: $*"
    echo "[$(date)]: $*" >> terminate.log
}

# delete all the prereqs by calling the function
terminate_prereqs

