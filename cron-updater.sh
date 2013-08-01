#!/bin/bash
# Wrapper script to check if it is the second week of the month.
# if it is run the script, if not, exit
#
# RMC - 08/03/2013

DATE=`date "+%d"`
DAY=`date "+%a"`

if [ "$DAY" == Mon ];
then
   if [ $DATE -ge 8 -a $DATE -le 14 ];
   then
      $1
   else
      exit 0
   fi
elif [ "$DAY" == Tue ];
then
   if [ $DATE -ge 9 -a $DATE -le 15 ];
   then
      $1
   else
      exit 0
   fi
elif [ "$DAY" == Wed ];
then
   if [ $DATE -ge 10 -a $DATE -le 16 ];
   then
      $1
   else
      exit 0
   fi
elif [ "$DAY" == Thu ];
then
   if [ $DATE -ge 11 -a $DATE -le 17 ];
   then
      $1
   else
      exit 0
   fi
else
   exit 0
fi
