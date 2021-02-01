FROM ubuntu:latest

MAINTAINER "Vagisha Sharma -- MacCoss Lab"

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y libtext-csv-xs-perl
 

# Create the directories
RUN mkdir /data
RUN mkdir /code

# Add the required files to the container.
ADD skyline_gct_maker.pl /code

WORKDIR /data