#!/bin/sh
docker buildx build -t ericwang2006/ttnode --platform=linux/amd64,linux/arm64,linux/arm/v7 ./build_dir --push