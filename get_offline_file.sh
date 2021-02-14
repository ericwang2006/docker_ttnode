#!/bin/bash
function save_img() {
	v=$(echo $manifest | jq -r ".[] | select(.Descriptor.platform.architecture==\"$1\")|.Descriptor.digest")
	docker pull $image_name:$tag@$v

	m=$(echo $manifest | jq -r ".[] | select(.Descriptor.platform.architecture==\"$1\")|.SchemaV2Manifest.config.digest")
	m=${m:7:12}
	docker tag $m $image_name:$tag
	docker save $image_name:$tag | gzip >"$prefix"_"$2"_"$tag".tar.gz
}

image_name="ericwang2006/ttnode"
tag="latest"
prefix="ttnode"
manifest=$(docker manifest inspect -v $image_name:$tag)
save_img "amd64" "amd64"
save_img "arm64" "arm64"
save_img "arm" "arm32"
