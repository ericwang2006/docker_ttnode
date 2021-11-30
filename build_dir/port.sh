#!/bin/bash
netstat -tunlp | grep ttnode | grep -v '127.0.0.1\|17331' | awk '{sub(/0.0.0.0:/,""); print $1,$4}' | sort -k 2n -k 1
