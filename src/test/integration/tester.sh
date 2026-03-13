#!/bin/bash
echo "Starting kafka";
su - srv-kaf_07 -s "$(which bash)" -c 'KAFKA_OPTS="-Djava.security.auth.login.config=/config/kafka.jaas.conf" CLASSPATH=/opt/teragrep/kaf_04/share/kaf_04.jar /opt/teragrep/kaf_06/bin/kafka-server-start.sh -daemon /config/kafka.properties'

echo "Sleeping a bit to let it wake up";
sleep 5;

for i in {1..10}; do
    echo "Attempt ${i} of seeing if kafka is up";
    if nc -z 127.0.0.1 9092; then
        break;
    fi;
    if [ "${i}" -eq "10" ]; then
        echo "Could not connect to kafka, failing. Printing last 50 lines of logs:";
        tail -50 /opt/teragrep/kaf_06/logs/kafkaServer.out;
        exit 1;
    fi;
    sleep 1;
done;


function grep_message() {
    echo "Grepping '${1}' from /opt/teragrep/kaf_06/logs/kafkaServer.out";
    if ! grep "${1}" /opt/teragrep/kaf_06/logs/kafkaServer.out; then
        echo "Can't find '${1}' from logs, failing";
        exit 1;
    fi;
}

echo "Checking if all messages are as expected in kafkaServer.out";
grep_message "Didn't find property <\[teragrep.kaf_04.authorize.file\]>";
grep_message "Didn't find property <\[teragrep.kaf_04.writer.file\]>";
grep_message "Didn't find property <\[teragrep.kaf_04.cluster.file\]>";
grep_message "Didn't find property <\[teragrep.kaf_04.identitySuffix.file\]>";

echo "Adding properties and restarting server";
kill -TERM "$(ps ax | grep -i 'kafka\.Kafka' | grep java | awk '{print $1}')"
(
    echo "teragrep.kaf_04.authorize.file=/custom-path/authorize.json"
    echo "teragrep.kaf_04.writer.file=/custom-path/writer.json"
    echo "teragrep.kaf_04.cluster.file=/custom-path/cluster.json"
    echo "teragrep.kaf_04.identitySuffix.file=/custom-path/identitySuffix.json"
) >> /config/kafka.properties
# Just because permissions and clean shutdown is not possible right now
sleep 30;

echo "Starting kafka";
su - srv-kaf_07 -s "$(which bash)" -c 'KAFKA_OPTS="-Djava.security.auth.login.config=/config/kafka.jaas.conf" CLASSPATH=/opt/teragrep/kaf_04/share/kaf_04.jar /opt/teragrep/kaf_06/bin/kafka-server-start.sh -daemon /config/kafka.properties'

echo "Sleeping a bit to let it recover";
sleep 2;

echo "Checking if all messages are as expected in kafkaServer.out";
grep_message "Resolved property <\[teragrep.kaf_04.authorize.file\]> to";
grep_message "Resolved property <\[teragrep.kaf_04.writer.file\]> to";
grep_message "Resolved property <\[teragrep.kaf_04.cluster.file\]> to";
grep_message "Resolved property <\[teragrep.kaf_04.identitySuffix.file\]> to";
