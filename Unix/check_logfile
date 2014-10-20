#!/usr/bin/perl -w
# nagios: -epn
#
# Log file regular expression based parser plugin for Nagios.
#
# Written by Aaron Bostick (abostick@mydoconline.com)
# Rewritten by Peter Mc Aulay and Tom Wuyts
# The -a feature was contributed by Ian Gibbs
# The -M and -R features were added by Noah Guttman
# Released under the terms of the GNU General Public Licence v2.0
#
# Last updated 2013-04-11 by Peter Mc Aulay <peter@zeron.be>
# Updated again 2014-03-09 by Noah Guttman  <noah.guttman@gmail.com>
#
# Thanks and acknowledgements to Ethan Galstad for Nagios and the check_log
# plugin this is modeled after.
#
# Tested on Linux, Windows, AIX and Solaris.
#
# Usage: check_log3.pl --help
#
#
# Description:
#
# This plugin will scan arbitrary text files looking for regular expression
# matches.  A temporary file is used to store the seek byte position of the
# last scan.  This file will be created automatically.
#
# The search pattern can be any RE pattern that perl's s/// syntax accepts.
# The search patterns can be read from a file, one per line; the lines will
# be combined into a regexp of the form 'line1|line2|line3|...'.
#
# A negation pattern can be specified, causing the plugin to ignore lines
# matching it.  Alternatively, the ignore patterns can be read from a file
# (one regexp per line).  This is for badly behaved applications that produce
# lots of error messages when running "normally" (certain Java apps come to
# mind).  You can use either -n or -f, but not both.  If both are specified,
# -f will take precedence.
#
# Patterns can be either case sensitive or case insensitive.  The -i option
# controls case sensitivity for both search and ignore patterns.
#
# It is also possible to just raise an alert if the log file was not written
# to since the last check (using -d or -D).  You can use these options alone
# or in combination with pattern matching.
#
# Note that a bad regexp might case an infinite loop, so set a reasonable
# plugin time-out in Nagios.
#
# Optionally the plugin can execute a block of Perl code on each matched line,
# to further affect the output (using -e or -E).  The code should be enclosed
# in curly brackets (and probably quoted).  This allows for complex parsing
# rules of log files based on their actual content.  You can use either -e or
# -E, but not both.  If you do, -E will take precedence.
#
# The code passed to the plugin via -e be executed as a Perl 'eval' block and
# the matched line passed will be to it as $_.
#
# Return code:
# - If the code returns non-zero, it is counted towards the alert threshold.
# - If the code returns 0, the line is not counted against the threshold.
#   (It's still counted as a match, but for informational purposes only.)
#
# Modify $parse_out to make the plugin save a custom string for this match
# (the default is the input line itself).
#
# Note: -e and -E are experimental features and potentially dangerous!
#
#
# Return codes:
#
# This plugin returns OK when a file is successfully scanned and no pattern
# matches are found.
#
# It returns WARNING or CRITICAL if pattern matches were found; the -w and -c
# options determine how many lines must match before an alert is raised.
#
# If an eval block is defined (via -e or -E) a line is only counted if it
# both matches the pattern and the custom code returns a non-zero result for
# that line.
#
# If the thresholds are expressed as percentages, the thresholds are taken to
# mean the percentage of lines in the input that match (match / total * 100).
# If -e is used, the percentage of matched lines that also match the parsing
# condition is taken, rather than the total number of lines in the input.
#
# By default, the plugin returns WARNING if one match was found.
#
# The plugin returns WARNING if the -d option is used, and the log file hasn't
# grown since the last run.  Likewise, if -D is used, it will return CRITICAL
# instead.  Take care that the time between service checks is less than the
# minimum amount of time your application writes to the log file when you use
# these options.
#
# If the --ok option is used, the plugin will always return OK unless an error
# occurs and will ignore any thresholds.  This can be useful if you use this
# plugin only for its log parsing functionality, not for alerting (e.g. to
# just plot a graph of values extracted from the log file).
#
# The plugin always returns CRITICAL if an error occurs, such as if a file is
# not found or in case of a permissions problem or I/O error.
#
#
# Output:
#
# The line of the last pattern matched is returned in the output along with
# the pattern count.  If custom Perl code is run on matched lines using -e,
# it may modify the output via $parse_out (for best results, do not produce
# output directly using 'print' or related functions).
#
# Use the -a option to output all matching lines instead of just the last
# matching one.  Note that Nagios will only read the first 4 KB of data that
# a plugin returns, and that the NRPE daemon even has a 1KB output limit.
#
# Use the -C option to return some lines of context before and/or after the
# match, like "grep -C".  Prefix the number with - to return extra lines only
# before the matched line, with + to return extra lines only after the matched
# line, or with nothing to return extra lines both before and after the match.
#
# Note: lines returned as context are not parsed with -e or -E, nor is any
# context preserved if you override the output by modifying $parse_out.  If
# you want to modify the output while using -C, modify @line_buffer instead.
#
# If you use -a and -C together, the plugin will output "---" between sections
# of matched lines and their context.
#
#
# Performance data:
#
# The number of matching lines is returned as performance data (key = lines).
# If -e is used, the number of matching lines is also returned (key = parsed).
# The custom eval code can change the perfdata output by modifying the value of
# the $perfdata variable, e.g. for when you want to graph the actual figures
# appearing in the log file.
#
#
# Nagios service check configuration notes:
#
# 1. The maximum check attempts value for the service should always be 1, to
#    prevent Nagios from retrying the service check (the next time the check
#    is run it will not produce the same results).  Otherwise you will not
#    receive a notification for every match.
#
# 2. The notification options for the service should always be set to not
#    notify you of recoveries for the check.  Since pattern matches in log
#    file will only be reported once, "recoveries" don't really apply.
#
# 3. You must always supply a different seek file for each service check that
#    you define - even if the checks are reading the same log file.
#    Otherwise one check will start reading where another left off, which is
#    likely not what you want (especially since the order in which they run
#    is unpredictable).
#
#
# A few simple examples:
#
# Return WARNING if errors occur in the system log, but ignore the ones from
# the NRPE agent itself:
#   check_log.pl -l /var/log/messages -s /tmp/log_messages.seek -p '[Ee]rror' -n nrpe
#
# Return WARNING if more than 10 logon failures logged since last check, or
# CRITICAL if there are more than 50:
#   check_log.pl -l /var/log/auth.log -s /tmp/auth.seek -p 'Invalid user' -w 10 -c 50
#
# Return WARNING if more than 10 errors logged or CRITICAL if the application
# stops writing to the log file altogether:
#   check_log.pl -l /var/log/heartbeat.log -s /tmp/heartbeat.seek -p ERROR -w 10 -D
#
#
# An avanced example:
#
# Return WARNING and print a custom message if there are more than 50 lines
# in a CSV formatted log file where column 7 contains a value over 4000:
#
# check_log.pl -l processing.log -s processing.seek -p ',' -w 50 -e \
# '{
#       my @fields = split(/,/);
#       if ($fields[6] > 4000) {
#	       $parse_out = "Processing time for $fields[0] exceeded: $fields[6]\n";
#	       return 1
#       }
# }'
#
# Note: in nrpe.cfg this will all have to be put on one line.  It will be more
# readable if you put the parser code in a separate file and use -E.
#
# Shameless plug: to make configuration and maintenance of this plugin easier,
# check out the plugin "check_customlog".
#
####

