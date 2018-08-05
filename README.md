# Setup SSL secured Kafka cluster 

in this tutorial, i will show you how to setup kafka cluster on your server, secured by ssl authetication & encription

go to the kafka official web site ad download the lastet version of kafka.

https://www.apache.org/dyn/closer.cgi?path=/kafka/2.0.0/kafka_2.11-2.0.0.tgz

 at this time, in my case, the latest version is available in the link below
 
 
 http://www-us.apache.org/dist/kafka/2.0.0/kafka_2.11-2.0.0.tgz

- switch as root in your machine <br />
`$ sudo su`<br />
- we’ll start by creating a kafka directory where the installation will be<br />
`$ mkdir -p /opt/kafka`<br />
 `$ cd /opt/kafka`<br />
 
- Here you can change kafka version, i will use the latest version available in my case

 `$ wget http://www-us.apache.org/dist/kafka/2.0.0/kafka_2.11-2.0.0.tgz`<br />
 `$ tar xvf kafka_2.11-2.0.0.tgz`<br />
 
- now we will change some of the kafka broker properties

`$ cd kafka_2.11-2.0.0/config`<br\>
`$ nano server.properties `<br\>

You will need to find the following configs

>#listeners=PLAINTEXT://:9092<br />
>#advertised_listeners=PLAINTEXT://your.host.name:9092<br />
>#listener.security.protocol.map=PLAINTEXT:PLAINTEXT,SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,SASL_SSL:SASL_SSL<br />
>log.dirs=/tmp/kafka-logs<br />
>zookeeper.connect=localhost:2181<br />


And change them as follows

>listeners=SSL://:9093<br />
>advertised.listeners=SSL://localhost:9093<br />
>listener.security.protocol.map=SSL:SSL<br />
>log.dirs=/opt/kafka/kafka-logs<br />
>zookeeper.connect=localhost:2181<br />

The above config is not enough to make Kafka work with SSL, so we would need to add some other custom properties inside server.properties file and later on also create an SSL certificate later on. Add the following at the end of the file

>security.protocol=SSL<br />
security.inter.broker.protocol=SSL<br />
ssl.keystore.location=/opt/kafka/ssl/kafka.server.keystore.jks<br />
ssl.keystore.password=elhaloui123456<br />
ssl.key.password=elhaloui123456<br />
ssl.keystore.type=JKS<br />
ssl.truststore.location=/opt/kafka/ssl/kafka.server.keystore.jks<br />
ssl.truststore.password=elhaloui123456<br />
ssl.truststore.type=JKS<br />
authorizer.class.name=kafka.security.auth.SimpleAclAuthorizer<br />
allow.everyone.if.no.acl.found=false<br />
super.users=User:CN=localhost,OU=kafka,O=kafka,L=kafka,ST=kafka,C=XX<br />
ssl.client.auth=required<br />

So all the basic necessary configuration are now done for the Kafka Broker. Now we will proceed in creating the necessary directories and SSL certificates to make this work

`$ mkdir -p /opt/kafka/ssl`<br />
`$ cd /opt/kafka/ssl`<br />

we need to have openssl and java installed on our machine, so we make sure that we have them

`$ apt-get install java-1.8.0-openjdk openssl`<br />

-   You can then use the **ssl.sh** script to create the necessary server and client certificates/keystores.

by default i use the following data for certficates creation

>`VALIDITY=1825
>KAFKA_HOST=localhost
>SSLPASSPHRASE=elhaloui123456
>CERTIFICATE_INFO="CN=$KAFKA_HOST,OU=kafka,O=kafka,L=kafka,ST=kafka,C=XX"
>CA_INFO="/C=XX/ST=kafka/L=kafka/O=kafka/OU=kafka/CN=$KAFKA_HOST/"
>KAFKA_SSL="/opt/kafka/ssl" `

You can change them in the **ssl.sh** befor you run it.
* Once the certificates and keystores are created, we can start the Kafka Broker and the embedded zookeeper which comes with the installation.

`$ cd /opt/kafka/kafka_2.11-2.0.0/bin`

- First you would need to start the zookeeper service

 `$ nohup ./zookeeper-server-start.sh ../config/zookeeper.properties > zookeeper.out &`
 
- After zookeeper has started, start the kafka broker

`$ nohup ./kafka-server-start.sh ../config/server.properties > kafka.out &`

- Next, we will create a kafka topic so that we can then configure the ACLs.

`$ ./kafka-topics.sh --zookeeper localhost:2181 --create --topic test1 --partitions 1 --replication-factor 1`

-    Now we will configure the ACLs on this newly created topic for the user that was created in the certificate (in my case the user is “mohammed”).
 #### To create ACLs for producer use the following command
`$ ./kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 --add --allow-principal User:"CN=mohammed,OU=kafka,O=kafka,L=kafka,ST=kafka,C=XX" --producer --topic test1`
#### To create ACLs for consumer use the following command
`$ ./kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 --add --allow-principal User:"CN=mohammed,OU=kafka,O=kafka,L=kafka,ST=kafka,C=XX" --consumer --topic test1 --group mohammed-consumer` 

- You would need to create another file for the client so that it can use the client-keystore and client-truststore that were previously created. Change the password and necessary configs depending on how you previously set them up

`cat > /opt/kafka/ssl/client-ssl.properties << EOF 
security.protocol=SSL 
ssl.truststore.location=/opt/kafka/ssl/kafka.client.truststore.jks 
ssl.truststore.password=elhaloui123456
ssl.keystore.location=/opt/kafka/ssl/kafka.client.keystore.jks 
ssl.keystore.password=elhaloui123456 
ssl.key.password=elhaloui123456
EOF`

- You can then check whether you can produce or consume using the following commands
#### Producer
`$ ./kafka-console-producer.sh --broker-list localhost:9093 --topic test1  -producer.config /opt/kafka/ssl/client-ssl.properties`
#### Consumer
`$ ./kafka-console-consumer.sh --bootstrap-server localhost:9093 --topic test1 --consumer.config /opt/kafka/ssl/client-ssl.properties --group mohammed-consumer --from-beginning`

### Enjoy!
