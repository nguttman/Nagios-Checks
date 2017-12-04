#!/usr/bin/perl


## Script written by Noah Guttman and Copyright (C) 2014 Noah Guttman. This script is released and distributed under the terms of the GNU General Public License

#Libraries to use
use lib "/usr/local/nagios/libexec";
use lib "/usr/lib/nagios/plugins";
use lib "/usr/lib64/nagios/plugins";

use strict;
use warnings;
use Getopt::Long qw(:config posix_default bundling);
use Time::HiRes qw(gettimeofday);
use utils qw(%ERRORS);

our @opt_d;

my @old_disks;
my @new_disks;
my $disk_name;
my $reads_completed;
my $sectors_read;
my $time_reading;
my $writes_completed;
my $sectors_written;
my $time_writing;
my $weighted_time_IO;
my $deltatime;
my $currenttime;
my $lastchecktime;
my $clock_delta;
my $clock_time;
my $old_clocktime;
my $opt_t = "/tmp/disk_statistics.tmp";
my $longoutput = "OK: Service check collects disk statistics and returns OK|";
my $commandstring;

# Make the Nagios devs happy
$SIG{'ALRM'} = sub {
  print "Something has gone wrong and the check has timed out. This should be looked into\n";
  exit $ERRORS{'UNKNOWN'};
};
alarm 20;





GetOptions(
  'h|help' => sub { usage() },
  'd|disk=s' => \@opt_d,
) || usage();

if (!@opt_d){
  usage();
}

## Display Help
sub usage {
  print "::Disk Statistics Instructions::\n\n";
  print " -h,             Display this help information\n";
  print " -d,             Disk to check - This can be specified multiple times\n";
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
  exit $ERRORS('OK');
}



#First we get the current CPU and time stats we need.
$currenttime = (`cat /proc/stat |grep "cpu " |awk \'{print \$2 + \$3 + \$4 + \$5 + \$6 + \$7 + \$8}\'`);
chomp($currenttime);
$clock_time = gettimeofday;
#Next we check if there is an old temp file - if there is we load its data.
if (-e "$opt_t"){
	$lastchecktime = (`cat $opt_t |grep cputime |awk \'{print \$2}\'`);
	$old_clocktime = (`cat $opt_t |grep clocktime |awk \'{print \$2}\'`);
        $deltatime=($currenttime - $lastchecktime) *10;
	$clock_delta = ($clock_time - $old_clocktime);
	@old_disks= (`cat $opt_t |grep -v time`);
}else{
  print ("First time running test - Results will be available starting next test\n");
  #We need to pull the data and write it to the tmp file, but we do that below anyways.
}
## Now we pull the current data and write it to the tmp file. 

@new_disks= `cat /proc/diskstats |grep -v ram`;

#We construc the new tmp file and try and write it - exiting on an aerro if we can't.
$commandstring = ("echo -n \"cputime $currenttime\nclocktime $clock_time\n @new_disks\" \> $opt_t");
my $bash_exit_code = system ($commandstring);
  if ($bash_exit_code != 0){
  print ("UNKNOWN:Unable to create the new temp file at: $opt_t. Without this file the script cannot calculate Disk IO statistics.\n");
  exit $ERRORS{'UNKNOWN'};
}

#Now we have all of the data so we can itterate through it and do all the math.
foreach my $current_disk (@new_disks){
  foreach my $check_disk (@opt_d){
    if ($check_disk eq (split(" ",$current_disk))[2]){
      foreach my $old_disk (@old_disks){
        if (((split(" ",$current_disk))[2]) eq ((split(" ",$old_disk))[2])){
          $disk_name = (split(" ",$current_disk))[2];

          $reads_completed = ((split(" ",$current_disk))[3]-(split(" ",$old_disk))[3]) /$clock_delta;
          $reads_completed = sprintf("%.4f",$reads_completed);

          $sectors_read = ((split(" ",$current_disk))[5] - (split(" ",$old_disk))[5])/2/$clock_delta;
          $sectors_read= sprintf("%.4f", $sectors_read);

          $time_reading = (((split(" ",$current_disk))[6] - (split(" ",$old_disk))[6]) / $deltatime);
          $time_reading = sprintf("%.4f", $time_reading);

          $writes_completed = ((split(" ",$current_disk))[7]-(split(" ",$old_disk))[7])/$clock_delta;
          $writes_completed  = sprintf("%.4f",$writes_completed);

          $sectors_written =((split(" ",$current_disk))[9]-(split(" ",$old_disk))[9])/2/$clock_delta;
          $sectors_written = sprintf("%.4f", $sectors_written);

          $time_writing =(((split(" ",$current_disk))[10] - (split(" ",$old_disk))[10]) / $deltatime);
          $time_writing= sprintf("%.4f", $time_writing);

          $weighted_time_IO =(((split(" ",$current_disk))[13]-(split(" ",$old_disk))[13])/$deltatime);
          $weighted_time_IO = sprintf("%.4f", $weighted_time_IO);

          $longoutput .= " $disk_name"."_reads_per_second=$reads_completed;;";
          $longoutput .= " $disk_name"."_read_per_second=$sectors_read"."KB;;";
          $longoutput .= " $disk_name"."_reading_util=$time_reading"."%;;";
          $longoutput .= " $disk_name"."_writes_per_second=$writes_completed;;";
          $longoutput .= " $disk_name"."_writen_per_second=$sectors_written"."KB;;";
          $longoutput .= " $disk_name"."_writing_util=$time_writing"."%;;";
          $longoutput .= " $disk_name"."_utilization=$weighted_time_IO"."%;;";
        }
      }
    }
  }	
}
#Since this check does not have alerts all we need to now is print out the performance data and exit cleanly.
print ("$longoutput\n");
exit $ERRORS{'OK'};  
