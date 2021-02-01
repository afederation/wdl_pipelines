## panorama-encyclopedia Dockerfile

The Dockerfile can be used to create a docker image containing: 
-  `EncyclopeDIA` (from https://bitbucket.org/searleb/encyclopedia/wiki/Home)

The version of encyclopedia is specified in the $VERSION environment variable in Dockerfile.

The Dockerfile uses version `0.9.5`.


### Build the Docker image ###
```
docker build -t panorama-encyclopedia:0.9.5 .
```

docker build -t panorama-encyclopedia:0.9.4 -e "VERSION=0.9.4" .

### Download a pre-built Docker image ###
This Docker image repo is available on DockerHub at [proteowizard/panorama-encyclopedia](https://hub.docker.com/repository/docker/proteowizard/panorama-encyclopedia/).
It can be downloaded by running
```
docker pull proteowizard/panorama-encyclopedia:latest
```
or 
```
docker pull proteowizard/panorama-encyclopedia:0.9.5
```

## Usage Examples

### Generate global quantitative results

docker run -it -v /data/samples/workflows/DIA_msconvertEncyclopedia/testfiles:/data --rm panorama-encyclopedia:0.9.5 java -jar /code/encyclopedia-0.9.5-executable.jar -Xmx8g -libexport -a true -l /data/library.dlib -f /data/sequences.fasta -i /data -o /data/output.elib


### Check the version of encyclopedia in the docker image 

```
docker run -it --rm panorama-encyclopedia:0.9.5 java -jar /code/encyclopedia-0.9.5-executable.jar --version 
````

