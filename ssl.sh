#!/bin/bash

###Set Environment variable
VALIDITY=1825
KAFKA_HOST=localhost
SSLPASSPHRASE=elhaloui123456
CERTIFICATE_INFO="CN=$KAFKA_HOST,OU=kafka,O=kafka,L=kafka,ST=kafka,C=XX"
CA_INFO="/C=XX/ST=kafka/L=kafka/O=kafka/OU=kafka/CN=$KAFKA_HOST/"
KAFKA_SSL="/opt/kafka/ssl"

mkdir -p $KAFKA_SSL
cd $KAFKA_SSL

###Create CA and server keystore/truststore###
openssl req -new -x509 -keyout ca-key -out ca-cert -days $VALIDITY -subj $CA_INFO -passout pass:$SSLPASSPHRASE &> /dev/null
keytool -noprompt -keystore kafka.server.keystore.jks -alias $KAFKA_HOST -validity $VALIDITY -genkey -dname $CERTIFICATE_INFO -keypass $SSLPASSPHRASE -storepass $SSLPASSPHRASE &> /dev/dull
keytool -noprompt -keystore kafka.server.truststore.jks -alias CARoot -import -file ca-cert -storepass $SSLPASSPHRASE &> /dev/null
keytool -noprompt -keystore kafka.server.keystore.jks -alias $KAFKA_HOST -certreq -file cert-file-$KAFKA_HOST -storepass $SSLPASSPHRASE &> /dev/null
openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-file-$KAFKA_HOST -out cert-signed-$KAFKA_HOST -days $VALIDITY -CAcreateserial -passin pass:$SSLPASSPHRASE &> /dev/null
keytool -noprompt -keystore kafka.server.keystore.jks -alias CARoot -import -file ca-cert -storepass $SSLPASSPHRASE &> /dev/null
keytool -noprompt -keystore kafka.server.keystore.jks -alias $KAFKA_HOST -import -file cert-signed-$KAFKA_HOST -storepass $SSLPASSPHRASE &> /dev/null

###Create client keystore and truststore###
read -p "Please specify a username to give Kafka ACL permissions: " USERNAME
echo -n "Please specify a passphrase for the client ssl certificate: "
read -s CLIENT_SSLPASSPHRASE
echo -e "\n"
CLIENT_CERTIFICATE_INFO="CN=$USERNAME,OU=kafka,O=kafka,L=kafka,ST=kafka,C=XX"

keytool -noprompt -keystore kafka.client.keystore.jks -alias $USERNAME -validity $VALIDITY -genkey -dname $CLIENT_CERTIFICATE_INFO -keypass $CLIENT_SSLPASSPHRASE -storepass $CLIENT_SSLPASSPHRASE &> /dev/null
keytool -noprompt -keystore kafka.client.truststore.jks -alias CARoot -import -file ca-cert -storepass $CLIENT_SSLPASSPHRASE &> /dev/null
keytool -noprompt -keystore kafka.client.keystore.jks -alias $USERNAME -certreq -file cert-file-client-$USERNAME -storepass $CLIENT_SSLPASSPHRASE &> /dev/null
openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-file-client-$USERNAME -out cert-signed-client-$USERNAME -days $VALIDITY -CAcreateserial -passin pass:$SSLPASSPHRASE &>/dev/null

###Add client certificate to server truststore###
keytool -keystore kafka.server.truststore.jks -alias $USERNAME -import -file cert-signed-client-$USERNAME -storepass $SSLPASSPHRASE &> /dev/null
