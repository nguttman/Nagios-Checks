#!/usr/bin/perl


## Script written by Noah Guttman and Copyright (C) 2011 Noah Guttman. This script is released and distributed under the terms of the GNU General Public License

#Libraries to use
use strict;
use Getopt::Std;
use Mysql;
use DBI;

use vars qw($opt_h $opt_H $opt_w $opt_c $opt_M $opt_P $opt_u $opt_p $opt_d $opt_b $opt_t);
$opt_t = 4;

my $returnmessage = " ";
my $errormessage = " ";
my $baseport;
my $topport;
my $warning;
my $critical;
my $threads;
my $returnname=" ";

my $USER="rtpXC";
my $PASS="qpz-krtpXC";
my $DB="TELXopensipsXC";
my $DBHOST="208.76.18.58";

my $RELOAD_RESULT;
my $i;
my $n;

my $gah;

my $errortotal =0;
my $warningtotal =0;
my $testerrortotal =0;
my $failedtotal =0;

my $connect;
my $query;
my $query_handle;

my $exitcode=3;
my $checkresult;
my $currentcalls=0;

my $threadsinroute;


my @OPENSIPS_MI_DATAGRAM_SOCKETS=("208.76.18.60 9191","208.76.18.57 9191","208.76.18.58 9191");
##init();

# Get the options
if ($#ARGV le 0) {
        print "::Process Resource Usage Check Instructions::\n\n";
        print " -h,             Display this help information\n";
        print " -H,             Hostname or IP to check\n";
        print " -w,             Specify a warning level for the check\n";
        print "                  The default is 20% failure\n";
        print " -c,             Specify a critical level for the check\n";
        print "                  The default is 30% failure\n";
        print " -t,             The number of tests to run per thread\n";
        print "                  The default is 4\n";
        print " -M,             Specify a message to return on failure\n";
        print " -P,             Base port to monitor\n";
        print "                  The default is 7899\n";
	print " -u,             Username to connect to the database\n";
	print " -p,             Password to connect to the database\n";
	print " -d,             Database name\n";
	print " -b,             Database hostname/IP\n";
        print "Script written by Noah Guttman and Copyright (C) 2011 Noah Guttman.\n";
        print "This script is released and distributed under the terms of the GNU\n";
        print "General Public License.     >>>>    http://www.gnu.org/licenses/\n";
        print "";
        print "This program is free software: you can redistribute it and/or modify\n";
        print "it under the terms of the GNU General Public License as published by\n";
        print "the Free Software Foundation.\n\n";
        print "This program is distributed in the hope that it will be useful,\n";
        print "but WITHOUT ANY WARRANTY; without even the implied warranty of\n";
        print "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n";
        print "GNU General Public License for more details.\n";
        print ">>>>    http://www.gnu.org/licenses/\n";
        exit 0;
} else {
	getopts('hH:w:c:M:P:u:p:d:b:t:');
}


## Display Help
if ($opt_h){
	print "::Process Resource Usage Check Instructions::\n\n";
	print " -h,		Display this help information\n";
	print " -H,		Hostname or IP to check\n";
        print " -w,		Specify a warning level for the check\n";
        print "                  The default is 20% failure\n";
        print " -c,		Specify a critical level for the check\n";
        print "			 The default is 30% failure\n";
        print " -t,             The number of tests to run per thread\n";
        print "                  The default is 4\n";
        print " -M,		Specify a message to return on failure\n";
        print " -P,		Base port to monitor\n";
        print "                  The default is 7899\n";
        print " -u,             Username to connect to the database\n";
        print " -p,             Password to connect to the database\n";
        print " -d,             Database name\n";
        print " -b,             Database hostname/IP\n";

        print "Script written by Noah Guttman and Copyright (C) 2011 Noah Guttman.\n";
        print "This script is released and distributed under the terms of the GNU\n";
        print "General Public License.     >>>>    http://www.gnu.org/licenses/\n";
        print "";
        print "This program is free software: you can redistribute it and/or modify\n";
        print "it under the terms of the GNU General Public License as published by\n";
        print "the Free Software Foundation.\n\n";
        print "This program is distributed in the hope that it will be useful,\n";
        print "but WITHOUT ANY WARRANTY; without even the implied warranty of\n";
        print "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n";
        print "GNU General Public License for more details.\n";
        print ">>>>    http://www.gnu.org/licenses/\n";
        exit 0; 
}

if ($opt_u){
	if ($opt_p){
		$USER=$opt_u;
	}else{
		print ("When defining custom database options u,p,d,b MUST all be used\n");
		exit 3;
	}
}
if ($opt_p){
	if ($opt_d){
		$PASS=$opt_p;
        }else{
                print ("When defining custom database options u,p,d,b MUST all be used\n");
                exit 3;
        }
}
if ($opt_d){
	if ($opt_b){
		$DB=$opt_d;
        }else{
                print ("When defining custom database options u,p,d,b MUST all be used\n");
                exit 3;
        }
}
if ($opt_b){
	if ($opt_u){
		$DBHOST=$opt_b;
        }else{
                print ("When defining custom Database options u,p,d,b MUST all be used\n");
                exit 3;
        }
}



