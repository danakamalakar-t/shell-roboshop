#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
MONGODB_HOST="mongodb.danakamalakar.store"
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-script/16-logs.log
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script with root privelege"
    exit 1 # failure is other than 0
fi

VALIDATE(){ # functions receive inputs through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

### NodeJS is a prerequisite for catalogue service. So, we will install NodeJS first and then we will install catalogue service.###
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling NodeJS module"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling NodeJS 20 module"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing NodeJS"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Adding roboshop user"
else
    echo "roboshop user already exists... SKIPPING"
fi



mkdir -p /app
VALIDATE $? "Creating /app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading catalogue service code"

cd /app
VALIDATE $? "Changing directory to /app"

dnf install unzip -y &>>$LOG_FILE
VALIDATE $? "Installing unzip"

rm -rf /app/* &>>$LOG_FILE
VALIDATE $? "Cleaning up old catalogue service code"

unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Extracting catalogue service code"

npm install &>>$LOG_FILE
VALIDATE $? "Installing catalogue service dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying catalogue service file"

systemctl daemon-reload
systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "Enabling catalogue service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding Mongo repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installing MongoDB Shell"

COUNT=$(mongosh mongodb.danakamalakar.store --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")

if [ $COUNT -le 0 ]; then
        mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
        VALIDATE $? "Loading master data to MongoDB"
else
    echo -e "Catalogue products already loaded  ... $Y SKIPPING $N"
fi 


systemctl restart catalogue
VALIDATE $? "Restarting catalogue service"

