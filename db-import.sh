#!/bin/bash
docker ps
read -p "enter container name :" container_name
ls *.sql
read -p "enter dumpfile name :" dumpfile_name
docker cp $dumpfile_name $container_name:$dumpfile_name
docker exec -it $container_name  mysql -uroot -pcloud -Dtodo

