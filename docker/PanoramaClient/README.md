## Build the Docker image ##
```
docker build -t panorama-client-java:1.2 .
```

## Download a pre-built Docker image ##
This Docker image repo is available on DockerHub at [proteowizard/panorama-client-java](https://hub.docker.com/repository/docker/proteowizard/panorama-client-java).
It can be downloaded by running
```
docker pull proteowizard/panorama-client-java:1.2
```

## Usage Examples ##

### Download a file ###
```
docker run -it -v $PWD:/data --rm proteowizard/panorama-client-java:1.2 java -jar /code/PanoramaClient.jar -d -k "<your_panorama_api_key>" -w "https://panoramaweb.org/_webdav/home/Example Data/Workflow/%40files/Study9S_Site20_v2.sky"
```

### Upload a file ###
```
docker run -it -v $PWD:/data --rm proteowizard/panorama-client-java:1.2 java -jar /code/PanoramaClient.jar -u -k "<your_panorama_api_key>" -w "https://panoramaweb.org/_webdav/home/Example Data/Workflow/%40files/" -f "Site20_STUDY9S_Cond_6ProtMix_QC_01.sky.zip"
```

### Get a list of files in a folder ###
```
docker run -it -v $PWD:/data --rm proteowizard/panorama-client-java:1.2 java -jar /code/PanoramaClient.jar -l -k "<your_panorama_api_key>" -w "https://panoramaweb.org/_webdav/home/Example Data/Workflow/%40files/"
```


## Build and upload the Docker image to Dockerhub ##
### Build the docker image ###

```
docker build -t panorama-client-java:1.2 .
```
### Pushing a new container image to image respository ###
For this image, we use Dockerhub. The image is uploaded to https://hub.docker.com/repository/docker/proteowizard/panorama-client-java

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
docker tag panorama-client-java:1.2 proteowizard/panorama-client-java:1.2
docker tag panorama-client-java:1.2 proteowizard/panorama-client-java:latest
```

Now push the image 
```
docker push proteowizard/panorama-client-java:1.2
docker push proteowizard/panorama-client-java:latest

```
And this resulted in the image now being available at https://hub.docker.com/repository/docker/proteowizard/panorama-client-java

