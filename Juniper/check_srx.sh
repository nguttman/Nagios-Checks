#!/bin/bash

# Bash script to check the status of a SRX cluster.
#  Works by SSHing into cluster to check "show chassis cluster status" command and SNMP walking to make sure BGP peers
#  are both in a connected state


pluginpath="/usr/local/nagios/libexec"

pluginname=`basename $0`

. $pluginpath/utils.sh



while getopts "H:h" options; do

  case $options in

        H)clusterAddress=$OPTARG;;

        *)

          echo ":: $pluginname Check Instructions ::"
          echo ""
          echo "-H <Hostname> : Hostname/IP of JunOS SRX cluster"
          echo "Usage: $pluginname -H <HOSTADDRESS>"
          echo ""
          echo "You must create a trusted key relationship between the nagios user"
	  echo "on the monitoring server and the opsview user on the SRX cluster for this to work"
	  echo ""
	  echo "Script written by Noah Guttman and Copyright (C) 2014 Noah Guttman."
	  echo "This script is released and distributed under the terms of the GNU"
	  echo "General Public License.     >>>>    http://www.gnu.org/licenses/"
	  echo ""
	  echo "This program is free software: you can redistribute it and/or modify"
	  echo "it under the terms of the GNU General Public License as published by"
	  echo "the Free Software Foundation."
	  echo "This program is distributed in the hope that it will be useful,"
	  echo "but WITHOUT ANY WARRANTY; without even the implied warranty of"
	  echo "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the"
	  echo "GNU General Public License for more details."
	  echo ">>>>    http://www.gnu.org/licenses/"
          exit 3

        ;;

  esac

done


#
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

clusterStatus=`ssh opsview@$clusterAddress "show chassis cluster status"`


declare -i primaryCount
declare -i secondaryCount
declare -i failoverCount




primaryCount=`echo "$clusterStatus" | grep primary | wc -l`
secondaryCount=`echo "$clusterStatus" | grep secondary | wc -l`
failoverCount=`echo "$clusterStatus" | grep "Failover count" | wc -l`

if [ $primaryCount -ne 2 ]
then
        echo "No two primary redundancy groups"
		echo "$clusterStatus"
        exit $STATE_CRITICAL
fi

if [ $secondaryCount -ne 2 ]
then
        echo "No two secondary redundancy groups"
		echo "$clusterStatus"
        exit $STATE_CRITICAL
fi

if [ $failoverCount -ne 2 ]
then
        echo "SRX has fallen over on a redundancy group"
		echo "$clusterStatus"
        exit $STATE_WARNING
fi


echo "OK, 2 peers.  OK: Chassis Cluster status OK"
echo "$clusterStatus"
exit $STATE_OK
