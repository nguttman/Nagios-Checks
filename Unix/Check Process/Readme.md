# Basic Plugin Help

The script exists to be the one stop solution for UNIX process monitoring. It runs on all major distributions and can evaluate all  information available from the kernel about the health and activity of a process. 

## Installation

The installation needs will be slightly different based on what system you are going to use to run the script. Most people will run this script via NRPE or the via check_by_ssh which is included in most Nagios like packages. Check the documentation of whatever you are using for specific instructions.

This script needs to be installed on every server where you wish for it to check the status of processes.

## Requirements to run correctly

This script is written in Perl and uses the standard libraries of `warnings`, `strict`, and `Getopt::Long`. Ity also uses the custom library of  `utils` which is one of the standard libraries included with every NRPE (Nagios Remote Plugin Executor) installation. 
 
Depending on what switches are passed it can invoke the bash commands : `sudo`, `cat`, `ps`, `top` and `rm`. Unless you plan (foolishly) on having the script run as root you will need to allow the user that does run the script to run the `sudo cat` command without a password ans without a full shell.  

## Process Resource Usage Check Instructions

Below are all of the switches that can be used when running this check script as well as brief explanation as to how they work. They are arranged in no particular order.

-nosudo : This switch tells the script to try and read all files that it needs to do its job (.pid files and files under /proc) without ever invoking invoking the `sudo cat` command. Using this option will likely prevent the check from working correctly as normally the check will be run by the *nagios* user which lacks the needed read permissions to files under /proc/.

-C|Check : This switch **must** be used in order for the script to do anything useful. If you attempt to run the script without declaring a valid check the script will exit with an Error (Code:3) and print out the usage help. Below are the possible options; 
* PCPU(%) - CPU usage as returned by the **ps** command
* ICPU(%) - CPU usage as returned by the **top** command with a 1 second sample
* ACPU(%) - Average CPU usage since the last time this check was run. This data is gather by reading the files under /proc/ and through the reading/writing of temporary files under /tmp/.
* Memory(%) Memory used expressed as a percentage of total system memory. This data is gathered by reading the file under /proc/ and by default includes the memory used by any children processes. On newer kernels (CentOS/RHEL 6/7 & Ubuntu 15/16, etc) this check measures memory correctly (unlike **ps** which counts the shared memory as part of each child process as well as the parent). 
* VSZ - Virtual Set Size. This represents how much memory is currently available to the the process. This data is gathered by reading the file under /proc/ and by default includes the memory used by any children processes. This amount of memory is being reserved (but not necessarily used) in RAM and Swap.  
* RSS - Resident Set Size. This represents how much memory is currently in use by the process. This amount of memory is being reserved (but not necessarily used) in RAM and Swap. When dealing with processes that have children or share memory in other ways, RSS should not be used as it incorrectly counts any shared memory once for each child in addition to the parent. Instead you should use (if possible) the **PSS** check. This data is gathered by reading the file under /proc/.
* PSS - Proportional Set Size. This is an updated and more accurate check than RSS as it (correctly) only counts shared memory once (as part of the Parent process). Unfortunately on some older Kernels this statistic is not available - in which case this check will rerun a PSS of 0 Bytes. This data is gathered by reading the file under /proc/.
* IO - Disk IO statistics. **This check only reports on read/write operations performed by the process being monitored.** This check does not support warning/critical thresholds and will only alert if the process is not running. It reports the following seven averages that are calculated by using temporary files (in /tmp/) and reading the correct counter values under /proc/. The results are averages since the last time the check was run.
  * Average data read per second (in Bytes). The statistic includes **both** reads from disk and reads from data the Kernel kept cached in memory.
  * Average data written per second (in Bytes). The statistic includes **both** writes to disk and writes to data the Kernel decided to cache and write later. 
  * Average number of read operations per second. The statistic includes **both** reads from disk and reads from data the Kernel kept cached in memory.
  * Average number of write operations per second. The statistic includes **both** writes to disk and writes to data the Kernel decided to cache and write later. 
  * Average data read per second **from disk** (in Bytes). This statistic includes and preemptive reads the Kernel chooses to perform.
  * Average data written per second **to disk** (in Bytes). This statistic includes any writes that Kernel previously wrote to cache and has now decided to commit to disk.
  * Average data that was scheduled to be written to disk per second **where the write was cancelled** (in Bytes). It is normal for writes to be cancelled sometimes, but if you find this statistic is high it may indicate an operation or coding problem with the process.
* stats - Check that process is running and gather basic statistics as performance data. By default this will collect and return the statistics data of the **CPU, Memory, VSZ, RSS and PSS** Checks 

### In addtition the following switches can be used to add performance data to any basic check.

-diskio,  Add disk IO information to stats check

-average_cpu,  Add average CPU (ACPU) information to stats check 


### Choosing a method of how to identify what process(es) to check.

You must specify one **and only one** of the following switches and information so that the script knows how to identify the correct process(es). 

-p|processname,  Specify a process name to be monitored. This is usually just the name of the executable. No command line arguments are used.

-a|argument,  Specify a process with the following argument in the command line to be monitored

-P|PID,  Specify a PID file containg the PID to be monitored. **This is the best method and should always be used**.

***Note: Checks by PID file include all children (by default), but not grandchildren.*** The two other process identification methods may or may not include children and grandchildren - it depends on how the process.


***These options only work is you are checking via a .pid file***

-nochildren  Do not include children in the data collected. 

***These options are for the stats and ACPU checks only***

-multicpu,  Use CPU values like that of top and ps rather than true percentages

With this option the max cpu usage is 100% * number of logical cores. Without this option max cpu usage is 100% 

**The following options only work for the CPU and memory checks** 

-w|warning,  Specify a warning level for the check. The default is 60 percent or 1000000 kilobytes

-c|critical,  Specify a critical level for the check .The default is 70 percent or 2000000 kilobytes

**The following options are highly recommended** 

-M|message,  Specify a message to return on failure. This is a great way to point support teams to documentation on how to deal with failures.

-R|startup,  The script to use to restart the process. If selected this will be added as the firest piece of text output on CRITICALs and can be easily parsed out by an event handler script.

-N|name,  Specify a differnet name for the process **Highly recommended that you use this to avoid confusion** For example: `check_process -P /var/run/mysqld.pid -N MasterDB ...` will return the `The MasterDB process is currently OK...` rather than referencing the PID file and path.
