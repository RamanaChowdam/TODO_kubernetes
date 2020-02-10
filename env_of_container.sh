#!/bin/bash
set -e
env_variables() {
    # Taking env variables for mysql container
    echo "NOTE: Run shell script as a root user"
    echo "enter env variables for containers"
    echo
    read -p "enter mysql root password :" mysql_root_password
    read -p "enter mysql user name :" mysql_user
    read -p "enter mysql password for user $mysql_user:" mysql_password
    read -p "enter database name :" database_name

    # taking container names
    read -p "enter container name for mysql db service :" db_service_container_name
    read -p "enter container name for webapp service :" webapp_service_container_name
    read -p "enter container name for nginx service :" nginx_service_container_name

    # persistant volume location for mysql container
    read -p "enter mysql volume directory path in host :" mysql_volume_directory
    if [ -d "$mysql_volume_directory" ]
    then
        echo "The volume directory already exists in host,your selected directory path is $mysql_volume_directory"
    elif [ ! -d "$mysql_volume_directory" ]
    then
        echo "The provided volume directory path already not exists in host"
        mkdir -p $mysql_volume_directory
        echo "The directory path created successfully in host,your selected directory path is $mysql_volume_directory"
    else
        echo "provide correct directory path and script as a root user"
    fi

    # persistant volume location for webapp container
    read -p "enter webapp volume directory path in host :" webapp_volume_directory
    if [ -d "$webapp_volume_directory" ]
    then
        echo "The volume directory already exists in host,your selected directory path is $webapp_volume_directory"
    elif [ ! -d "$webapp_volume_directory" ]
    then 
        echo "The provided volume directory path already not exists in host"
        mkdir -p $webapp_volume_directory
        echo "The volume path is successfully created in host,your selected directory path is $webapp_volume_directory"
    else
        echo "provide correct directory path and run script as a root user"
    fi

    # persistant volume location for nginx
    read -p "enter nginx volume directory path in host :" nginx_volume_directory
    if [ -d "$nginx_volume_directory" ]
    then
        echo "The volume directory already exists in host,your selected directory path is $nginx_volume_directory"
    elif [ ! -d "$nginx_volume_directory" ]
    then
        echo "The provided directory path is already not exists in host"
        mkdir -p $nginx_volume_directory
        echo "The volume path is successfully created in host,your selected directory path is $nginx_volume_directory"
    else
        echo "provide correct directory path and run script as a root user"
    fi
}

exporting() {
        export root_password=$mysql_root_password 
        export mysql_user_name=$mysql_user  
        export user_password=$mysql_password 
        export mysql_database_name=$database_name 
        export wm_root_password=$mysql_root_password 
        export mysql_container_name=$db_service_container_name 
        export webapp_container_name=$webapp_service_container_name 
        export nginx_container_name=$nginx_service_container_name 
        export mysql_persistant_volume=$mysql_volume_directory 
        export webapp_persistant_volume=$webapp_volume_directory 
        export nginx_persistant_volume=$nginx_volume_directory 
}

# help section

display_help() {
    echo "Usage: sudo $0 [Option...]   [Command]
        sudo $0 -h|--help"
    echo "Commands:"
    echo "   deploy                Create and start containers"
    echo "   help                  Get help on a command"
    echo "   restart               Restart containers"
    echo "   start                 Start services"
    echo "   stop                  Stop services"
    echo "   down                  Stop and remove containers, networks, images, and volumes"
    echo "   import                import .sql file to container"

}
deploy_containers() {
    env_variables
    exporting
    docker-compose up -d
}
restart_containers() {
    exporting
    docker-compose restart
}
stop_containers() {
    exporting
    docker-compose stop
}
start_containers() {
    exporting
    docker-compose start
}
down_containers() {
    exporting
    docker-compose down
}
import_db() {
    exporting
    echo "you can import dumpfile only if your containers are up"
    echo
    read -p "if your containers up enter (y) , or enter (n) :" import_decision
    if [ "$import_decision" == {Y|y} ]
    then
        echo "list of sql files in current directory"
        ls *.sql
        read -p "enter your dump.sql file name :" dumpfile
        if [ "$dumpfile" == "*.sql" ]
        then 
            docker cp $dumpfile $db_service_container_name:$dumpfile
        else
            echo "please select right file to import"
        fi
    elif [ "$import_decision" == {N|n} ]
    then
    echo "your containers are not up so you cant perform operation"
    fi
}

case "$1" in  
        -h|--help)
                display_help
                ;;
        deploy)
                deploy_containers 
                ;;
        stop)
                stop_containers 
                ;;
        restart)
                restart_containers 
                ;;
        start)
                start_containers 
                ;;
        down)
                down_containers 
                ;;
        import)
                import_db 
                ;;
        *)
                echo "This shell script is to perform given operations only"
                echo "only you can perfom below operations"
                display_help
                ;;
esac





























# copying dump.sql to mysql container



