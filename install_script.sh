#!/bin/bash

usage () { echo "Usage: $0 [-a <access_key>] [-s <secret_key>] [ -h <proxy_host> -p <proxy_port> [ -u <proxy_username> -w <proxy_password> ] [ -c <ca_file> ] ] [-g <google_cloud_file_path>]"; }

while getopts :a:s:h:p:u:w:c:g: opt ; do
   case $opt in
      a) ACCESS_KEY=$OPTARG ;;
      s) SECRET_KEY=$OPTARG ;;
      h) PROXY_HOST=$OPTARG ;;
      p) PROXY_PORT=$OPTARG ;;
      u) PROXY_USERNAME=$OPTARG ;;
      w) PROXY_PASSWORD=$OPTARG ;;
      c) CA_FILE=$OPTARG ;;
      g) GOOGLE_FILE=$OPTARG ;;
      *) echo 'no valid input available' ;;
   esac
done

if ! [ -z "$ACCESS_KEY" ];then
    if [ -z "$SECRET_KEY" ];then
        echo "secret key is required"
        usage
        exit
    fi
fi



if ! [ -z "$PROXY_HOST" ] && ! [ -z "$PROXY_PORT" ];then
    PROXY_STRING=$PROXY_HOST:$PROXY_PORT
    if ! [ -z "$PROXY_USERNAME" ] && ! [ -z "$PROXY_PASSWORD" ];then
        PROXY_STRING=$PROXY_USERNAME:$PROXY_PASSWORD@$PROXY_STRING
    fi
    export http_proxy=http://$PROXY_STRING
    export https_proxy=http://$PROXY_STRING
fi

if ! [ -z "$GOOGLE_FILE" ];then
    if ! [ -f "$GOOGLE_FILE" ];then
        echo "Google credentials file does not exist"
        exit
    fi
fi


mkdir -p /opt/netapp/databroker/mnt
cd /opt/netapp/databroker

# install third party dependencies
yum -y update --security
yum -y install unzip
yum -y install nfs-utils
yum -y install cifs-utils
yum -y install samba-client

# install and start nscd (cache getaddrinfo requests)
yum -y install nscd
service nscd start
chkconfig nscd on

# remove SSM agent
yum -y erase amazon-ssm-agent

# install n and stable node+npm
curl --verbose --location https://repo.cloudsync.netapp.com/n --connect-timeout 10 --retry 5 --output /usr/bin/n
chmod +x /usr/bin/n
N_PREFIX=/ n latest

# download data broker bundle
curl --verbose --location "https://repo.cloudsync.netapp.com/production/phoenix/data-broker_1.3.0.15670-ac79ab0-production.zip" --connect-timeout 10 --retry 5 --output data-broker.zip
unzip -o data-broker.zip -d .
\rm -f data-broker.zip

# generate certificate & key and add relevant key-values to the data-broker json
if ! [ -z "" ];then
    mkdir certification
    cd ./certification
    openssl req -newkey rsa:2048 -subj '/CN=5d41cde2614c3c000ad0b5b7' -nodes -keyout 5d41cde2614c3c000ad0b5b7.key -x509 -days 365 -out 5d41cde2614c3c000ad0b5b7.crt
    cd ..

cat <<EOT >> config/data-broker.json
{
    "environment": "prod",
    "data-broker-id": "5d41cde2614c3c000ad0b5b7",
    "type": "AZURE",
    "commandsQueue": "https://sqs.us-east-1.amazonaws.com/167338112540/COMMANDS_prod_5d41cde2614c3c000ad0b5b7",
    "statusesQueue": "https://sqs.us-east-1.amazonaws.com/167338112540/STATUSES_prod_5d41cde2614c3c000ad0b5b7",
    "port": ,
    "aws":{
        "sqs":{
            "accessKeyId": "AKIASN5RA6YOISGOTWDB",
            "secretAccessKey": "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"
        }
    }
}
EOT

else

cat <<EOT >> config/data-broker.json
{
    "environment": "prod",
    "data-broker-id": "5d41cde2614c3c000ad0b5b7",
    "type": "AZURE",
    "commandsQueue": "https://sqs.us-east-1.amazonaws.com/167338112540/COMMANDS_prod_5d41cde2614c3c000ad0b5b7",
    "statusesQueue": "https://sqs.us-east-1.amazonaws.com/167338112540/STATUSES_prod_5d41cde2614c3c000ad0b5b7",
    "aws":{
        "sqs":{
            "accessKeyId": "AKIASN5RA6YOISGOTWDB",
            "secretAccessKey": "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"
        }
    }
}
EOT

fi


if ! [ -z "$ACCESS_KEY" ] && ! [ -z "$SECRET_KEY" ];then
    curl --verbose --location "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" --connect-timeout 10 --retry 5 --output awscli-bundle.zip
    unzip -o awscli-bundle.zip -d .
    sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
    sudo rm -rf ./awscli-bundle awscli-bundle.zip

    /usr/local/bin/aws configure set aws_access_key_id $ACCESS_KEY --profile data-broker
    /usr/local/bin/aws configure set aws_secret_access_key $SECRET_KEY --profile data-broker
fi

if ! [ -z "$PROXY_STRING" ];then
    sudo npm config set proxy http://$PROXY_STRING
    sudo npm config set https-proxy http://$PROXY_STRING
fi

if ! [ -z "$CA_FILE" ];then
    sudo npm config set cafile $CA_FILE
fi

sudo npm i --production

# install PM2 globally
sudo npm i pm2 -g

# start
if ! [ -z "$PROXY_STRING" ];then
    if ! [ -z "$CA_FILE" ];then
        sudo AWS_PROFILE=data-broker GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_FILE http_proxy=http://$PROXY_STRING https_proxy=http://$PROXY_STRING NODE_EXTRA_CA_CERTS=$CA_FILE pm2 start app.js --name data-broker --output /dev/null --error /dev/null
    else
        sudo AWS_PROFILE=data-broker GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_FILE http_proxy=http://$PROXY_STRING https_proxy=http://$PROXY_STRING pm2 start app.js --name data-broker --output /dev/null --error /dev/null
    fi
else
    sudo AWS_PROFILE=data-broker GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_FILE pm2 start app.js --name data-broker --output /dev/null --error /dev/null
fi

sudo pm2 startup
sudo pm2 save

