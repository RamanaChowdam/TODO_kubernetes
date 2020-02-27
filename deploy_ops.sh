#!/bin/bash
set -e
wm_user=$(id -u ${USER}):$(id -g ${USER})
export wm_user=$wm_user

# help section

display_help() {
    echo "usage:  $0 -o [command] [option argument]"
    echo "usage:  $0 -h|--help "
    echo "example usage for deploy: "
    echo "         $0 -o build "
    echo "         $0 -o deploy -P {deploymentProfile} -p {mysql-password} -v {direcotry}"
    echo "         $0 -o deploy -P deployment -p Wave1234 -v /usr/local/content/myapp"
    echo "         $0 -o build-deploy -P {deploymentProfile} -p {mysql-password} -v {direcotry}"
    echo "         $0 -o importdb -p {mysql-password} -d {databasename} -f {db_dump_file_name.sql} "
    echo
    echo "Options :"
    echo "   -o                    specify the type of operation"
    echo "   -P                    Specify the type of build profile (default:deployment)"
    echo "   -p                    Specify the mysql root password"
    echo "   -v                    specify the voume directory for mysql data, tomcat logs, nginx logs"
    echo "   -d                    database name of mysql"
    echo "   -f                    dump sql file name for import"

    echo "Commands:"
    echo "   build                 To build code and create war file"
    echo "   deploy                To Create, start containers "
    echo "   build-deploy          To build code, create war file, Create, start containers"
    echo "   start                 Start services"
    echo "   stop                  To Stop services"
    echo "   restart               To Restart containers"
    echo "   remove                To Stop and remove containers, networks, images"
    echo "   importdb              To Import dumpfile to containers"
    

}

# function for deploying containers
deploy_containers() {
    #docker-compose build nginx  #TODO enable it.
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

build_app() {
    #function for build the code using maven
    docker-compose -f app-build-compose.yml up

}
deploy_app() {
             if [ -z "$build_profile" ]
            then
                read -p "Enter type of maven build(deployment) :" build_profile_typed
                export maven_build=${build_profile_typed:-deployment}
            else
                export maven_build=${build_profile}
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
}

# condition for display the help
if [ "$#" == 0 -o "$1" == '--help' -o "$1" == '-help' -o "$1" == 'help' -o "$1" == 'h' -o "$1" == '--h' ]
then
    display_help
    exit
fi
# .env read
source .env

#TODO: docker and docker-compose needs to be installed. 
# getops statement for optional arguments
while getopts o:P:p:d:f:v:h: options
do
    case "${options}" in
            o) command_arg=${OPTARG};;
            P) build_profile=${OPTARG};;
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
            deploy_app
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
            build_app
            ;;
        build-deploy)
            build_app
            deploy_app
            deploy_containers
            docker-compose ps
            ;;
        *) display_help;;
    esac
    
fi


#TODO: enable export option. 
#TODO: doc to configure multiple webapps. 
#TODO: scale webapp