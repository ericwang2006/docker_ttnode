#!/bin/sh
docker buildx build -t ericwang2006/ttnode --platform=linux/amd64,linux/arm64,linux/arm/v7 --build-arg EMULATION_PLATFORM=arm32 ./build_dir --push
