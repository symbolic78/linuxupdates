#!/bin/bash
#

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

#Function to provide usage
usage()
{
cat << EOF

usage: `basename $0` OPTION

OPTIONS:
  -h Show this message
  -c Check for updates
  -u Update the system

Only one option of either check or update should be passed to this script

EOF
}

#Make sure that we are running on a redhat system, if not exit
check_version()
{
   if [ ! -f /etc/redhat-release ]; then
      echo "ERROR! DOESN'T APPEAR TO BE A REDHAT SYSTEM"
      exit 1
   fi
} 

#Check that the yum prerequisites are installed and available
check_prereqs()
{
   # Check that the package redhat_lsb is installed for lsb_release
   # we will also assume that the earlier setting of system_version
   # failed so we will set that again after installing.
   rpm -qa | grep redhat-lsb >& /dev/null
   if [ $? -eq 1 ];
   then
      $YUM -y install redhat-lsb
      SYSTEM_VERSION=`lsb_release -rs | cut -f1 -d.`
   fi

   # Check for yum-downloadonly plugin and install if missing
   if [ $SYSTEM_VERSION -eq 5 ];
   then
      $RPM -qa | grep yum-downloadonly >& /dev/null
      if [ $? -eq 1 ];
      then
         $YUM -y install yum-downloadonly
      fi
   elif [ $SYSTEM_VERSION -eq 6 ];
   then
      $RPM -qa | grep yum-plugin-downloadonly >& /dev/null
      if [ $? -eq 1 ];
      then
         $YUM -y install yum-plugin-downloadonly
      fi
   else
      echo "ERROR: Unknown RedHat Version. Exiting"
      exit 1
   fi

   # Check for yum-security plugin and install if missing
   if [ $SYSTEM_VERSION -eq 5 ]; 
   then
      $RPM -qa | grep yum-security >& /dev/null
      if [ $? -eq 1 ];
      then
         $YUM -y install yum-security
      fi
   elif [ $SYSTEM_VERSION -eq 6 ];
   then
      $RPM -qa | grep yum-plugin-security >& /dev/null
      if [ $? -eq 1 ];
      then
         $YUM -y install yum-plugin-security
      fi
   else
      echo "ERROR: Unknown RedHat Version. Exiting"
      exit 1
   fi

   if [ ! -d $REPORTDIR ]; then
      mkdir $REPORTDIR
   fi

   if [ ! -d $DOWNLOADDIR ]; then
      mkdir $DOWNLOADDIR
   fi
}


#Function to check redhat for updates
check_redhat()
{
   # Clean out any old updates if not already removed
   rm -f $DOWNLOADDIR/*.rpm
   $YUM clean all >& /dev/null
   $YUM check-update >& $REPORTTMP
   YUMSTATUS="$?"

   case $YUMSTATUS in
   0)
      #No updates available, lets clean up and exit
      echo "no updates available"
      rm -rf $REPORTTMP
      exit 0
      ;;
   100)
      #Updates are available
      echo "updates are available, downloading to local repository. Please run in update mode"
      $YUM -y upgrade --downloadonly --downloaddir=$DOWNLOADDIR >& /dev/null
      cp $REPORTTMP $UPDATEREPORT
      rm -rf $REPORTTMP
      mail_updates
      exit 0
      ;;
   *)
      #If exit status is anything other than 0 or 100 then there has 
      #been a problem
      echo "an error occurred with yum"
      exit 1
      ;;
   esac
}

mail_updates()
{
   $MAIL -s "[REDHAT UPDATES]Updates are available for server `uname -n`" $MAILTO << EOF
Updates are available and have been downloaded for server `uname -n`. If not already scheduled via cron, update server `uname -n` using the RPMs which can be found in /srv/updates/localrepo/`uname -n`/

Available Updates

`cat $UPDATEREPORT`

This message was automatically generated on server `uname -n` by $0
EOF
}

mail_reboot()
{
   $MAIL -s "[REDHAT UPDATES]Server `uname -n` applied updates and rebooting" $MAILTO << EOF
Server `uname -n` has applied relevant errata and will be rebooting in $SLEEP seconds. Please check all services are running correctly once the server has rebooted.

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

   # To lessen the NFS load, lets randomly sleep for upto 10 minutes before
   # installing
   SLEEP=$[ ( $RANDOM%600+1 ) ]
   echo "sleeping for $SLEEP seconds before installing"
   sleep $SLEEP
   echo "time to apply system updates"
   $YUM -y upgrade $DOWNLOADDIR/* >& $REPORTDIR/`uname -n`.updates.log
   YUMSTATUS="$?"

   case $YUMSTATUS in
   0)
      #looks like yum has completed succesfully, time to reboot
      #generate a random time between 1 minute (60) and 30 minutes (1800)
      SLEEP=$[ ( $RANDOM%1800+60  ) ]
      rm -rf $DOWNLOADDIR/*.rpm
      echo "update completed, server will reboot in $SLEEP seconds"
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

#Check that there is only one command line option, any more and we'll
#print usage and exit
if [ "$#" -gt "1" ]; then
   echo "ERROR: TOO MANY COMMAND LINE OPTIONS PROVIDED"
   usage
   exit 1
fi

check_version
check_prereqs

while getopts "hcu" OPTION
do
   case $OPTION in
      h)
         usage
         exit 0 
         ;;
      c)
         check_redhat
         ;;
      u)
         update_redhat
         ;;
      ?)
         usage
         exit 1
         ;;
     esac
done
