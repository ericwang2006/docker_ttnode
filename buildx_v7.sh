curl https://purge.jsdelivr.net/gh/ericwang2006/docker_ttnode/armv7l/ttnode
docker buildx build -t ericwang2006/ttnode:armv7 --platform=linux/arm/v7 -o type=docker ./build_dir
