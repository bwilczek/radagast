#!/bin/bash

docker stop rabbit-radagast
docker rm rabbit-radagast

docker run -d \
  --hostname rabbit-radagast \
  --name rabbit-radagast \
  -p 5672:5672 \
  -p 15672:15672 \
  -e RABBITMQ_ERLANG_COOKIE='radagast' \
  rabbitmq:3

sleep 3
docker exec rabbit-radagast rabbitmq-plugins enable rabbitmq_management
docker restart rabbit-radagast
