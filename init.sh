#!/usr/bin/env bash
# stop script on error
set -e

sudo apt install jq
sudo add-apt-repository universe
sudo apt-get update
sudo apt install python3-pip
pip install psutil

aws iot create-thing --thing-name "ec2-iot"

aws iot create-policy \
    --policy-name adminpolicy \
    --policy-document file://policy.json
    
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGION="us-east-1"


certificateArn=$(aws iot create-keys-and-certificate \
    --set-as-active \
    --certificate-pem-outfile ec2-iot.cert.pem \
    --public-key-outfile ec2-iot.public.key \
    --private-key-outfile ec2-iot.private.key | jq -r '.certificateArn')
    
    
aws iot attach-policy \
    --policy-name adminpolicy \
    --target $certificateArn
    
aws iot attach-thing-principal --thing-name ec2-iot --principal $certificateArn


# Check to see if root CA file exists, download if not
if [ ! -f ./root-CA.crt ]; then
  printf "\nDownloading AWS IoT Root CA certificate from AWS...\n"
  curl https://www.amazontrust.com/repository/AmazonRootCA1.pem > root-CA.crt
fi

# Check to see if AWS Device SDK for Python exists, download if not
if [ ! -d ./aws-iot-device-sdk-python ]; then
  printf "\nCloning the AWS SDK...\n"
  git clone https://github.com/aws/aws-iot-device-sdk-python.git
fi

# Check to see if AWS Device SDK for Python is already installed, install if not
if ! python -c "import AWSIoTPythonSDK" &> /dev/null; then
  printf "\nInstalling AWS SDK...\n"
  pushd aws-iot-device-sdk-python
  pip install AWSIoTPythonSDK
  result=$?
  popd
  if [ $result -ne 0 ]; then
    printf "\nERROR: Failed to install SDK.\n"
    exit $result
  fi
fi

printf "\nInitialization complete!\n"