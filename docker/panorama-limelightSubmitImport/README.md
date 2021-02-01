## panorama-cruxCometPercolator2LimelightXML Dockerfile

The Dockerfile can be used to create a docker image containing: 
-  `limelightSubmitImport.jar` (from https://limelight.yeastrc.org/limelight/static/limelightSubmitImport/limelightSubmitImport.jar)
-  [Source code](https://github.com/yeastrc/limelight-core)

The version of limelightSubmitImport.jar is specified in the $VERSION environment variable in Dockerfile.



### Build the Docker image ###
```
docker build -t panorama-limelightsubmitimport.jar:latest .
```

### Download a pre-built Docker image ###
This Docker image repo is available on DockerHub at [proteowizard/panorama-limelightsubmitimport](https://hub.docker.com/repository/docker/proteowizard/panorama-limelightsubmitimport).
It can be downloaded by running
```
docker pull panorama-limelightsubmitimport.jar:latest
```
or 
```
docker pull panorama-limelightsubmitimport:1
```

## Usage Examples

### Import a Limelight XML file 

```
docker run -it -v /data/samples/workflows/DDA_CruxCometPercolatorLimelight/testfiles:/data --rm panorama-limelightsubmitimport:latest \
    java -jar /code/limelightSubmitImport.jar \
    --limelight-web-app-url= https://limelight.yeastrc.org/limelight \
    -p <project-id> \
    --user-submit-import-key=<limelight_user_key> \
    --search-description="<description of search>" 
    -i limelight.xml \
    -s <mzML file associated with limelight.xml file> \
    > limelight.log.txt

```

This assumes that limelight.xml and other file are located in the directory `/data/samples/workflows/DDA_CruxCometPercolatorLimelight/testfiles/` on your local workstation.

### Check the version of limelightSubmitImport.jar in the docker image 

```
docker run -it --rm panorama-limelightsubmitimport:latest java -jar /code/limelightSubmitImport.jar --version
````






