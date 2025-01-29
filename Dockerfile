# Build Docker in root project cause some file need to copy to docker after build

FROM ubuntu:24.04 AS build

USER root

WORKDIR /tmp

RUN DEBIAN_FRONTEND=noninteractive apt update \
  && DEBIAN_FRONTEND=noninteractive apt -y upgrade wget \
  && wget https://apt.llvm.org/llvm.sh \
  && chmod a+x llvm.sh \
  && DEBIAN_FRONTEND=noninteractive apt -y install lsb-release software-properties-common gnupg bc bison ca-certificates curl flex gcc git libc6-dev libssl-dev openssl ssh zip zstd sudo make gcc-arm-linux-gnueabi gcc-aarch64-linux-gnu glibc-source glibc-tools linux-headers-generic

RUN DEBIAN_FRONTEND=noninteractive ./llvm.sh 20

RUN apt autoremove -y && apt autoclean -y && apt clean --dry-run -y && rm -rf /tmp/*

FROM ubuntu:24.04 AS main

COPY --from=build / /
COPY ./linked.sh /tmp/linked.sh

RUN ls /tmp && /tmp/linked.sh

WORKDIR /data

USER root
