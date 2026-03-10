#!/bin/bash

apt update -y
apt upgrade -y

# install docker
apt install -y docker.io
systemctl enable docker
systemctl start docker

# install git + tools
apt install -y git curl wget

# run OWASP Juice Shop
docker run -d -p 3000:3000 bkimminich/juice-shop

# create vulnerable API
mkdir /opt/vulnapi
cd /opt/vulnapi

cat <<EOF > app.py
from flask import Flask, request
import os

app = Flask(__name__)

@app.route("/ping")
def ping():
    host = request.args.get("host")
    return os.popen("ping -c 1 " + host).read()

app.run(host="0.0.0.0", port=5000)
EOF

apt install -y python3-pip
pip3 install flask

nohup python3 /opt/vulnapi/app.py &

# weak credentials for testing
useradd dev
echo "dev:Password123" | chpasswd

echo "lab ready"
