#!/bin/bash

DAY=`date +%a`
DATE=`date +%d`

if [ "$DAY" == Mon ];
then
   if [ $DATE -ge 8 -a $DATE -le 14 ];
   then
      echo "It is Monday 2nd Week"
   else
      echo "Not Monday 2nd Week"
      exit 1
   fi
elif [ "$DAY" == Tue ];
then
   if [ $DATE -ge 9 -a $DATE -le 15 ];
   then
      echo "It is Tuesday 2nd Week"
   else
      echo "Not Tuesday 2nd Week"
   fi
elif [ "$DAY" == Wed ];
then
   if [ $DATE -ge 10 -a $DATE -le 16 ];
   then
      echo "It is Wednesday 2nd Week"
   else
      echo "Not Wednesday 2nd Week"
   fi
elif [ "$DAY" == Thu ];
then
   if [ $DATE -ge 11 -a $DATE -le 17 ];
   then
      echo "It is Thursday 2nd Week"
   else
      echo "Not Thursday 2nd Week"
   fi
else
   echo "Not a day we want to action. Exiting"
   exit 1
fi
