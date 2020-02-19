#!/bin/bash
wm_user=$(id -u ${USER}):$(id -g ${USER})
export wm_user=$wm_user
echo $wm_user
docker-compose up -d
sleep 40
cp -fR ./target/*.war ./warfile
