#!/usr/bin/perl -w


## Script written by Noah Guttman and Copyright (C) 2014 Noah Guttman. This script is released and distributed under the terms of the GNU General Public License

#Libraries to use
use lib "/usr/lib/perl5/5.8.8/";
use lib "/usr/lib/perl5/5.8.8/Getopt/";

use strict;
use Getopt::Std;

our ($opt_h);

my @ointerfaces;
my @tinterfaces;
my $RX_BPS;
my $RX_PPS;
my $RX_EPS;
my $RX_MPS;
my $TX_BPS;
my $TX_PPS;
my $TX_EPS;
my $interfacename;
my $opt_t = "/tmp/network_statistics2.tmp";
my $longoutput = "Service check collects network statistics and returns OK|";
my $currenttime;
my $lastchecktime;
my $deltatime;
my $commandstring;
        getopts('h');

## Display Help
if ($opt_h){
        print "::Network Statistics Instructions::\n\n";
        print " -h,             Display this help information\n";
#	print " -t,             Path to store the pervious check results\n";
#	print "			 used to calculate deltas.\n";
	print "                 Writes temporary data to $opt_t\n";
        print "Script written by Noah Guttman and Copyright (C) 2014 Noah Guttman.\n";
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


#First we get the current time
$currenttime = time();
#Second we need to check if there is history file in /tmp/.If so then we pull in the data
if (-e "$opt_t"){
	$lastchecktime = (`cat $opt_t |grep time |awk \'{print \$2}\'`);
	chomp ($lastchecktime);
	$deltatime=($currenttime - $lastchecktime);
	@ointerfaces= (`cat $opt_t`);
}else{
	print ("First time running test - Results will be available starting next test\n");
	
#We need to pull the data and write it to the tmp file.

#	exit 0;
}
## Now we pull the current data and write it to the tmp file. 
#we check is each stat exists before we pull it.

	@tinterfaces= (`cat /proc/net/dev |grep : |awk -F : \'{print \$1" "\$2}\'|awk \'{print \$1" "\$2" "\$3" "\$4" "\$9" "\$10" "\$11" "\$12}\'`);

## Next we write the data to the tmp file
#First we wipe out the old file
$commandstring = ("/bin/rm -f $opt_t");
system ($commandstring);
#Next we populate the string
$commandstring = ("/bin/echo \'time $currenttime\' \>\> $opt_t");
system ($commandstring);
$commandstring = ("cat /proc/net/dev |grep :|awk -F : \'{print \$1\" \"\$2}\'|awk \'{print \$1\" \"\$2\" \"\$3\" \"\$4\" \"\$9\" \"\$10\" \"\$11\" \"\$12}\' \>\> $opt_t");
#print ("$commandstring\n");
system ($commandstring);


##Here goes the math
foreach my $interface (@tinterfaces){
	foreach my $oldinterface (@ointerfaces){
		if (((split(" ",$interface))[0]) eq ((split(" ",$oldinterface))[0])){
			$interfacename = (split(" ",$interface))[0];
			$RX_BPS = ((split(" ",$interface))[1] - (split(" ",$oldinterface))[1]) / $deltatime;
                        $RX_PPS = ((split(" ",$interface))[2] - (split(" ",$oldinterface))[2]) / $deltatime;
                        $RX_EPS = ((split(" ",$interface))[3] - (split(" ",$oldinterface))[3]) / $deltatime;
                        $RX_MPS = ((split(" ",$interface))[4] - (split(" ",$oldinterface))[4]) / $deltatime;
                        $TX_BPS = ((split(" ",$interface))[5] - (split(" ",$oldinterface))[5]) / $deltatime;
                        $TX_PPS = ((split(" ",$interface))[6] - (split(" ",$oldinterface))[6]) / $deltatime;
                        $TX_EPS = ((split(" ",$interface))[7] - (split(" ",$oldinterface))[7]) / $deltatime;

			$longoutput = $longoutput .$interfacename."_RX_BPS"."=$RX_BPS"."B;; ";
                        $longoutput = $longoutput .$interfacename."_RX_PPS"."=$RX_PPS;; ";
                        $longoutput = $longoutput .$interfacename."_RX_EPS"."=$RX_EPS;; ";
                        $longoutput = $longoutput .$interfacename."_RX_MPS"."=$RX_MPS;; ";
                        $longoutput = $longoutput .$interfacename."_TX_BPS"."=$TX_BPS"."B;; ";
                        $longoutput = $longoutput .$interfacename."_TX_PPS"."=$TX_PPS;; ";
                        $longoutput = $longoutput .$interfacename."_TX_EPS"."=$TX_EPS;; ";
		}
	}
	
}

print ("$longoutput\n");
exit 0;  
