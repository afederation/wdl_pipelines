## panorama-crux Dockerfile

The Dockerfile can be used to create a docker image running the daily version of [Crux](http://crux.ms). 

### Build the Docker image 
These instructions assume that you want to use the latest daily release. The first step is to find version number of the latest build. To do this, open a browser to https://noble.gs.washington.edu/crux-downloads/daily/latest-build.txt. Your browser will show a number such as `fb7f902`.

Update the Dockerfile `BUILD_NUMBER` ENV variable in the Dockerfile to be the build number found above. For example change the line 

```
ENV BUILD_NUMBER=7d0cc70
```
to 
```
ENV BUILD_NUMBER=fb7f902
```

Build the Docker image, run the command
```
docker build -t panorama-crux:3.2.<LATEST_BUILD_NUMBER> .
```
where `<LATEST_BUILD_NUMBER>` is the number found above.


### Download a pre-built Docker image
This Docker image repo is available on DockerHub at [proteowizard/panorama-crux](https://hub.docker.com/repository/docker/proteowizard/panorama-crux).
It can be downloaded by running
```
docker pull proteowizard/panorama-crux:latest
```

## Usage Examples

### Run a comet search 

docker run -it -v /data/samples/workflows/DDA_CruxCometPercolatorLimelight/testfiles:/data --rm panorama-crux:3.2.fb7f902 /crux comet --decoy_search 1 --output_percolatorfile 1 /data/2020_0212_Loomis_23_DDA_SIM60_515_35.mzML /data/Human_PD_ClinVarpep.fasta --output-dir ./crux_output --overwrite T

## Run peroclator on the comet search output 

docker run -it -v /data/samples/workflows/DDA_CruxCometPercolatorLimelight/testfiles:/data --rm panorama-crux:3.2.fb7f902 /crux percolator --pout-output T --output-dir /data/crux_output --overwrite T /data/crux_output/comet.target.pin


## Build and upload the Docker image to Dockerhub 

### Build the docker image 

```
docker build -t panorama-crux:3.2.fb7f902 .
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
docker tag panorama-crux:3.2.fb7f902 proteowizard/panorama-crux:3.2.fb7f902
docker tag panorama-crux:3.2.fb7f902 proteowizard/panorama-crux:latest
```

Now push the image 
```
docker push proteowizard/panorama-crux:3.2.fb7f902
docker push proteowizard/panorama-crux:latest
```

And this resulted in the image now being available at https://hub.docker.com/repository/docker/proteowizard/panorama-crux
