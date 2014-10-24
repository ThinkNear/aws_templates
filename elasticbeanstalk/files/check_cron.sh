#!/bin/sh

##
# check_cron
# Script supposed to be run by inittab because crond keeps crashing
##
# Date: 15/07/2010
# Author: David - http://www.ows.fr
# Version: Initial Release
##

# Check if fs is mounted.
while [ ! -f /usr/sbin/crond ] || [ ! -f /etc/crontab ]
do
        # If not mounted we sleep 15 s
        /bin/sleep 15
done

# Let the system start up crond at init
sleep 300

# We fake daemonize it
while true
do
        # We test if crontab is already running
        TEST=`ps | grep [c]rond`
        if [ "$?" = "0"  ] ; then
                # It's running: Wait 60s
                sleep 60
        else
                # It's not running: Restart it !
                /etc/init.d/crond start
                # We log it cause we are serious people
                /usr/bin/logger "[check_cron.sh]: Process: crond was crashed ! Restarted !"
                # We test if the restart worked
                TEST_2=`ps | grep [c]rond`
                if [ "$?" = "1" ] ; then
                   # if restart failed there is nothing more we can do
                   /usr/bin/logger "[check_cron.sh]: crond can't be started. We go offline for 5min."
                   sleep 300
                fi
        fi
done
