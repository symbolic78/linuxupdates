#!/bin/bash
#
# Fork of the cron script to update redhat from its local repo
# this will update the system and perform an immediate reboot.

#GLOBAL VARIABLES
SYSTEM_VERSION=`lsb_release -rs | cut -f1 -d.`
YUM="/usr/bin/yum"
RPM="/bin/rpm"
DOWNLOADDIR="/srv/updates/localrepo/`uname -n`"
REPORTDIR="/srv/updates/reports/`uname -n`"
REPORTTMP="/tmp/auto_updates.$$"
UPDATEREPORT="$REPORTDIR/`uname -n`.updates.out"
MAIL=/bin/mailx
MAILTO=unix-support@city.ac.uk

#Make sure that we are running on a redhat system, if not exit
check_version()
{
   if [ ! -f /etc/redhat-release ]; then
      echo "ERROR! DOESN'T APPEAR TO BE A REDHAT SYSTEM"
      exit 1
   fi
} 

mail_reboot()
{
   $MAIL -s "[REDHAT UPDATES]Server `uname -n` applied updates and rebooting" $MAILTO << EOF
Server `uname -n` has applied relevant errata and is rebooting. Please check all services are running correctly once the server has rebooted.

This message was automatically generated on server `uname -n` by $0
EOF
}

update_redhat()
{
   #First lets check that there are updates to apply
   ls -l $DOWNLOADDIR/*.rpm >& /dev/null
   case $? in
   0)
      echo "there are updates to apply"
      ;;
   *)
      echo "there are no updates to apply in $DOWNLOADDIR. this could mean that there were no available updates, or that there has been a problem."
      exit 1
      ;;
   esac

   echo "time to apply system updates"
   $YUM -y upgrade $DOWNLOADDIR/* >& $REPORTDIR/`uname -n`.updates.log
   YUMSTATUS="$?"

   case $YUMSTATUS in
   0)
      # looks like the updates was succesful, reboot!
      rm -rf $DOWNLOADDIR/*.rpm
      echo "update completed, server will reboot"
      mail_reboot
      sleep $SLEEP
      reboot
      ;;
   *)
      #Looks like there was a problem with the update
      echo "ERROR UPDATING!"
      ;;
   esac
}

check_version
update_redhat
