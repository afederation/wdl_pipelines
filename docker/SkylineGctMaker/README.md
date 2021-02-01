## Build the Docker image ##
```
docker build -t panorama-skyline-gct:1.0 .
```

## Download a pre-built Docker image ##
This Docker image repo is available on DockerHub at [proteowizard/panorama-skyline-gct](https://hub.docker.com/repository/docker/proteowizard/panorama-skyline-gct).
It can be downloaded by running
```
docker pull proteowizard/panorama-skyline-gct:1.0
```

## Usage Examples ##

TBD


## Build and upload the Docker image to Dockerhub ##
### Build the docker image ###

```
docker build -t panorama-skyline-gct:1.0 .
```
### Pushing a new container image to image respository ###
For this image, we use Dockerhub. The image is uploaded to https://hub.docker.com/repository/docker/proteowizard/panorama-skyline-gct

The first step is to login to docker hub 

```
docker login
Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to https://hub.docker.com to create one.
Username: bconnmaccoss
Password:
Login Succeeded
```

Tag the image
```
docker tag panorama-skyline-gct:1.0 proteowizard/panorama-skyline-gct:1.0
docker tag panorama-skyline-gct:1.0 proteowizard/panorama-skyline-gct:latest
```

Now push the image 
```
docker push proteowizard/panorama-skyline-gct:1.0
docker push proteowizard/panorama-skyline-gct:latest

```
And this resulted in the image now being available at https://hub.docker.com/repository/docker/proteowizard/panorama-skyline-gct

