# jumpboxMaster

## Notes:
*  This has currently only been developed to run on AWS.
*  This was built and tested on Docker Version: 19.03.1  

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
  centos
  
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
```

##  Build your instance:

```
cd /app/jumpboxMaster
. bin/setup.sh aws
```

##  Terminate all aws items: 
* VPC, Security Groups, Route Tables, Subnet, Internet Gateway, PEM File and EC2 Instance.

```
cd /app/jumpboxMaster
. provider/aws/terminate.sh
```

##  Useful docker command reference:

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

```
