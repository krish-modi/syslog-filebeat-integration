FROM docker.elastic.co/beats/filebeat:7.17.9

LABEL description="Filebeat logs watcher"

# Adding configuration file and SSL certificates for Filebeat
COPY filebeat.yml /usr/share/filebeat/filebeat.yml
COPY <FILE NAME ca.crt OR ca.pem> /etc/ssl/certs/Coralogix.<CHOOSE BETWEEN .pem OR .crt>

# Changing permission of configuration file
USER root
RUN chown root:filebeat /usr/share/filebeat/filebeat.yml

# Return to deploy user
USER filebeat
