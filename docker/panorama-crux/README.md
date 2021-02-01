## panorama-crux Dockerfile

The Dockerfile can be used to create a docker image running v3.2 of [Crux](http://crux.ms). 

See the `daily` directory for a Dockefile to create a docker image running the lastest daily release.

### Build the Docker image 
```
docker build -t panorama-crux:3.2 .
```

### Download a pre-built Docker image
This Docker image repo is available on DockerHub at [proteowizard/panorama-crux](https://hub.docker.com/repository/docker/proteowizard/panorama-crux).
It can be downloaded by running
```
docker pull proteowizard/panorama-crux:3.2
```

## Usage Examples

### Run a comet search 

docker run -it -v /data/samples/workflows/DDA_CruxCometPercolatorLimelight/testfiles:/data --rm panorama-crux:3.2 /crux comet --decoy_search 1 --output_percolatorfile 1 /data/2020_0212_Loomis_23_DDA_SIM60_515_35.mzML /data/Human_PD_ClinVarpep.fasta --output-dir ./crux_output --overwrite T

## Run peroclator on the comet search output 

docker run -it -v /data/samples/workflows/DDA_CruxCometPercolatorLimelight/testfiles:/data --rm panorama-crux:3.2 /crux percolator --pout-output T --output-dir /data/crux_output --overwrite T /data/crux_output/comet.target.pin


## Build and upload the Docker image to Dockerhub 

### Build the docker image 

```
docker build -t panorama-crux:3.2 .
```


### Pushing a new container image to image respository. 
For this image, we use Dockerhub. The image is uploaded to https://hub.docker.com/repository/docker/proteowizard/panorama-crux

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
docker tag panorama-crux:3.2 proteowizard/panorama-crux:3.2
```
*Note: do not use the `latest` tag for this release. Release builds are never given the latest tags, as they are normally behind than the daily build.* 


Now push the image 
```
docker push proteowizard/panorama-crux:3.2

```
And this resulted in the image now being available at https://hub.docker.com/repository/docker/proteowizard/panorama-crux
