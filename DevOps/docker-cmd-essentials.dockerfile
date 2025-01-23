##docker commands essentials

## Docker Version and Information 
docker --version                                        # Show Docker version
docker info                                             # Display system-wide information about Docker

## Workig with Containers
docker ps                                               # List running containers
docker ps -a                                            # List all running containers (running and stopped)
docker run <image>
docker run -d <image>

docker run --name <name> <image>
docker stop <container>
docker start <container>
docker restart <container>
docker rm <container>
docker exec it <container> /bin/bash


## Managing Images
docker network ls
docker network create <name>
docker network inspect <network>
docker network connect <network> <container>
docker network disconnect <network> <container>
docker network rm <network>

 