require 5.004;

use strict;
use lib "/usr/lib/nagios/plugins";    # Debian
use lib "/usr/lib64/nagios/plugins";  # 64 bit
use lib "/usr/local/nagios/libexec";  # Other
use utils qw($TIMEOUT %ERRORS &print_revision &support);
use Getopt::Long qw(:config no_ignore_case);

# Plugin version
my $plugin_revision = '3.5a';

# Predeclare subroutines
sub print_usage ();
sub print_version ();
sub print_help ();
sub ioerror;
sub add_to_buffer;
sub read_next;

# Initialise variables
my $restart_command = '';
my $return_message = '';
my $log_file = '';
my $seek_file = '';
my $warning = '1';
my $critical = '0';
my $diff_warn = '';
my $diff_crit = '';
my $re_pattern = '';
my $case_insensitive = '';
my $neg_re_pattern = '';
my $pattern_file = '';
my $negpatternfile = '';
my $pattern_count = 0;
my $pattern_line = '';
my $parse_pattern = '';
my $parse_file = '';
my $parse_line = '';
my $parse_count = 0;
my $parse_out = '';
my $output_all = 0;
my $total = 0;
my $stop_first_match;
my $always_ok;
my @line_buffer;
my $read_ahead = 0;
my $read_back = 0;
my $output;
my $context;
my $perfdata;
my $version;
my $help;
my $debug;

