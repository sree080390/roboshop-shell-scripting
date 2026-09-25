#!/bin/bash

LOG_FOLDER=/var/lib/roboshop
sudo mkdir -p $LOG_FOLDER
sudo chown -R ec2-user:ec2-user $LOG_FOLDER
sudo chmod -R 755 $LOG_FOLDER
LOG_FILE="$LOG_FOLDER/$0.log"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

R="\e[31m"
Y="\e[33m"
G="\e[32m"
N="\e[0m"

USER_ID=$(id -u)

if [ $USER_ID -ne 0 ]; then
    echo -e "Script execution started at $G $TIMESTAMP" $N | tee -a $LOG_FILE
    echo -e "$TIMESTAMP [ERROR] You are $R not root user. Please run the script as root." | tee -a $LOG_FILE
    exit 1
fi
echo -e "$TIMESTAMP [INFO] You are $G root user. Proceeding with the script execution." | tee -a $LOG_FILE

VALIDATE () {
    if [ $1 -ne 0 ]; then
        echo -e "$TIMESTAMP [ERROR] $2 $R failed.$N" | tee -a $LOG_FILE
        echo -e "$TIMESTAMP [ERROR] script exit with status code 1" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$TIMESTAMP [INFO] $2 $G completed successfully.$N" | tee -a $LOG_FILE
    fi
}

cp mongodb.repo /etc/yum.repos.d/mongodb.repo
VALIDATE $? "Adding Mongo Repo"   
dnf list installed | grep -q mongodb-org
if [ $? -eq 0 ]; then
    echo -e "$TIMESTAMP [INFO] MongoDB is $Y already installed. $N" | tee -a $LOG_FILE
else
    echo -e "$TIMESTAMP [ERROR] MongoDB is not $R installed. $N Installing..." | tee -a $LOG_FILE
    dnf install -y mongodb-org &>> $LOG_FILE
    VALIDATE $? "Installing MongoDB"
fi
systemctl enable --now mongod 
VALIDATE $? "Starting and enabling MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf
VALIDATE $? "Updating MongoDB configuration with remote connection"

systemctl restart mongod
VALIDATE $? "Restarting MongoDB service"