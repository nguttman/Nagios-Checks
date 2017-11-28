# Basic Plugin Help



## Process Resource Usage Check Instructions
 -h|help,  Display this help information
 

-nosudo,  Do not use the sudo cat command to read files as needed

Using this option will likely prevent the check from working when run as any user other than root.

-C|Check,  Specify a check type: 
* PCPU(%) - CPU usage as reurtned by the **ps** command
* ICPU(%) - CPU usage as reurtned by the **top** command with a 1 second sample
* ACPU(%) - Average CPU usage since the last time this check was run. This data is gather by reading the files under /proc/
* Memory(%) Memory used expressed as a percentage of total system memory. This data is gathered by reading the file under /proc/.
* VSZ,
* RSS,
* IO,
* PSS, stats
* PSS reports actual memory usage with the duplicate counting of shared memory



ACPU uses the files under /proc/ to get the average CPU since the last check run.

IO uses the files under /proc/ to get the average disk/cache IO since last run.

Note: The ACPU and IO options only works with a PID file (see below)

stats will report CPU,Memory, VSZ and RSS by default

It will only alert if the process is not running

***These options only work is you are checking via a .pid file***

-nochildren  Do not include children in the data collected. 

-diskio,  Add disk IO information to stats check

-average_cpu,  Add average cpu (ACPU) information to stats check 

***These options are for the stats and ACPU checks only***

-multicpu,  Use CPU values like that of top and ps rather than true percantages

With this option the max cpu usage is 100% * number of logical cores

Without this option max cpu usage is 100% 

***The following options only work for the CPU and memory checks*** 

-w|warning,  Specify a warning level for the check

The default is 60 percent or 1000000 kilobytes

-c|critical,  Specify a critical level for the check

The default is 70 percent or 2000000 kilobytes

-M|message,  Specify a message to return on failure

-R|startup,  The script to use to restart the process

If selected this will be added the the output on CRITICAL

This is an easy way to pass information to an Event Handler

***Highly reccomended that you use this***

-N|name,  Specify a differnet name for the process

This is for display in Nagios messages

Example: check_process -P /var/run/mysqld.pid -N MasterDB

The mysqld process will be monitored and the Nagios message will read:

The MasterDB process is currently OK.

***Only use one of the following***

-p|processname,  Specify a process name to be monitored

-a|argument,  Specify a process with the following argument in the

command line to be monitored

-P|PID,  Specify a PID file containg the PID to be monitored

***Note: Checks by PID file include all children (by default), but not grandchildren***