# If invoked with a path, strip the path from our name
my $prog_dir;
my $prog_name = $0;
if ($0 =~ s/^(.*?)[\/\\]([^\/\\]+)$//) {
	$prog_dir = $1;
	$prog_name = $2;
}

# Grab options from command line
GetOptions (
	"l|logfile=s"	   => \$log_file,
	"s|seekfile=s"	  => \$seek_file,
	"p|pattern=s"	   => \$re_pattern,
	"P|patternfile=s"       => \$pattern_file,
	"n|negpattern=s"	=> \$neg_re_pattern,
	"f|negpatternfile=s"    => \$negpatternfile,
	"w|warning=s"	   => \$warning,
	"c|critical=s"	  => \$critical,
	"i|case-insensitive"    => \$case_insensitive,
	"d|nodiff-warn"	 => \$diff_warn,
	"D|nodiff-crit"	 => \$diff_crit,
	"e|parse=s"	     => \$parse_pattern,
	"E|parsefile=s"	 => \$parse_file,
	"a|output-all"	  => \$output_all,
	"C|context=s"	   => \$context,
	"1|stop-first-match"    => \$stop_first_match,
	"R|restartcommand=s"		=> \$restart_command,
	"M|returnmessage=s"		=> \$return_message,
	"ok"		    => \$always_ok,
	"v|version"	     => \$version,
	"h|help"		=> \$help,
	"debug"		 => \$debug,
);

($version) && print_version ();
($help) && print_help ();

# These options are mandatory
($log_file) || usage("Log file not specified.\n");
($seek_file) || usage("Seek file not specified.\n");
($re_pattern) || usage("Regular expression not specified.\n") unless ($pattern_file || $diff_warn || $diff_crit);

# Just in case of problems, let's not hang Nagios
$SIG{'ALRM'} = sub {
	print "Plug-in error: time out after $TIMEOUT seconds\n";
	exit $ERRORS{'UNKNOWN'};
};
alarm($TIMEOUT);

# Determine line buffer characteristics
if ($context && $context =~ /\+(\d+)/) {
	$read_ahead = $1;
} elsif ($context && $context =~ /\-(\d+)/) {
	$read_back = $1 + 1;
} elsif ($context && $context =~ /(\d+)/) {
	$read_ahead = $1;
	$read_back = $1 + 1;
}

# If we have a pattern file, read it and construct a pattern of the form 'line1|line2|line3|...'
my @patterns;
if ($pattern_file) {
	open (PATFILE, $pattern_file) || ioerror("Unable to open $pattern_file: $!");
	chomp(@patterns = <PATFILE>);
	close(PATFILE);
	$re_pattern = join('|', @patterns);
	($re_pattern) || usage("Regular expression not specified.\n")
}

# If we have an ignore pattern file, read it
my @negpatterns;
if ($negpatternfile) {
	open (PATFILE, $negpatternfile) || ioerror("Unable to open $negpatternfile: $!");
	chomp(@negpatterns = <PATFILE>);
	close(PATFILE);
} else {
	@negpatterns = ($neg_re_pattern);
}

# If we have a custom code file, read it
if ($parse_file) {
	open (EVALFILE, $parse_file) || ioerror("Unable to open $parse_file: $!");
	while (<EVALFILE>) {
		$parse_pattern .= $_;
	}
	close(EVALFILE);
}

# Open log file
open (LOG_FILE, $log_file) || ioerror("Unable to open $log_file: $!");

