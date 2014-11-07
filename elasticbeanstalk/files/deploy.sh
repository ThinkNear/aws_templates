#!/bin/bash

ec2_dir="/home/ec2-user"

# Temp: Don't install Tomcat7 if already installed
if [ -e $ec2_dir/tomcat7 ] ; then exit 0 ; fi
touch $ec2_dir/tomcat7

# TODO: Move Tomcat7 installation below
tar -zxf $ec2_dir/apache-tomcat-7.0.54.tar.gz -C $ec2_dir
rm $ec2_dir/apache-tomcat-7.0.54.tar.gz
mv -f $ec2_dir/apache-tomcat-7.0.54/bin/* /usr/share/tomcat7/bin/
mv -f $ec2_dir/apache-tomcat-7.0.54/lib/* /usr/share/tomcat7/lib/

# Don't run if deployed already
if [ -e $ec2_dir/deployed ] ; then exit 0 ; fi
touch $ec2_dir/deployed

echo "Configuring Raid 0"
umount /media/ephemeral0
yes | mdadm --create /dev/md0 --level=0 -c256 --raid-devices=2 /dev/sdb /dev/sdc
echo 'DEVICE /dev/sdb /dev/sdc' > /etc/mdadm.conf
mdadm --detail --scan >> /etc/mdadm.conf
blockdev --setra 2048 /dev/md0
mkfs.ext4 /dev/md0
mkdir -p /mnt/md0 && mount -t ext4 -o noatime /dev/md0 /media/ephemeral0
perl -ne 'print if $_ !~ /media/' /etc/fstab > /etc/fstab.2
echo '#/dev/md0  /media/ephemeral0  ext4    defaults 0 0' >> /etc/fstab.2
mv -f /etc/fstab.2 /etc/fstab
cat /proc/mdstat

echo "Pointing Tomcat logs to /media/ephemeral0/"
mv /var/log/tomcat7 /media/ephemeral0/logs
ln -s /media/ephemeral0/logs /var/log/tomcat7

echo "Downloading LZOP from http://www.lzop.org/download/..."
curl http://www.lzop.org/download/lzop-1.03-i386_linux.tar.gz -o $ec2_dir/lzop-1.03-i386_linux.tar.gz

echo "Unpacking LZOP..."
tar -zxf $ec2_dir/lzop-1.03-i386_linux.tar.gz -C $ec2_dir
mv $ec2_dir/lzop-1.03-i386_linux/lzop /bin/lzop

echo "Downloading Java 1.7.0u60..."
JDK_HOME=/usr/java/jre1.7.0_60
wget -nv -O $ec2_dir/jre-7u60-linux-x64.rpm --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http://www.oracle.com/; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/7u60-b19/jre-7u60-linux-x64.rpm"

echo "Installing Java 1.7.0u60..." 
rpm -i $ec2_dir/jre-7u60-linux-x64.rpm
alternatives --install /usr/bin/java java $JDK_HOME/bin/java 2 \
  --slave /usr/lib/jvm/jre jre $JDK_HOME \
  --slave /usr/bin/keytool keytool $JDK_HOME/bin/keytool \
  --slave /usr/bin/orbd orbd $JDK_HOME/bin/orbd \
  --slave /usr/bin/pack200 pack200 $JDK_HOME/bin/pack200 \
  --slave /usr/bin/rmid rmid $JDK_HOME/bin/rmid \
  --slave /usr/bin/rmiregistry rmiregistry $JDK_HOME/bin/rmiregistry \
  --slave /usr/bin/servertool servertool $JDK_HOME/bin/servertool \
  --slave /usr/bin/tnameserv tnameserv $JDK_HOME/bin/tnameserv \
  --slave /usr/bin/unpack200 unpack200 $JDK_HOME/bin/unpack200 \
  --slave /usr/bin/unpack200 unpack200 $JDK_HOME/bin/unpack200
echo 2 | alternatives --config java

rm -f $ec2_dir/*.gz

echo "Monitor for low disk space."
echo "2,17,32,47 * * * * root $ec2_dir/aws-scripts-mon/mon-put-instance-data.pl --disk-space-avail --disk-path=/ --aws-iam-role=aws-elasticbeanstalk-ec2-role" >> /etc/crontab
instance_id=`curl --silent http://169.254.169.254/latest/meta-data/instance-id`

aws cloudwatch put-metric-alarm --region us-east-1 --alarm-name LowDiskSpace_$instance_id --comparison-operator LessThanThreshold --evaluation-periods 2 --metric-name DiskSpaceAvailable --namespace 

echo "*/5 * * * * root /etc/cron.d/logrotate-tomcat" >> /etc/crontab

echo "Setting up logrotate-tomcat-rc..."
logrotate_file="/etc/init.d/logrotate-tomcat"
ln -s $logrotate_file /etc/rc0.d/K13logrotate-tomcat
ln -s $logrotate_file /etc/rc1.d/S87logrotate-tomcat
ln -s $logrotate_file /etc/rc2.d/S87logrotate-tomcat
ln -s $logrotate_file /etc/rc3.d/S87logrotate-tomcat
ln -s $logrotate_file /etc/rc4.d/S87logrotate-tomcat
ln -s $logrotate_file /etc/rc5.d/S87logrotate-tomcat
ln -s $logrotate_file /etc/rc6.d/K13logrotate-tomcat

echo "Setting up cron checker..."
check_file="/etc/init.d/check_cron"
ln -s $check_file /etc/rc1.d/S86check_cron
ln -s $check_file /etc/rc2.d/S86check_cron
ln -s $check_file /etc/rc3.d/S86check_cron
ln -s $check_file /etc/rc4.d/S86check_cron
ln -s $check_file /etc/rc5.d/S86check_cron
$check_file

echo "Removing Elasticbeanstalk rotation of Tomcat log files (catalina.out and localhost_access_log.txt)"
rm -f /etc/cron.hourly/logrotate-elasticbeanstalk

echo "Removing publishing of tomcat7 logs"
rm -f /opt/elasticbeanstalk/tasks/publishlogs.d/tomcat7.conf

echo "Removing Elasticbeanstalk publish logs script"
rm -f /etc/cron.d/publishlogs

echo "Generating TN unique identifier"
echo `uuidgen` > /home/ec2-user/tn-unique-identifier.dat

echo "Setup complete."
