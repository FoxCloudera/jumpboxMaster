# jumpboxMaster

## This is a test...
###  Docker notes:
```
docker volume create jumpbox-vol1

# inspect
docker volume inspect jumpbox-vol1

# list volumes
docker volume ls

# run a new docker container with this volume from centos image

 docker run -it \
  --name centos_jumpbox \
  --mount source=jumpbox-vol1,target=/app \
  centos
  


  
# list all containers on host
docker ps -a  

#  start an existing container
docker start container_name

# connect to command line of this container
docker exec -it centos_jumpbox bash

#list running container
docker container ls -all

# stop a running container
docker container stop container_name

# remove a docker container
docker container rm container_name


# set git repo credentials
git config --global user.email "email address"
```

### Pull repo
```
docker pull centos
docker run -it centos

#install git
yum install -y git
cd /app
git clone https://github.com/tlepple/jumpboxMaster.git
cd /app/jumpboxMaster
```
