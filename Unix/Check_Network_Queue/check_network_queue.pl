#!/usr/bin/perl


## Script written by Noah Guttman and Copyright (C) 2011 Noah Guttman. This script is released and distributed under the terms of the GNU General Public License

#Libraries to use
use lib "/usr/local/nagios/libexec";
use lib "/usr/lib/nagios/plugins";
use lib "/usr/lib64/nagios/plugins";

use strict;
use warnings;
use Getopt::Std;
use utils qw(%ERRORS);

use vars qw($opt_h $opt_w $opt_c $opt_p $opt_d);
$opt_w = 1000;
$opt_c = 1000;
$opt_p ="UDP";
$opt_d ="Recv-Q";
my @output;
my $warnings=0;
my $criticals=0;
my $badqueue ="";
my $queue=0;
my $longoutput="|";
my $stat;

my $sudo_rights;

$SIG{'ALRM'} = sub {
  print "Something has gone wrong and the check has timed out. This should be looked into\n";
  exit $ERRORS{'UNKNOWN'};
};
alarm 20;

if ($#ARGV le 0) {
  $opt_h=1;
}else{
  getopts('hw:c:d:p:');
}
## Display Help
if ($opt_h){
  print "::Network Queue Instructions::\n\n";
  print "This check requres that nagios can run netstat using the sudo command\n";
  print " -h,             Display this help information\n";
  print " -w,             Per UDP/TCP stream queue before WARNING. default: 1000\n";
  print " -c,             Per UDP/TCP stream queue before CRITCIAL. deafult 1000\n";
  print " -d,             Direction of traffic we are checking (Recv-Q|Send-Q) default:Recv-Q\n";
  print " -p,             Which protocol to check (TCP|UDP) default: UDP\n";
  print "Performance data is only provided for all queues with non-zero lengths\n";
  print "Script written by Noah Guttman and Copyright (C) 2011 Noah Guttman.\n";
  print "This script is released and distributed under the terms of the GNU\n";
  print "General Public License.     >>>>    http://www.gnu.org/licenses/\n\n";
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

#We need to check if we can sudo netstat
#On man *nix systems if you have entries in the sudoers file then running sudo -l
#will prompt for a pssword rather than syaing you have no sudo rights (and then say you have no rights)
#We get arround this by adding -A
#if there are entires in sudoers they are returned
#if there are no entires we get an error about nothing defined to use with -A
#In either case the script can contiue rather than locking.
$sudo_rights = `sudo -l -A |grep NOPASSWD`;
if (($sudo_rights =~ m\netstat\) || ($sudo_rights =~ m\all\i)){
  print ("Check requires that nagios be allowed to sudo NOPASSWD the netstat utility without a TTY shell.\n");
  exit $ERRORS{'CRITICAL'};
}



if ($opt_p =~ /UDP/){
	if ($opt_d =~ /Send-Q/){
		@output = (`sudo netstat -uldn |grep udp |awk \'{print \$4"="\$3}\'`);
	}else{
		@output = (`sudo netstat -uldn |grep udp |awk \'{print \$4"="\$2}\'`);
	}
}elsif ($opt_p =~ /TCP/){
        if ($opt_d =~ /Send-Q/){
		@output = (`sudo netstat -tldn |grep tcp |awk \'{print \$4"="\$3}\'`);
        }else{
		@output = (`sudo netstat -tldn |grep tcp |awk \'{print \$4"="\$2}\'`);
	}
}else{ 
	print "You must define the protocol you wish to check (-p) as either TCP or UDP\n";
	exit 3;
}

chomp(@output);
foreach $stat (@output){
	if ($stat =~ m/^\=0/){
		$queue = (split("=",$stat))[1];
		if ($queue >= $opt_c){
			$criticals++;
			$badqueue = "$badqueue $stat";
		}elsif($queue >= $opt_w){
			$warnings++;
                        $badqueue = "$badqueue $stat";
		}
		$longoutput = ("$longoutput$stat;; ");
	}
}
if ($criticals >0){
	print "CRITICAL: one or more $opt_p $opt_d queues are too long - $badqueue$longoutput\n";
	exit 2
}elsif ($warnings >0){
        print "WARNING: one or more $opt_p $opt_d queues are getting too long - $badqueue$longoutput\n";
        exit 1
}else{
	print "OK:All $opt_p $opt_d queues are within allowed levels$longoutput\n";
        exit 0;
}
