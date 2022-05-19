endpointAddress=$(aws iot describe-endpoint --endpoint-type iot:Data-ATS | jq -r '.endpointAddress')

# run pub/sub sample app using certificates downloaded in package
printf "\nRunning pub/sub sample application...\n"
echo $endpointAddress
instanceid=$(curl http://169.254.169.254/latest/meta-data/instance-id)
python aws-iot-device-sdk-python/samples/basicPubSub/basicPubSub.py -e $endpointAddress -r root-CA.crt -c ec2-iot.cert.pem -k ec2-iot.private.key -i $instanceid