# Try to open log seek file.  If open fails, we seek from beginning of file by default.
if (open(SEEK_FILE, $seek_file)) {
	chomp(my @seek_pos = <SEEK_FILE>);
	close(SEEK_FILE);

	# If file is empty, no need to seek...
	if ($seek_pos[0] && $seek_pos[0] != 0) {

		# Compare seek position to actual file size.  If file size is smaller,
		# then we just start from beginning i.e. the log was rotated.
		my @stat = stat(LOG_FILE);
		my $size = $stat[7];

		# If the file hasn't grown since last time and -d or -D was specified, stop here.
		if ($seek_pos[0] eq $size && $diff_crit) {
			print "$restart_command CRITICAL: Log file not written to since last check $return_message\n";
			exit $ERRORS{'CRITICAL'};
		} elsif ($seek_pos[0] eq $size && $diff_warn) {
			print "$restart_command WARNING: Log file not written to since last check\n";
			exit $ERRORS{'WARNING'};
		}

		# Seek to where we stopped reading before
		if ($seek_pos[0] <= $size) {
			seek(LOG_FILE, $seek_pos[0], 0);
		}
	}
}

# Loop through every line of log file and check for pattern matches.
# Count the number of pattern matches and remember the full line of
# the most recent match.
while (<LOG_FILE>) {
	my $line = $_;
	my $negmatch = 0;

	# Count total number of lines
	$total++;

	# Add current line to buffer, if required
	add_to_buffer($line, $read_back) if $read_back;

	# Try if the line matches the pattern
	if (/$re_pattern/i) {
		# If not case insensitive, skip if not an exact match
		unless ($case_insensitive) {
			next unless /$re_pattern/;
		}

		# And if it also matches the ignore list
		foreach (@negpatterns) {
			next if ($_ eq '');
			if ($line =~ /$_/i) {
				# As case sensitive as the first match
				unless ($case_insensitive) {
					next unless $line =~ /$_/;
				}
				$negmatch = 1;
				last;
			}
		}

		# OK, line matched!
		if ($negmatch == 0) {
			# Increment final count
			$pattern_count += 1;

			# Save the line matched and optionally some lines of context before and/or after
			if ($output_all) {
				$pattern_line .= join('', @line_buffer) if $read_back;
				$pattern_line .= "($pattern_count) $line" if not $read_back;
				$pattern_line .= read_next(*LOG_FILE, $read_ahead) if $read_ahead;
				$pattern_line .= "---\n" if $context;
			} else {
				$pattern_line = join('', @line_buffer) if $read_back;
				$pattern_line = $line if not $read_back;
				$pattern_line .= read_next(*LOG_FILE, $read_ahead) if $read_ahead;
			}

			# Optionally execute custom code
			if ($parse_pattern) {
				my $res = eval $parse_pattern;
				warn $@ if $@;
				# Save the result if non-zero
				if ($res > 0) {
					$parse_count += 1;
					# If the eval block set $parse_out, save that instead
					# Note: in this case we don't save any context
					if ($parse_out && $parse_out ne "") {
						if ($output_all) {
							$parse_line .= "($parse_count) $parse_out";
						} else {
							$parse_line = $parse_out;
						}
					# Otherwise save the current line as before
					} else {
						if ($output_all) {
							$parse_line .= join('', @line_buffer) if $read_back;
							$parse_line .= "($parse_count) $line" if not $read_back;
							$parse_line .= read_next(*LOG_FILE, $read_ahead) if $read_ahead;
							$parse_line .= "---\n" if $context;
						} else {
							$parse_line = join('', @line_buffer) if $read_back;
							$parse_line = $line if not $read_back;
							$parse_line .= read_next(*LOG_FILE, $read_ahead) if $read_ahead;
						}
					}
				}
			}
		}
		# Stop here?
		last if $stop_first_match;
	}
}

# Overwrite log seek file and print the byte position we have seeked to.
open(SEEK_FILE, "> $seek_file") || ioerror("Unable to open $seek_file: $!");
print SEEK_FILE tell(LOG_FILE);

# Close files
close(SEEK_FILE);
close(LOG_FILE);

#
# Compute exit code, terminate if no thresholds were exceeded
#
my $endresult = $ERRORS{'UNKNOWN'};

print "DEBUG: found matches $pattern_count total $total parsed $parse_count, limits: warn $warning crit $critical\n" if $debug;

# Thresholds may be expressed as percentages
my ($warnpct, $critpct);
if ($warning =~ /%/) {
	if ($parse_pattern) {
		# Ratio of parsed lines to matched lines
		$warnpct = ($parse_count / $pattern_count) * 100 if $pattern_count;
	} else {
		# Ratio of matched lines to total lines
		$warnpct = ($pattern_count / $total) * 100 if $total;
	}
	$warning =~ s/%//g;
}