##Set custom output if any set
if ($opt_M){
	$returnmessage=$opt_M;
}else{
	$returnmessage=" ";
}

if ($opt_w){
        $warning=$opt_w;
}else{
        $warning=30;
}
if ($opt_c){
        $critical=$opt_c;
}else{
        $critical=20;
}
if ($opt_P){
        $baseport=$opt_P;
}else{
        $baseport=7899;
}


#Check to see if RTP Proxy is currently in route
$connect = DBI->connect("dbi:mysql:$DB:$DBHOST:3306", $USER, $PASS);
$query="SELECT COUNT(rtpproxy_sock) FROM nh_sockets WHERE rtpproxy_sock LIKE \"%$opt_H%\"\; ";
$query_handle = $connect->prepare($query);
$query_handle->execute();
$query_handle->bind_columns(\$i);
while($query_handle->fetch()) {
        $threadsinroute= $i;
}
#print ("$threadsinroute");


#Set the top port to check
if ($threadsinroute == 0){
	$topport = ($baseport + 4);
}else{
$topport = ($baseport + $threadsinroute);
}

#Check that each thread is responding
for ( $i=$baseport; $i<$topport; $i++) {
	$testerrortotal = 0;
	for ($n=0; $n < $opt_t; $n++){
		$gah = (`echo \"opsview_123456789 V\"|nc -w 1 -D -u $opt_H $i| awk \'{print \$2}\'`);
#		print ("Test $n of thread $i \n");
		if ($gah == 20040107){
#			print ("$errortotal");
		}else{
			$testerrortotal++;
		}
#	sleep (1);
	}
	if (($testerrortotal*100 / $opt_t) > $critical){
		$errortotal = ($errortotal + $testerrortotal);
		$failedtotal++;
		$errormessage = ("$errormessage CRITICAL:Thread with port $i failed $testerrortotal out of $opt_t tests. ");
	}elsif (($testerrortotal*100 / $opt_t) > $warning){
		$warningtotal++;
		$errortotal = ($errortotal + $testerrortotal);  
                $errormessage = ("$errormessage WARNING:Thread with port $i failed $testerrortotal out of $opt_t tests. ");
	}else{
		$errortotal = ($errortotal + $testerrortotal);  
                $errormessage = ("$errormessage OK:Thread with port $i failed $testerrortotal out of $opt_t tests. ");
	}
}




#Create output and add/remove RTP Proxy from route
#Case 1 RTP Proxy responds AND RTP Proxy has at least 4 threads in route
if ((($failedtotal ==0) && ($warningtotal ==0 )) && (($threadsinroute == 4) || ($threadsinroute == 8))){
	print ("All OK:$errormessage|failedTests=$failedtotal;;;; critcalThreads=$errortotal;;;; warningThreads=$warningtotal;;;;\n");
	exit 0;
#Case 2 RTP Proxy responds BUT RTP Proxy has less than 4 threads in route
}elsif (($failedtotal ==0) && ($warningtotal ==0 )){
	print ("All OK but not in route:$errormessage|failedTests=$failedtotal;;;; critcalThreads=$errortotal;;;; warningThreads=$warningtotal;;;;\n");
	exit 1;
#Case 3 RTP Proxy does not respond normally and is still in route.
}elsif (($failedtotal >= 1) && ($threadsinroute !=0)) {
	print ("Critical:$returnmessage $errormessage|failedTests=$failedtotal;;;; critcalThreads=$errortotal;;;; warningThreads=$warningtotal;;;;\n");
	exit 2;
#Case 4 RTP Proxy does not respond normally and is out of route
}elsif (($failedtotal > 0) && ($threadsinroute ==0)) {
	print ("Critical:One or more rtpproxy threads not responding - RTP Proxy has already been taken out of route. $errormessage|failedTests=$failedtotal;;;; critcalThreads=$errortotal;;;; warningThreads=$warningtotal;;;;\n");
	exit 2;
#Case 5 One or more RTP Proxy thread responds at warning levels and is still in route
}elsif (($warningtotal >0) && ($threadsinroute !=0)){
	print ("Warning:$returnmessage $errormessage|failedTests=$failedtotal;;;; critcalThreads=$errortotal;;;; warningThreads=$warningtotal;;;; \n");
	exit 1;
#Case 6 One or more RTP Proxy thread responds at warning levels and is out of route
}elsif (($warningtotal >0) && ($threadsinroute ==0)){
	print ("Warning:One or more rtpproxy threads is at warning levels - RTP Proxy has already been taken out of route $errormessage|failedTests=$failedtotal;;;; critcalThreads=$errortotal;;;; warningThreads=$warningtotal;;;;\n");
	exit 1;
}
exit 3;
