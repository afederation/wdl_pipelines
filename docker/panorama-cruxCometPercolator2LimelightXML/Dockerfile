FROM openjdk:14-ea-8-alpine

MAINTAINER "Brian Connolly -- MacCoss Lab"

# Install bash
RUN apk update && apk add bash

# Create the directories
RUN mkdir /code \
    && mkdir /data

# Download cruxCometPercolator2LimelightXML.jar
ENV VERSION=2.2.0
RUN cd /code; wget -O cruxCometPercolator2LimelightXML.jar "https://github.com/yeastrc/limelight-import-crux-comet-percolator/releases/download/v$VERSION/cruxCometPercolator2LimelightXML.jar"


WORKDIR /data

