FROM dancooke/octopus

MAINTAINER Vincent Cahais <cahaisv@iarc.who.int>
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y samtools
