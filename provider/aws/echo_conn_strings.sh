#!/bin/bash
 
#########################################################
# BEGIN
#########################################################

###########################################################################################################
# import parameters and utility functions 
###########################################################################################################
. $starting_dir/provider/aws/demo.properties
. $starting_dir/provider/aws/prereq_utils.sh
. $starting_dir/provider/aws/.info


GET_PUBLIC_IP=`aws --output json --region ${AWS_REGION:?} ec2 describe-instances --instance-id ${oneNodeInstanceId:?} | jq -r ".Reservations[].Instances[].PublicIpAddress"`

echo
echo
echo
echo "		---------------------------------------------------------------------------------------------------------------------------------------------"
echo "		---------------------------------------------------------------------------------------------------------------------------------------------"
echo "		|		   SSH Connection String:				 		                                                             "
echo "		---------------------------------------------------------------------------------------------------------------------------------------------"
echo "		---------------------------------------------------------------------------------------------------------------------------------------------"
echo "		|	ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $KEY_FILE_PATH$KEY_FILENAME $SSH_USERNAME@$GET_PUBLIC_IP 	 "
echo "		---------------------------------------------------------------------------------------------------------------------------------------------"
echo "		---------------------------------------------------------------------------------------------------------------------------------------------"
echo
echo
echo "		---------------------------------------------------------------------------------------------------------------------------------------------"
echo "		---------------------------------------------------------------------------------------------------------------------------------------------"
echo "		| 		Proxy Connection String:    		                                           "
echo "		---------------------------------------------------------------------------------------------------------------------------------------------"
echo "		---------------------------------------------------------------------------------------------------------------------------------------------"
echo "		|       ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $KEY_FILE_PATH$KEY_FILENAME -CND 8157 $SSH_USERNAME@$GET_PUBLIC_IP          " 
echo "		---------------------------------------------------------------------------------------------------------------------------------------------"
echo "		---------------------------------------------------------------------------------------------------------------------------------------------"
echo
echo
echo
echo
echo
echo

