#!/bin/bash

# STAGE and ELASTICBEANSTALK_ENVIRONMENT is set in the .ebextension environment.config containter_command
STAGE=$1
ELASTICBEANSTALK_ENVIRONMENT=$2

function enable_collectd() {
    sed -i "s/IncludeRegex \"DISABLED\"/IncludeRegex \"collectd.processes*,collectd.cpu.0*,collectd.GenericJMX*,collectd.memory*,collectd.load*\"/g" $COLLECTD_CONF
}

function detailed_collectd() {
    sed -i "s/^Interval.*/Interval 60/g" $COLLECTD_CONF
    sed -i "s/FlushIntervalSecs.*/FlushIntervalSecs 60/g" $COLLECTD_CONF
    sed -i "s/FloorTimeSecs.*/FloorTimeSecs 60/g" $COLLECTD_CONF
}

INSTANCE_ID=$(curl --silent http://169.254.169.254/latest/meta-data/instance-id)
if [ -z $ELASTICBEANSTALK_ENVIRONMENT ]; then
    ELASTICBEANSTALK_ENVIRONMENT=$(AWS_DEFAULT_REGION=us-east-1 aws ec2 describe-tags \
      --query Tags[0].Value \
      --filters Name=resource-id,Values=$INSTANCE_ID Name=key,Values=elasticbeanstalk:environment-name)
fi
SOURCENAME=$(echo "$ELASTICBEANSTALK_ENVIRONMENT-$INSTANCE_ID" | sed s/\"//g )
COLLECTD_CONF=/etc/collectd.conf

# Sets the sourcenames
if [ -f $COLLECTD_CONF ]; then 
  sed -i "/Host /c Host \"$SOURCENAME\"" $COLLECTD_CONF
  sed -i "/Hostname /c Hostname \"$SOURCENAME\"" $COLLECTD_CONF

  # By default, collectd does not report to Librato. Enable it.
  if [ "$STAGE" = "production" ] || [ "$ELASTICBEANSTALK_ENVIRONMENT" = "environment-test-load" ]; then
    enable_collectd
  fi

  # Send detailed metrics for load testing
  if [ "$ELASTICBEANSTALK_ENVIRONMENT" = "environment-test-load" ]; then
    detailed_collectd
  fi
fi

killall collectdmon
LD_PRELOAD=/usr/lib/jvm/jre/lib/amd64/server/libjvm.so /usr/sbin/collectdmon -c /usr/sbin/collectd

# Don't break deploy if configuring collectd fails
exit 0 
