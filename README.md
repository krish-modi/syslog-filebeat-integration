# Syslog Integration Using Filebeat

# **Summary**

Coralogix provides integration with Syslog using `Filebeat` so you can send your logs from anywhere and parse them according to your needs.

# Pre-Requisites

1. EC2 instance with OS based on Debian or RedHat based distributions.
2. SSH and root access to the EC2 instance (via a terminal).
3. A Static Public IP allocated to the instance.
4. Information related to hosts:

| Cluster | EU | IN | US |
| --- | --- | --- | --- |
| Cluster domain | coralogix.com | app.coralogix.in | coralogix.us |
| SSL Certificates | https://coralogix-public.s3-eu-west-1.amazonaws.com/certificate/Coralogix-EU.crt | https://coralogix-public.s3-eu-west-1.amazonaws.com/certificate/Coralogix-IN.pem | https://www.amazontrust.com/repository/AmazonRootCA1.pem |
| Logstash server URL | logstashserver.coralogix.com | logstash.app.coralogix.in | logstashserver.coralogix.us |

# Installing directly on EC2

1. Installing `Filebeat` on the EC2 instance

For a quick setup of `Filebeat` on your server, you can use prepared **[scripts](https://github.com/coralogix/integrations-docs/tree/master/integrations/filebeat/scripts)**.

Go to the folder with your `Filebeat` configuration file **(`filebeat.yml`)** and execute **(as root)** 

This script will install `Filebeat` on your machine, prepare configuration and download *Coralogix* SSL certificates.

**Note:** If you want to install a specific version of `Filebeat` you should pass version number with environment variable before script run:

```bash
$ export FILEBEAT_VERSION=7.17.9
```

### deb

Based on the region of your account you can run the following command for Debian based linux, replace the script name according to your region (`EU`, `IN`, `US`):

```bash
$ curl -sSL https://raw.githubusercontent.com/krish-modi/syslog-filebeat-integration/main/filebeat_setup/deb/install-db-<CHOOSE EU, IN OR US>.sh | bash
```

### rpm

Based on the region of your account you can run the following command for RedHat based linux, replace the script name according to your region (`EU`, `IN`, `US`):

```bash
$ curl -sSL https://raw.githubusercontent.com/krish-modi/syslog-filebeat-integration/main/filebeat_setup/rpm/install-rpm-<CHOOSE EU, IN OR US>.sh | bash
```

1. Configuring `filebeat.yml`

Open your `Filebeat` configuration file and configure it to use `Logstash` (Make sure you disable `Elasticsearch` output). For more information about configuring `Filebeat` to use `Logstash` please refer to **[https://www.elastic.co/guide/en/beats/filebeat/current/config-filebeat-logstash.html](https://www.elastic.co/guide/en/beats/filebeat/current/logstash-output.html)**

The following YAML file gives a typical template for the syslog configuration to send logs to Coralogix with input coming from a tcp source.

Navigate to `/etc/filebeat/filebeat.yml` and update the configuration file.

The template can be found [here](https://raw.githubusercontent.com/krish-modi/syslog-filebeat-integration/main/filebeat_conf/filebeat.yml) as well

Example:

```yaml
filebeat.inputs:
- type: syslog
  format:  # Choose the format accordingly
  protocol.tcp:
    host: "0.0.0.0:9000"

fields_under_root: true
fields:
  PRIVATE_KEY: ""   # Coralogix account private ket to send data
  COMPANY_ID:       # Coralogix account company id
  APP_NAME: ""      # Application name of your choice
  SUB_SYSTEM: ""    # Subsystem name of your choice

### Outputs
output:
  logstash:
    hosts: ["<LOGSTASH CLUSTER URL>:5015"]               # Add the relevant coralogix logstash cluster url
    ssl:
      certificate_authorities: ["<CERTIFICATE PATH>"]   # Add the coralogix certificate path
```

For further options please refer to [Filebeat's Syslog Input Options](https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-input-syslog.html)

**Note**: `Logstash` cluster for Coralogix can be found in the table above

**Note**: The certificate can path can found in the respective `.sh` files used in the installation of `filebeat`

1. Restart filebeat

Run the following commands to apply the changes made in `filebeat.yml`

```bash
$ service filebeat restart
$ service filebeat status
```

1. Testing the integration

NetCat commands can be used for sending a test log to Coralogix over a network.

**Note**: Please install `netcat` on the machine if it is not installed.

- For RedHat based

```bash
$ yum update -y
$ yum install -y netcat
```

- For Debian based

```bash
$ apt-get update -y
$ apt-get install -y netcat
```

Example (for tcp connection):

```bash
$ nc localhost 9000
test
test 123
```

(The above command will produce 2 logs with messages `test` and `test 123`)

# Docker

We will work in root for creating and deployment of the container

1. Make sure Docker is installed on the system. Refer to the [official installation guide](https://www.notion.so/Docker-Certification-Ready-522985af668045919442e927c15c4f61) according to the OS.
2. Prepare the `filebeat.yml` in the root folder explained in Step 2 above in the directory you wish to create the Docker image.
3. Download the respective ssl certificate in the working directory

### EU

```bash
$ curl -o ca.crt \
     https://coralogix-public.s3-eu-west-1.amazonaws.com/certificate/Coralogix-EU.crt
```

### IN

```bash
$ curl -o ca.pem \
     https://coralogix-public.s3-eu-west-1.amazonaws.com/certificate/Coralogix-IN.pem
```

### US

```bash
$ curl -o ca.pem \
     https://www.amazontrust.com/repository/AmazonRootCA1.pem
```

1. Create the `Dockerfile` for the image, refer [here](https://raw.githubusercontent.com/krish-modi/syslog-filebeat-integration/main/filebeat-docker/Dockerfile).

```docker
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
```

1. Run the following command to create the image.

```bash
$ docker build -t <NAME OF THE IMAGE> .
```

1. Deploy the container.

```bash
$ docker run -p <PORT OF CHOICE ON THE SERVER>:9000 <NAME OF THE IMAGE>
```

(This will not run the container in the detached mode, please open a separate terminal if you want to view the logs simultaneously)

1. Test the tcp connection.

```bash
$ nc localhost <PORT ATTACHED TO THE CONTAINER>
test
test 123
```

(The above command will produce 2 logs with messages `test` and `test 123`)
