#!/bin/bash

apt update -y
apt install -y docker.io python3-pip git

systemctl enable docker
systemctl start docker

# OWASP Juice Shop
docker run -d -p 3000:3000 bkimminich/juice-shop

# vulnerable API
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

pip3 install flask

nohup python3 /opt/vulnapi/app.py &

useradd dev
echo "dev:Password123" | chpasswd

echo "target ready"
