#!/usr/bin/perl

## Script written by Noah Guttman and Copyright (C) 2011 Noah Guttman. This script is released and distributed under the terms of the GNU General Public License

#Libraries to use
#use strict;
use lib "/usr/local/nagios/perl/lib";
use lib "/usr/local/nagios/libexec/";
use Getopt::Std;

# Check for proper args....

use vars qw($opt_h $opt_H $opt_U $opt_P $opt_M);
my $currentStatus;
my $exitcode=3;
my @statusList;
my $val;

if ($#ARGV le 0) {
        print "::IMPI Server Check Instructions::\n\n";
        print " -h,             Display this help information\n";
        print " -H,             Hostname or IP to check\n";
        print " -M,             Specify a message to return on failure\n";
        print " -U,             Username to connect\n";
        print " -P,             Password to connect\n";
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
        getopts('hH:U:P:M:');
}


## Display Help
if ($opt_h){
        print "::IMPI Server Check Instructions::\n\n";
        print " -h,             Display this help information\n";
        print " -H,             Hostname or IP to check\n";
        print " -M,             Specify a message to return on failure\n";
        print " -U,             Username to connect\n";
        print " -P,             Password to connect\n";
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

#Get the data
$currentStatus = `ipmitool -I lanplus -L USER -H $opt_H -U $opt_U -P $opt_P sdr elist all |grep -v " ns "`;

@statusList = split("\n", $currentStatus);

#Check if there are any Errors, Warnings or Criticals
if ($currentStatus =~ /OK/i){
        $exitcode =0;
#        print "OK:";
}

if ($currentStatus =~ /Error/i){
        foreach my $val (@statusList) {
                if ($val =~ /ERROR/i){
			if ($val =~ /ok/i){
				#false alarm
			}else{
				$exitcode =3;
				print "ERROR:";
				my $error_message = (split(/ +\|/, $val))[4];
                       		print "$error_message **";
			}
                }
        }

}

if ($currentStatus =~ /Warning/i){
        foreach my $val (@statusList) {
                if ($val =~ /WARNING/i){
                        if ($val =~ /ok/i){
                                #false alarm
                        }else{
                                $exitcode =1;
                                print "WARNING:";
                                my $error_message = (split(/ +\|/, $val))[4];
                                print "$error_message **";
                        }
                }
        }
	
}

if ($currentStatus =~ /Critical/i){
	foreach my $val (@statusList) {
		if ($val =~ /CRITICAL/i){
                        if ($val =~ /ok/i){
				if ($val =~ /In Critical Array/i){
				  $exitcode =2;
				  my $error_message = (split(/ +\|/, $val))[4];
				  print "$error_message **";
				}
                                #false alarm
                        }else{
                                $exitcode =2;
                                print "CRITICAL:";
                                my $error_message = (split(/ +\|/, $val))[4];
                                print "$error_message **";
                        }
#			print "$val ";
		}
	}
}
if ($currentStatus =~ /OK/i){
	print "OK: The remaining checks were all OK|";
	foreach my $val (@statusList){
		if (((($val =~ /Temp/i) || ($val =~ /Ambient Temp/i)) || ($val =~ /System Level/i)) ||($val =~ /FAN MOD/i)){
			#print "\n$val\n";
			@resultArray = split(/ +\|/, $val);
			#print "\n***$resultArray[0]***$resultArray[4]***\n";
			@performanceArray = split(" ", @resultArray[4]);
			$resultArray[0] =~ s/ /_/g;
	
			print "$resultArray[0]"."_"."$performanceArray[1]"."="."$performanceArray[0];;; ";
			#print "\n------\n";
		}

	} 
}else{
	print ("UNKNOWN: check seems to have timed out. Error: $currentStatus - Do *NOT* contact On-Call. iDRACs are not production\n");

}


#print "\n$currentStatus\n";

#print ("\n$exitcode\n");
print "\n";
exit $exitcode; 