if ($critical =~ /%/) {
	if ($parse_pattern) {
		# Ratio of parsed lines to matched lines
		$critpct = ($parse_count / $pattern_count) * 100 if $pattern_count;
	} else {
		# Ratio of matched lines to total lines
		$critpct = ($pattern_count / $total) * 100 if $total;
	}
	$critical =~ s/%//g;
}

print "DEBUG: warnpct = $warnpct, critpct = $critpct\n" if $debug;

#
# Count parse matches if applicable, or else just count the matches.
#

# Warning?
if ($warnpct) {
	if ($warnpct >= $warning) {
		$endresult = $ERRORS{'WARNING'};
		print "DEBUG: warnpct >= warning\n" if $debug;
	}
} elsif ($parse_pattern) {
	if ($parse_count >= $warning) {
		$endresult = $ERRORS{'WARNING'};
		print "DEBUG: parse_count >= warning\n" if $debug;
	}
} elsif ($pattern_count >= $warning) {
		$endresult = $ERRORS{'WARNING'};
		print "DEBUG: pattern_count >= warning\n" if $debug;
} else {
	$endresult = $ERRORS{'OK'};
}

# Critical?
if ($critical > 0) {
	if ($critpct) {
		if ($critpct >= $critical) {
			$endresult = $ERRORS{'CRITICAL'};
			print "DEBUG: critpct >= critical\n" if $debug;
		}
	} elsif ($parse_pattern) {
		if ($parse_count >= $critical) {
			print "DEBUG: parse_count >= critical\n" if $debug;
			$endresult = $ERRORS{'CRITICAL'};
		}
	} elsif ($pattern_count >= $critical) {
		print "DEBUG: pattern_count >= critical\n" if $debug;
		$endresult = $ERRORS{'CRITICAL'};
	}
}


# If matches were found, print the last line matched, or all lines if -a was
# specified.  Note that there is a limit to how much data can be returned to
# Nagios: 4 KB if run locally, 1 KB if run via NRPE.
# If -e was used, print the last line parsed with a non-zero result
# (possibly something else if the code modified $parse_out).
if ($parse_pattern) {
	$output = "Parsed output ($parse_count matched): $parse_line";
	$perfdata = "lines=$pattern_count parsed=$parse_count" unless $perfdata;
} else {
	$output = $pattern_line;
	$perfdata = "lines=$pattern_count";
}

# Filter any pipes from the output, as that is the Nagios output/perfdata separator
$output =~ s/\|/\!/g;

# Prepare output, or terminate if nothing to do
if ($endresult == $ERRORS{'CRITICAL'}) {
	print "$restart_command CRITICAL: " unless $always_ok;
} elsif ($endresult == $ERRORS{'WARNING'}) {
	print "$restart_command WARNING: " unless $always_ok;
} else {
	print "$restart_command OK - No matches found.|$perfdata\n";
	exit $ERRORS{'OK'};
}

# Print output and exit
$warning .= "%" if $warnpct;
$critical .= "%" if $critpct;
chomp($output);
print "Found $pattern_count lines (limit=$warning/$critical): ";
print "\n" if $context;
if (($endresult == $ERRORS{'CRITICAL'}) && (!$always_ok)){
	print "$output $return_message|$perfdata";
}else{
	print "$output|$perfdata";
}
exit $ERRORS{'OK'} if $always_ok;
exit $endresult;


#
# Main programme ends
#
###

#
# Subroutines
#

# Die with error message and Nagios error code, for system errors
sub ioerror() {
	print @_;
	print "\n";
	exit $ERRORS{'CRITICAL'};
}

# Die with usage info, for improper invocation
sub usage {
	my $format=shift;
	printf($format,@_);
	print "\n";
	print_usage();
	exit $ERRORS{'UNKNOWN'};
}

# Print version number
sub print_version () {
	print "$prog_name version $plugin_revision\n";
	exit $ERRORS{'OK'};
}

# Add a line to the read-back buffer, a FIFO queue with max length $c
sub add_to_buffer {
	my ($l, $c) = @_;
	push(@line_buffer, $l);
	shift(@line_buffer) if @line_buffer > $c;
}

