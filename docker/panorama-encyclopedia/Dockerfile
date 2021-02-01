# EncyclopeDIA requires Java 1.8
FROM openjdk:8u272-jre-buster

MAINTAINER "Brian Connolly -- MacCoss Lab"

# Create the directories
RUN mkdir /code \
    && mkdir /data

# Download EncyclopeDIA 
ENV VERSION=0.9.5
RUN cd /code; wget -O "encyclopedia-$VERSION-executable.jar" "https://bitbucket.org/searleb/encyclopedia/downloads/encyclopedia-$VERSION-executable.jar"

WORKDIR /data

