aws_templates
=============

This repo contains template configuration files that we use to configure our AWS services.

## Getting Started

### Requirements

The provided files have been tested with

* ami-ed8e928, Amazon Linux AMI x86_64 PV S3 (Instance Store) 2014.03.1 
* Beanstalk Stack Version Tomcat 7 Java 7 on 64bit Amazon Linux 2014.03 v1.0.4
* Beanstalk web server. Environment type load balancing, autoscaling
* Instances role that allows getting and putting objects to S3.
* Beanstalk option parameter PARAM2 is 'production'

### Filling in the blanks

The provided files are missing working values for various settings. Make the following updates:

**environment.config**

* Replace JMX_USER with a username.
* Replace JMX_PASSWORD with a password.
* Replace JMX_ROLE with a access-level role. For monitoring, this can be "readonly". 
* Replace JMX_PORT with a JMX listener port.
  * See Java [docs](http://docs.oracle.com/javase/7/docs/technotes/guides/management/agent.html#gdeuc) for more details on remote JMX monitoring
* Replace S3_LOG_BUCKET with the bucket name of your log files destination.
* Replace AWS_ELB_BUCKET with the bucket name where your ELB Access logs will be dumped.

**collectd.conf**

* Replace JMX_USER with a username.
* Replace JMX_PASSWORD with a password.
* Replace JMX_PORT with a JMX listener port.
* Replace LIBRATO_USER with a Librato account email.
* Replace LIBRATO_EMAIL with a Librato account API Token. This token should have permission to write metrics.

**logrotate.conf.tomcat.production**

* Replace S3_LOG_BUCKET with the bucket name of your log files destination.

### Adding it to your project

1. If your Java application is packaged as a WAR file, copy the ```.ebextensions``` to the same level as the WEB-INF directory. Otherwise, copy ```.ebextensions``` to the top-level directory of your project. 

2. Copy your files to an S3 bucket. This bucket name should match the value of S3_FILES_BUCKET. Be sure that the instance role allows instances to getting and putting files from this bucket.

#### Environment stages and PARAM2

The environment stage is set with the Beanstalk option PARAM2. 
PARAM2 must be 'production' for this template configuration.
