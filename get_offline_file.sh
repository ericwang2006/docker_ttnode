#!/bin/bash
function save_img() {
	v=$(cat /tmp/tt.json | jq -r ".[] | select(.Descriptor.platform.architecture==\"$1\")|.Descriptor.digest")
	docker pull ericwang2006/ttnode:latest@$v

	m=$(cat /tmp/tt.json | jq -r ".[] | select(.Descriptor.platform.architecture==\"$1\")|.SchemaV2Manifest.config.digest")
	m=${m:7:12}
	docker tag "$m" ericwang2006/ttnode:latest
	docker save ericwang2006/ttnode:latest | gzip >ttnode_"$2"_latest.tar.gz
}

docker manifest inspect -v ericwang2006/ttnode >/tmp/tt.json
rm -f ttnode*latest.tar.gz
save_img "amd64" "amd64"
save_img "arm64" "arm64"
save_img "arm" "arm32"
rm /tmp/tt.json
