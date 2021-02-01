## panorama-cruxCometPercolator2LimelightXML Dockerfile

The Dockerfile can be used to create a docker image containing: 
-  `cruxCometPercolator2LimelightXML.jar` (from https://github.com/yeastrc/limelight-import-crux-comet-percolator/releases)

The version of cruxCometPercolator2LimelightXML.jar is specified in the $VERSION environment variable in Dockerfile.

The Dockerfile uses version `2.2.0`.


### Build the Docker image ###
```
docker build -t panorama-cruxcometpercolator2limelightxml:2.2.0 .
```

### Download a pre-built Docker image ###
This Docker image repo is available on DockerHub at [proteowizard/panorama-cruxcometpercolator2limelightxml](https://hub.docker.com/repository/docker/proteowizard/panorama-cruxcometpercolator2limelightxml/).
It can be downloaded by running
```
docker pull panorama-cruxcometpercolator2limelightxml:latest
```
or 
```
docker pull panorama-cruxcometpercolator2limelightxml:2.2.0
```

## Usage Examples

### Convert Percolator results

docker run -it -v /data/samples/workflows/DDA_CruxCometPercolatorLimelight/testfiles:/data --rm panorama-cruxcometpercolator2limelightxml:latest java -jar /code/cruxCometPercolator2LimelightXML.jar -d /data/crux_output -f /data/Human_PD_ClinVarpep.fasta -o 2020_0212_Loomis_23_DDA_SIM60_515_35.crux.limelight.xml

This assumes that the comet and percolator results are located in the directory `/data/samples/workflows/DDA_CruxCometPercolatorLimelight/testfiles/crux_output` on your local workstation.

### Check the version of cruxCometPercolator2LimelightXML.jar in the docker image 

```
docker run -it --rm panorama-cruxcometpercolator2limelightxml:latest java -jar /code/cruxCometPercolator2LimelightXML.jar --version
````






