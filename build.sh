#!/bin/bash
set -x
docker rm -f cdh
set -e
#docker build --rm -t cdh .
docker build --no-cache=true --rm -t cdh .
docker run  -m 5000M --name cdh -i -t -h flipper \
	--expose=1024-65535 \
	-p 2181:2181 \
	-p 8020:8020 \
	-p 8888:8888 \
	-p 11000:11000 \
	-p 11443:11443 \
	-p 9090:9090 \
	-p 8088:8088 \
	-p 19888:19888 \
	-p 9092:9092 \
	-p 8983:8983 \
	-p 16000:16000 \
	-p 16001:16001 \
	-p 42222:22 \
	-p 8042:8042 \
	-p 60010:60010 \
	cdh
