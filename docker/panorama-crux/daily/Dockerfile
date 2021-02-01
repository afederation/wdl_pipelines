# This Dockerfile will use the most recent version or daily
# release of Crux. This is the version you would download
# if you clicked on the button which says 
# "I agree to the licensing terms, download the most recent build of Crux"
# 
# To find the BUILD_NUMBER for the latest build, open your browser and goto 
# https://noble.gs.washington.edu/crux-downloads/daily/latest-build.txt

FROM debian:buster-slim

MAINTAINER "Brian Connolly -- MacCoss Lab"

ENV BUILD_NUMBER=fb7f902

# Make directories 
RUN mkdir /data

RUN apt-get update \
      && apt-get -y install ca-certificates unzip curl libgomp1 netbase \
      && rm -rf /var/lib/apt/lists/*

# Download and install Crux 3.2
RUN curl -o "crux-3.2.$BUILD_NUMBER.Linux.x86_64.zip" "https://noble.gs.washington.edu/crux-downloads/daily/crux-3.2.$BUILD_NUMBER.Linux.x86_64.zip" \
    && unzip "crux-3.2.$BUILD_NUMBER.Linux.x86_64.zip" \
    && mv "./crux-3.2.Linux.x86_64/bin/crux" / \
    && rm "crux-$VERSION.Linux.x86_64.zip" \
    && rm -rf  "./crux-3.2.Linux.x86_64/"

WORKDIR /data
