# Basic Plugin Help

The script exists to be the one stop solution for collecting performace data on the  disks of UNIX systems. It runs on all major distributions and can report the usefull information that can be gleaded from the Kernel. Currently the script does not support allerts on individual statistics or disks - if you would like to see that feature implemented make sure to le me know. The script uses a temporary file to caulate average values since the last time the script was run.

## Installation

The installation needs will be slightly different based on what system you are going to use to run the script. Most people will run this script via NRPE or the via check_by_ssh which is included in most Nagios like packages. Check the documentation of whatever you are using for specific instructions.

This script needs to be installed on every server where you wish for it to check the status of processes.

## Requirements to run correctly

This script is written in Perl and uses the standard libraries of `warnings`, `strict`, `Getopt::Long`,  and 'Time::HiRes'. It also uses the custom library of  `utils` which is one of the standard libraries included with every NRPE (Nagios Remote Plugin Executor) installation. 
 
The script uses the `cat` command to load data (from the /tmp/ and /proc/ directoroes) and the `echo` command to write a temporary file at /tmp/disk_statsticts.tmp If you reun the script manualy as root, or as the wrong user, you may break the script by writing a file to /tmp/ that cannot be overwritten by Nagios. If this occurs, just delete the temporary file. 

## Disk Statistics Check Instructions

 -h,             Display this help information
 -d,             Disk to check - This can be specified multiple times, or you can specift *all*
                   to collect data on all disks

The script collects and reports the following metrics for each of the selected disks:
 
 * Average number of read opperations per second since the last time the script was run.
 * Average data reads per scond (in KB) since the last time the script was run.
 * Average number of write opperations per second since the last time the script was run.
 * Average data writes per scond (in KB) since the last time the script was run.
 * Average percentage of time the disk was engaed in IO oprations (%) since the last time the script was run
 * Average IO utilisation (%) since the last time the script was run