# Get next $n lines from current file position of file $fh
# The current seek position is preserved
sub read_next {
	my ($fh, $n) = @_;
	my $lines;
	my $i = 1;

	# Save current position
	my $oldpos = tell($fh);

	# Read next $i lines
	while (<$fh>) {
		last if not $_;
		last if $i > $n;
		$lines .= $_;
		$i++;
	}

	# Restore seek position and return
	seek ($fh, $oldpos, 0);
	return $lines;
}

# Short usage info
sub print_usage () {
    print "Usage: $prog_name [ -h | --help ]\n";
    print "Usage: $prog_name [ -v | --version ]\n";
    print "Usage: $prog_name -l log_file -s seek_file -p pattern | -P patternfile
	[ -n negpattern | -f negpatternfile ]
	[ -e '{ eval block}' | -E filename ]
	[ -R '{ process startup name}']
	[ -M '{ message to return on critical}']
	[ --ok ] | ( [ -w warn_count ] [ -c crit_count ] )
	[ -i ]  [-d | -D ] [ -1 ] [ --context=[-|+]nn ]
\n";
}

# Long usage info
sub print_help () {
	print "$prog_name version $plugin_revision\n";
	print "\n";
	print_usage();
	print "\n";
	print "This plugin scans arbitrary log files for regular expression matches.\n";
	print "\n";
	print "-l, --logfile=<logfile>\n";
	print "    The log file to be scanned.\n";
	print "-s, --seekfile=<seekfile>\n";
	print "    The temporary file to store the seek position of the last scan.\n";
	print "-p, --pattern=<pattern>\n";
	print "    The regular expression to scan for in the log file.\n";
	print "-i, --case-insensitive\n";
	print "    Do a case insensitive scan.\n";
	print "-P, --patternfile=<filename>\n";
	print "    File containing regular expressions, one per line, which will be combined\n";
	print "    into an expression of the form 'line1|line2|line3|...'.\n";
	print "-n, --negpattern=<negpattern>\n";
	print "    The regular expression to skip in the log file.\n";
	print "-f, --negpatternfile=<negpatternfile>\n";
	print "    Specifies a file with regular expressions which all will be skipped.\n";
	print "-w, --warning=<number>\n";
	print "    Return WARNING if at least this many matches found.  The default is 1.\n";
	print "-c, --critical=<number>\n";
	print "    Return CRITICAL if at least this many matches found.  The default is 0,\n";
	print "    i.e. don't return critical alerts unless specified explicitly.\n";
	print "-d, --nodiff-warn\n";
	print "    Return WARNING if the log file was not written to since the last scan.\n";
	print "-D, --nodiff-crit\n";
	print "    Return CRITICAL if the log was not written to since the last scan.\n";
	print "-1, --stop-first-match\n";
	print "    Stop at the first line matched, instead of the last one.\n";
	print "--context=[-|+]<number>\n";
	print "    Output <number> lines of context before or after matched line; use -N for\n";
	print "    N lines before the match, +N for N lines after the match (if possible) or\n";
	print "    an unqualified number to get N lines before and after the match.\n";
	print "-R, --restartcommand=<startup command>\n";
	print "    The startup script name under /etc/rc.d/init.d/ needed to restart the\n";
	print "    process that is writing to this log file.\n";
	print "-M, --returnmessage=<message>\n";
	print "    A message to append to the end of the check output on a critical result.\n";
	print "    This can be used to provide intructions on what to do when this check fails\n";
	print "--ok\n";
	print "    Always return an OK status to Nagios.\n";
	print "-e, --parse\n";
	print "-E, --parse-file\n";
	print "    Perl 'eval' block to parse each matched line with (EXPERIMENTAL).  The code\n";
	print "    should be in curly brackets and quoted.  If the return code of the block is\n";
	print "    non-zero, the line is counted against the threshold; otherwise it isn't.\n";
	print "\n";
	# Support information
	print "Send email to pmcaulay\@evilgeek.net if you have questions regarding use of this\n";
	print "software, or to submit patches or suggest improvements.  Please include version\n";
	print "information with all correspondence (when possible, use output from the --version\n";
	print "option of the plugin itself).\n";
	print "\n";
	print "This Nagios plugin comes with ABSOLUTELY NO WARRANTY. You may redistribute\n";
	print "copies of the plugins under the terms of the GNU General Public License.\n";
	print "For more information about these matters, see the file named COPYING.\n";
	print "\n";
	exit $ERRORS{'OK'};
}


