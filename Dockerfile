FROM ubuntu:focal

ARG SAMTOOLSVER=1.14
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/London

# Get dependencies
RUN apt-get -y update \
    && apt-get -y install \
        build-essential \
        libboost-all-dev \
        libgmp-dev \
        cmake \
        libhts-dev \
	libncurses5-dev \
	libbz2-dev \
	liblzma-dev \
	libcurl4-gnutls-dev \
	zlib1g-dev \
	libssl-dev \
	gcc \
	wget \
	make \
	perl \
	bzip2 \
	gnuplot \
	ca-certificates \
	gawk \
        python3-pip \
        git \
    && pip3 install distro


# Install samtools, make /data
RUN wget https://github.com/samtools/samtools/releases/download/${SAMTOOLSVER}/samtools-${SAMTOOLSVER}.tar.bz2 && \
 tar -xjf samtools-${SAMTOOLSVER}.tar.bz2 && \
 rm samtools-${SAMTOOLSVER}.tar.bz2 && \
 cd samtools-${SAMTOOLSVER} && \
 ./configure && \
 make && \
 make install && \
 mkdir /data

# set perl locale settings
ENV LC_ALL=C

# Install Octopus
ARG threads=4
ARG architecture=haswell
COPY . /opt/octopus
RUN /opt/octopus/scripts/install.py \
    --threads $threads \
    --architecture $architecture

# Cleanup git - only needed during install for commit info
RUN apt-get purge -y git \
    && rm -r /opt/octopus/.git \
    && apt-get clean \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/*

ENV PATH="/opt/octopus/bin:/usr/bin:${PATH}"

ENTRYPOINT ["octopus"]
WORKDIR /data



