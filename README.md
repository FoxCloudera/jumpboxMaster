# jumpboxMaster

#  The goal of this repo is to setup cloud security components and build out instances.

## Notes:
*  Currently only works on AWS.   More to come soon...
*  This was built and tested on Docker Version: 19.03.1
*  This assumes you already have Docker installed


##  Docker Setup steps:
```
# Create a docker volume to persist data
docker volume create jumpbox-vol1

# inspect volume
docker volume inspect jumpbox-vol1

# list volumes
docker volume ls

# run a new docker container with this volume from centos image

 docker run -it \
  --name centos_jumpbox \
  --mount source=jumpbox-vol1,target=/app \
  centos bash
  
```

### Pull git repo to build new instance

```
#install git
yum install -y git
cd /app
git clone https://github.com/tlepple/jumpboxMaster.git
cd /app/jumpboxMaster


```

##  Update `demo.properties` with your info.

```
vi ./provider/aws/demo.properties

OWNER_TAG=<your userid here>
AWS_RGION=<your region here>

# I will fix this soon
AMI_ID=<centos ami for your region>

#If you already have a security group and subnet ID set:

setup_prereqs=false and update the values of security group and subnet ID to your from your VPC.
```

##  Build your instance:

```
export AWS_ACCESS_KEY_ID=<your key>
export AWS_SECRET_ACCESS_KEY=<your secret key>
export AWS_DEFAULT_REGION=<aws region you want to run in>

cd /app/jumpboxMaster
. bin/setup.sh aws
```

##  Terminate all aws items: 
* VPC, Security Groups, Route Tables, Subnet, Internet Gateway, PEM File and EC2 Instance.

```
cd /app/jumpboxMaster
. provider/aws/terminate_everything.sh

```

## Terminate just the ec2 instance:

```
cd /app/jumpboxMaster
. provider/aws/terminate_ec2.sh

```

---
---
##  Useful docker command reference:
---
---


```
# list all containers on host
docker ps -a

#  start an existing container
docker start centos_jumpbox

# connect to command line of this container
docker exec -it centos_jumpbox bash

#list running container
docker container ls -all

# stop a running container
docker container stop centos_jumpbox

# remove a docker container
docker container rm centos_jumpbox

# list docker volumes
docker volume ls

# remove a docker volume
docker volume rm jumpbox-vol1

```

# Start a stopped Cloud Instance:
```
cd /app/jumpboxMaster
. bin/start_instance.sh
```

# Stop a running Cloud Instance:
```
cd /app/jumpboxMaster
. bin/stop_instance.sh
```
