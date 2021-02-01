FROM openjdk:14-ea-8-alpine

MAINTAINER "Brian Connolly -- MacCoss Lab"

# Install bash
RUN apk update && apk add bash

# Create the directories
RUN mkdir /code \
    && mkdir /data

# Download limelightSubmitImport.jar
RUN cd /code; \
    wget -O limelightSubmitImport.jar "https://limelight.yeastrc.org/limelight/static/limelightSubmitImport/limelightSubmitImport.jar"; \
    java -jar /code/limelightSubmitImport.jar -V | grep Version

WORKDIR /data

