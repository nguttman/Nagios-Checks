#!/usr/bin/perl

## Script written by Noah Guttman and Copyright (C) 2015 Noah Guttman. This script is released and distributed under the terms of the GNU General Public License

#Libraries to use
#use strict;
use lib "/usr/local/nagios/perl/lib";
use lib "/usr/local/nagios/libexec/";
use Getopt::Std;
use utils qw(%ERRORS);

# Check for proper args....

use vars qw($opt_h $opt_H $opt_U $opt_P $opt_M);
my $currentStatus;
my $exitcode=3;
my @statusList;
my $val;

# Make the Nagios devs happy
$SIG{'ALRM'} = sub {
  print "Something has gone wrong and the check has timed out. This should be looked into\n";
  exit $ERRORS{'UNKNOWN'};
};
alarm 20;


&usage() if @ARGV == 0;
        
getopts('hH:U:P:M:');

## Display Help
if ($opt_h){
	usage();
}

#Get the data
$currentStatus = `ipmitool -I lanplus -L USER -H $opt_H -U $opt_U -P $opt_P sdr elist all |grep -v " ns "`;

@statusList = split("\n", $currentStatus);

#Check if there are any Errors, Warnings or Criticals
if ($currentStatus =~ /OK/i){
	#If there is at leaste one OK returned then we start with the assumption that we are OK
	$exitcode =0;
}

if ($currentStatus =~ /Error/i){
	#We found at least one error so we want to verify it is a real error and return the error information
  foreach my $val (@statusList) {
    if ($val =~ /ERROR/i){
			if ($val =~ /ok/i){
				#false alarm - Some IMPI output lines are about errors and return OK (as in there are no errors)
			}else{
				#Real error, so we print it, and set the exit code 
				#we do errors first because they are the lowest severity of alerts
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
          #false alarm Some IMPI output lines are about WARNING and return OK (as in there are no warnings)
      }else{
        #Real warning event, so we print it, and set the exit code 
				#we do WARNINGs second because they are the second lowest severity of alerts
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
				  #This is a special case we discovered on some dell servrs where a RAID array is in a critical satte, but the IMPI check returns OK anyways.
				  $exitcode =2;
				  my $error_message = (split(/ +\|/, $val))[4];
				  print "$error_message **";
				}
      	#false alarm - Some IMPI output lines are about CRITICALs and return OK (as in there are no criticals)
      }else{
      	#Real critical event, so we print it, and set the exit code 
				#we do CRITICALs last because they are the highest severity of alerts
        $exitcode =2;
        print "CRITICAL:";
        my $error_message = (split(/ +\|/, $val))[4];
        print "$error_message **";
      }
		}
	}
}
# If there were at least one check that was OK (or not) then we let the user know and start parsing perfomance data.
if ($currentStatus =~ /OK/i){
	print "OK: The remaining checks were all OK|";
}else{
	print "None of the remaining checks were OK|";
}
#If you are using the check on a server that I have not tested with then this parsing may require some editing. 
foreach my $val (@statusList){
	if (((($val =~ /Temp/i) || ($val =~ /Ambient Temp/i)) || ($val =~ /System Level/i)) ||($val =~ /FAN MOD/i)){
		@resultArray = split(/ +\|/, $val);
		@performanceArray = split(" ", @resultArray[4]);
		$resultArray[0] =~ s/ /_/g;
		print "$resultArray[0]"."_"."$performanceArray[1]"."="."$performanceArray[0];;; ";
	}
} 
#We print a final newline and then exit with the correct exit code
print "\n";
if ($exitcode == 0){
	exit $ERRORS{'OK'};
}elsif ($exitcode == 1){
	exit $ERRORS{'WARNING'};
}elsif ($exitcode == 2){
	exit $ERRORS{'CRITICAL'};
}else{
	exit $ERRORS{'UNKNOWN'};
}

#Subs are below
sub usage {
	print "::IMPI Server Check Instructions::\n\n";
  print " -h,             Display this help information\n";
  print " -H,             Hostname or IP to check\n";
  print " -M,             Specify a message to return on failure\n";
  print " -U,             Username to connect\n";
  print " -P,             Password to connect\n";
  print "Script written by Noah Guttman and Copyright (C) 2015 Noah Guttman.\n";
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
  exit $ERRORS{'OK'};
}
