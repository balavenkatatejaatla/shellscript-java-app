#!/bin/bash

set -e

#Global variable
MYSQL_PATH=/root/studentapp/scripts/script.sql
TOMCAT_PATH=/root/studentapp/scripts/studentapp.war


log(){

    local log_level=$1
    local messege=$2

    echo "$(date) $log_level $messege"


}

log "INFO" "Script starts"


install_java(){

	log "INFO" "update & Install the java"
	sudo apt update > /dev/null 
	log "INFO" "Update is successfull"
	#sudo apt install openjdk-8-jdk -y > /dev/null 2>&1
	#log "SUCCESS" "Java installation complete"
	dpkg-query -W openjdk-8-jdk > /dev/null || { exit_status=1; }
	exit_status=$(( exit_status == 0 ? 0 : 1))
	if [ $exit_status -eq 0 ]; then
		echo "java is already installed in the system"
	else
		echo "Installing the java"
		sudo apt install openjdk-8-jdk -y > /dev/null 2>&1
		log "SUCCESS" "Java installation complete"
	fi
}


install_tomcat(){

	log "INFO" "Downloading the tomcat8 war"
	wget -nc https://dlcdn.apache.org/tomcat/tomcat-8/v8.5.100/bin/apache-tomcat-8.5.100.tar.gz > /dev/null
	log "INFO" "Download is success"
 	log "INFO" "Ectracting the tar"
	sudo tar -zxvf apache-tomcat-8.5.100.tar.gz -C /opt/ > /dev/null
	log "INFO" "Extract is succ"
	log "INFO" "Tomcat user check"
	if id tomcat8; then
		echo "user is tomcat8"
	else
		echo "user creation tomcat8"
		sudo adduser --system --group tomcat8 > /dev/null
		echo "user is created"
	fi
	log "INFO" "Changing the permissions"
	sudo chown -R tomcat8:tomcat8 /opt/apache-tomcat-8.5.100 > /dev/null
	log "INFO" "Perm got changed"
	



}


service_tomcat(){
	log "INFO" "Tomcat service creation"
	sudo cat > /etc/systemd/system/tomcat.service <<EOF
	
	[Unit]
	Description=Apache Tomcat Web Application Container
	After=network.target

	[Service]
	Type=forking
	User=tomcat8
	Group=tomcat8
	Environment=CATALINA_PID=/opt/apache-tomcat-8.5.100/temp/tomcat.pid
	Environment=CATALINA_HOME=/opt/apache-tomcat-8.5.100
	Environment=CATALINA_BASE=/opt/apache-tomcat-8.5.100
	Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
	ExecStart=/opt/apache-tomcat-8.5.100/bin/startup.sh
	ExecStop=/opt/apache-tomcat-8.5.100/bin/shutdown.sh

	[Install]
	WantedBy=multi-user.target
EOF
	log "INFO" "Service created"
	log "INFO" "REload start and enable of tomcat service"
	sudo systemctl daemon-reload > /dev/null
	sudo systemctl enable tomcat > /dev/null
	sudo systemctl restart tomcat > /dev/null
	log "INFO" "Tomcat Service is started"

}


install_mysql(){

	log "INFO" "MYSQL create"
	sudo apt update && apt install mysql-server -y > /dev/null
	log "INFO" "MYSQL is installed"
	log "INFO" "SERVICE ENABLED/ RESTART"
	sudo systemctl enable mysql > /dev/null
	sudo systemctl restart mysql > /dev/null
	log "INFO" "Service started mysql"

}


configure_mysql(){
	log "INFO" "Configure MYSQL"
	sudo sed -i 's/bind-address\s*=.*$/bind-address=0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
	log "INFO" "Changes are added"
	log "INFO" "Restart MYSQL"
	sudo systemctl restart mysql > /dev/null
	log "INFO" "MYSQL restart success"

}

mysql_driver(){

	log "INFO" "COPY the driver"
	sudo wget -nc -P /opt/apache-tomcat-8.5.100/lib https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.30/mysql-connector-java-8.0.30.jar
	log "INFO" "Download successfull"
	log "INFO" "Change the permissions"
	chown -R tomcat8:tomcat8 /opt/apache-tomcat-8.5.100/lib/mysql-connector-java-8.0.30.jar
	log "INFO" "MYSQL connector jar username changed"
}

create_db(){

	log "INFO" "Create DB"
	sudo mysql < $MYSQL_PATH
	log "INFO" "script db created"

}

configure_tomcat(){

	log "INFO" "Configure the context.xml"

	sudo sed -i '/<\/Context>/i\<Resource name="jdbc/TestDB" auth="Container" type="javax.sql.DataSource" maxActive="50" maxIdle="30" maxWait="10000" username="student" password="student@1" driverClassName="com.mysql.cj.jdbc.Driver" url="jdbc:mysql://10.0.0.4:3306/studentapp?useSSL=false&amp;allowPublicKeyRetrieval=true"/>' /opt/apache-tomcat-8.5.100/conf/context.xml

	log "INFO" "Context.xml jdbc copied"
	sudo systemctl restart tomcat
	log "INFO" "REstart the tomcat"

}

deploy_war(){

	log "INFO" "COPY to webapps"
	sudo cp -R $TOMCAT_PATH /opt/apache-tomcat-8.5.100/webapps/
        sudo systemctl restart tomcat
	log "INFO" "Restart tomcat"

}



#install_java
#install_tomcat
#service_tomcat
#install_mysql
#configure_mysql
#mysql_driver
#create_db
#configure_tomcat
#deploy_war



main(){

	case $1 in
		install)
			install_java
			install_tomcat
			install_mysql
			;;	
		
		service)
			service_tomcat
			;;
		configure)
			configure_mysql
			configure_tomcat
			;;
		driver)
			mysql_driver
			;;
		deploy)
			deploy_war
			;;
		db)
			create_db;;
		*)
			install_java
			install_tomcat
			install_mysql
			service_tomcat
			configure_mysql
			configure_tomcat
			mysql_driver
			create_db
			deploy_war
			;;
	
	
	esac

}


main $1 


























