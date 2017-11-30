# Basic Plugin Help



## Process Resource Usage Check Instructions

Below are all of the switches that can be used when running this check script as well as brief explanation as to how they work. They are arranged in no particular order.

-nosudo : This switch tells the script to try and read all files that it needs to do its job (.pid files and files under /proc) without ever invoking invoking the `sudo cat` command. Using this option will likely prevent the check from working correctly as normaly the check will be run by the *nagios* user which lacks the needed read permissions to files under /proc/.

-C|Check : This switch **must** be used in order for the script to do anything usefull. If you attemept to run the script without declaring a valid check the script will exit with an Error (Code:3) and pring out the usage help. Below are the possible options; 
* PCPU(%) - CPU usage as returned by the **ps** command
* ICPU(%) - CPU usage as returned by the **top** command with a 1 second sample
* ACPU(%) - Average CPU usage since the last time this check was run. This data is gather by reading the files under /proc/
* Memory(%) Memory used expressed as a percentage of total system memory. This data is gathered by reading the file under /proc/ and by default includes the memory used by any children processes. On newer kernels (CentOS/RHEL 6/7 & Ubuntu 15/16, etc) this check measures memory correctly (unlike **ps** which counts the shared memory as part of each child process as well as the parent). 
* VSZ - Virtual Set Size. This represents how much memory is currently available to the the process. This data is gathered by reading the file under /proc/ and by default includes the memory used by any children processes. This amount of memory is being reserved (but not necessarily used) in RAM and Swap.  
* RSS - Resident Set Size. This represents how much memory is currently in use by the process. This amount of memory is being reserved (but not necessarily used) in RAM and Swap. When dealing with processes that have children or share memory in other ways, RSS should not be used as it incorrectly counts any shared memory once for each child in addition to the parent. Instead you should use (if possible) the **PSS** check. This data is gathered by reading the file under /proc/.
* PSS - Proportional Set Size. This is an updated and more accurate check than RSS as it (correctly) only counts shared memory once (as part of the Parent process). Unfortunetly on some older Kernels this statistic is not available - in which case this check will rerun a PSS of 0 Bytes. This data is gathered by reading the file under /proc/.
* IO - Disk IO statistics. **This check only reports on read/write operations performed by the process being monitored.** This check does not support warning/critical thresholds and will only alert if the process is not running. It reports the following seven Averages that are calculated by using temporary files (in /tmp) and reading the correct counter values under /proc/. The results are averages since the last time the check was run.
  * Average data read per second (in Bytes). The statistic includes **both** reads from disk and reads from data the Kernel kept cached in memory.
  * Average data written per second (in Bytes). The statistic includes **both** writes to disk and writes to data the Kernel decided to cache and write later. 
  * Average number of read operations per second. The statistic includes **both** reads from disk and reads from data the Kernel kept cached in memory.
  * Average number of write operations per second. The statistic includes **both** writes to disk and writes to data the Kernel decided to cache and write later. 
  * Average data read per second **from disk** (in Bytes). This statistic includes and pre-emptive reads the Kernel chooses to perform.
  * Average data written per second **to disk** (in Bytes). This statistic includes any writes that Kernel previous wrote to cache and has now decided to commit to disk.
  * Average data that was scheduled to be written to disk per second **where the write was cancelled** (in Bytes). It is normal for writes to be cancelled sometimes, but if you find this sattistic is high it may indicate an operation or coding problem with the process.
* stats - Check that process is running and gather basic statistics as performance data. By defualt this will collect and return the statistics data of the **CPU,Memory, VSZ, RSS and PSS** Checks 

### In addtition the following switches can be used to add performance data to any basic check.

-diskio,  Add disk IO information to stats check

-average_cpu,  Add average cpu (ACPU) information to stats check 


### Choosing a method of how to identify what process(es) to check.

You must specify one **and only one** of the following switches and information so that the script knows how to identify the correct process(es). 

-p|processname,  Specify a process name to be monitored. This is usually just the name of the executable. No command line argumnets are used.

-a|argument,  Specify a process with the following argument in the command line to be monitored

-P|PID,  Specify a PID file containg the PID to be monitored. **This is the best method and should always be used**.

***Note: Checks by PID file include all children (by default), but not grandchildren.*** The two other process identification methodsd may or may not include chilkdren and grandchildren - it depends on how the process.


***These options only work is you are checking via a .pid file***

-nochildren  Do not include children in the data collected. 

***These options are for the stats and ACPU checks only***

-multicpu,  Use CPU values like that of top and ps rather than true percantages

With this option the max cpu usage is 100% * number of logical cores. Without this option max cpu usage is 100% 

**The following options only work for the CPU and memory checks** 

-w|warning,  Specify a warning level for the check. The default is 60 percent or 1000000 kilobytes

-c|critical,  Specify a critical level for the check .The default is 70 percent or 2000000 kilobytes

-M|message,  Specify a message to return on failure. This is a great way to point support teams to doccumentation on how to deal with failures.

-R|startup,  The script to use to restart the process. If selected this will be added as the firest piece of text output on CRITICALs and can be easily parsed out by an event handler script.

-N|name,  Specify a differnet name for the process **Highly reccomended that you use this to avoid confusion** For example: `check_process -P /var/run/mysqld.pid -N MasterDB ...` will return the `The MasterDB process is currently OK...`
 rather than referncing the PID file and path.




