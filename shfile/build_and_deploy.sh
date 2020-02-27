#!/bin/bash
wm_user=$(id -u ${USER}):$(id -g ${USER})
export wm_user=$wm_user
docker-compose -f maven_build.yml up
docker-compose up -d

