#!/bin/bash
set -e

# help section

display_help() {
    echo "usage: sudo $0 -o [command] [option argument]"
    echo "usage: sudo $0 -h|--help "
    echo "example usage for deploy: "
    echo "        sudo $0 -o deploy -P {deploymentProfile} -p {mysql-password} -v {direcotry}"
    echo "        sudo $0 -o deploy -P deployment -p Wave1234 -v /usr/local/content/myapp"
    echo "        sudo $0 -o import-db -p {mysql-password} -d {databasename} -f {db_dump_file_name.sql} "
    echo
    echo "Options :"
    echo "   -o                    specify the type of operation"
    echo "   -P                    Specify the type of build profile (default:deployment)"
    echo "   -p                    Specify the mysql root password"
    echo "   -v                    specify the voume directory for mysql data, tomcat logs, nginx logs"
    echo "   -d                    database name of mysql"
    echo "   -f                    dump sql file name for import"
    echo "   -s                    service name(webapp/nginx/all) to build"
    echo "Commands:"
    echo "   deploy                Create, start containers "
    echo "   start                 Start services"
    echo "   stop                  Stop services"
    echo "   restart               Restart containers"
    echo "   remove                Stop and remove containers, networks, images"
    echo "   importdb              Import dumpfile to containers"
    echo "   build                 To build and rebuild the service"

}

# function for deploying containers
deploy_containers() {
    #docker-compose build nginx  #TODO enable it.
    #docker-compose build webapp #TODO enable it.
    docker-compose up -d
}
# function for restarting containers
restart_containers() {
    docker-compose restart
}
# function for stop the containers
stop_containers() {
    docker-compose stop
}
# function for start the containers
start_containers() {
    docker-compose start
}
# function for remove the containers ,netwok and images
down_containers() {
    docker-compose down --rmi=all 
}

build_service() { 
    # function for build the image of the service
    if [ $service_name == "all" ]; then
            docker-compose build nginx
            docker-compose build webapp
    else    
            docker-compose build $service_name 
    fi  
}

# condition for display the help
if [ "$#" == 0 -o "$1" == '--help' -o "$1" == '-help' -o "$1" == 'help' -o "$1" == 'h' -o "$1" == '--h' ]
then
    display_help
    exit
fi
# .env read
source .env
echo "$mysql_root_password"
echo "$data_directory"
echo "$build_type"

#TODO: docker and docker-compose needs to be installed. 
# getops statement for optional arguments
while getopts o:P:p:d:f:v:h:s: options
do
    case "${options}" in
            o) command_arg=${OPTARG};;
            P) build_type=${OPTARG};;
            s) service_name=${OPTARG};;
            p) mysql_root_password=${OPTARG};;
            d) database_name=${OPTARG};;
            f) dumpfile=${OPTARG};;
            v) data_directory=${OPTARG};;
            h) display_help
    esac
done

user_dir=$(eval echo "~$USER")
app_name=${PWD##*/} 
# if no of positional arguments is greater than zero performs the provided operations
if [ "$#" -gt 1 ]
then
    case "$command_arg" in
        deploy)    # it creates the container and start the conatainer
            echo "$mysql_root_password"
            echo "$data_directory"
            echo "$build_type"
            
            if [ -z "$build_type" ]
            then
                read -p "Enter type of maven build(deployment) :" build_type_typed
                export maven_build=${build_type_typed:-deployment}
            else
                export maven_build=${build_type}
            fi

            if [ -z "$mysql_root_password" ]
            then
                read -p "Enter mysql root pasword(Wave123) :" mysql_root_password_typed
                export root_password=${mysql_root_password_typed:-Wave123}
            else
                export root_password=${mysql_root_password}
            fi

            if [ -z "$data_directory" ]
            then
                data_directory_default=$user_dir/$app_name/
                read -p "Enter data directory path($data_directory_default) :" data_directory_typed
                export data_directory_input=${data_directory_typed:-$data_directory_default}
            else
                export data_directory_input=${data_directory}
            fi
          
           mysql_persistant_volume_var=$data_directory_input/mysql
           webapp_persistant_volume_var=$data_directory_input/webapp-logs
           nginx_persistant_volume_var=$data_directory_input/nginx-logs
           export mysql_persistant_volume=$mysql_persistant_volume_var
           export nginx_persistant_volume=$nginx_persistant_volume_var
           export webapp_persistant_volume=$webapp_persistant_volume_var

            mkdir -p $data_directory_input
            mkdir -p $webapp_persistant_volume
            mkdir -p $mysql_persistant_volume
            mkdir -p $nginx_persistant_volume
            deploy_containers
            docker-compose ps
            ;;
        
        importdb) # import the dump to the mysql database  
                db_service_container_name=$(docker-compose ps | grep db | awk '{print $1}')
                if [ -z "$mysql_root_password" ]
                then
                    read -p "Enter mysql root pasword(Wave123) :" mysql_root_password
                    mysql_root_password=${mysql_root_password:-Wave123}
                fi
               
                if [ ! -z "$mysql_root_password" -a ! -z "$database_name" -a ! -z "$dumpfile" ]
                then
                    docker exec -i $db_service_container_name mysql -uroot -p$mysql_root_password -e "create database if not exists $database_name"
                    docker exec -i $db_service_container_name mysql -uroot -p$mysql_root_password --database=$database_name < $dumpfile
                elif [ -z "$mysql_root_password" -o -z "$dbservice_container_name" -o -z "$database_name" -o -z "$dumpfile" ]
                then
                 if [ -z "$database_name" ]
                    then
                    echo "Mandatory argment database name is missing" 
                 fi
                 if [ -z "$dumpfile" ]
                    then
                    echo "Mandatory argument db_dump_file_name name is missing" 
                 fi
                    echo "Usage :  sudo $0 -o importdb -p {mysql-password} -d {databasename} -f {db_dump_file_name.sql} "
                fi
                ;;
        start)
            start_containers
            ;;
        stop)
            stop_containers
            ;;
        restart)
            restart_containers
            ;;
        remove)
            down_containers
            ;;
        build)
             if [ -z "$service_name" ]
                then
                    echo "List of services can be re-build  "
                    echo " 1. webapp"
                    echo " 2. nginx" 
                    echo " 3. all"
                    read -p "Select service to build a image of service(webapp) :" service_name_typed
                    service_name=${service_name:-"webapp"}
            fi
            if [ "$service_name" == "webapp" -o "$service_name" == "all" ];
                then
                    if [ -z "$build_type" ]
                    then
                        read -p "Enter type of maven build(deployment) :" build_type_typed
                        export maven_build=${build_type_typed:-deployment}
                    else
                        export maven_build=${build_type}
                    fi
            fi
            build_service
            ;;

        *) display_help;;
    esac
    
fi


#TODO: enable export option. 
#TODO: doc to configure multiple webapps. 
#TODO: scale webapp
#TODO: multi stage docker file volumes. 