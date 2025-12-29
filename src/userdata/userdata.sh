#!/bin/bash
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd
echo 'Skill53##' | passwd --stdin ec2-user

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version

yum install jq -y --allowerasing

sudo yum install -y unzip jq wget git mariadb105 --allowerasing
sudo yum install docker -y
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
sudo usermod -aG docker root
sudo systemctl start docker
sudo chmod 666 /var/run/docker.sock

docker --version

BUCKET_NAME=$(aws s3api list-buckets --query "Buckets[].Name" --output text | tr '\t' '\n' | grep -E '^gbsw-s3-bucket-[0-9]{4}$')
aws s3 cp s3://$BUCKET_NAME/image/product/product .
aws s3 cp s3://$BUCKET_NAME/image/product/Dockerfile .

ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.ap-northeast-2.amazonaws.com
docker build -t $ACCOUNT_ID.dkr.ecr.ap-northeast-2.amazonaws.com/product:v1.0.0 .
docker push $ACCOUNT_ID.dkr.ecr.ap-northeast-2.amazonaws.com/product:v1.0.0