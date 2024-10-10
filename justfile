image := 'un1def/aws-efa-test'
version := '0.2'
base_image := 'dstackai/base:py3.12-0.5-cuda-12.1'
efa_version := '1.34.0'
nccl_version := '2.22.3'
ofi_version := '1.11.0'

_list:
  @just --list --unsorted

build:
  #!/bin/sh
  if docker image inspect '{{image}}:{{version}}' > /dev/null 2>&1; then
    echo '{{image}}:{{version}} already exists'
    exit 1
  fi
  docker build . \
    --pull \
    --build-arg 'BASE_IMAGE={{base_image}}' \
    --build-arg 'EFA_VERSION={{efa_version}}' \
    --build-arg 'NCCL_VERSION={{nccl_version}}' \
    --build-arg 'OFI_VERSION={{ofi_version}}' \
    --tag '{{image}}:{{version}}' --tag '{{image}}:latest'

push:
  docker push '{{image}}:{{version}}'
  docker push '{{image}}:latest'
