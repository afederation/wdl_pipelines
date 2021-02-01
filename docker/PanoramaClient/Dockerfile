FROM openjdk:14-ea-8-alpine

MAINTAINER "Vagisha Sharma -- MacCoss Lab"

# Install bash
RUN apk update && apk add bash

RUN java -version
RUN javac -version

# Create the directories
RUN mkdir /code \
    && mkdir /data

# Add the required files to the container.
ADD PanoramaClient.jar /code

WORKDIR /data

# RUN java -jar /code/PanoramaClient.jar
