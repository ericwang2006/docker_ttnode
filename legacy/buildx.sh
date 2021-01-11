curl https://purge.jsdelivr.net/gh/ericwang2006/docker_ttnode/aarch64/ttnode
docker buildx build -t ericwang2006/ttnode --platform=linux/arm64 -o type=docker ./build_dir
