FROM debian:buster-slim

MAINTAINER "Brian Connolly -- MacCoss Lab"

# Make directories 
RUN mkdir /data

RUN apt-get update \
      && apt-get -y install ca-certificates unzip curl libgomp1 netbase \
      && rm -rf /var/lib/apt/lists/*

# Download and install Crux 3.2
RUN curl -o crux-3.2.Linux.x86_64.zip https://noble.gs.washington.edu/crux-downloads/crux-3.2/crux-3.2.Linux.x86_64.zip \
    && unzip crux-3.2.Linux.x86_64.zip \
    && mv ./crux-3.2.Linux.x86_64/bin/crux /

WORKDIR /data

