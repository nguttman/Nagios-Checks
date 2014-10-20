#!/usr/bin/perl -w


## Script written by Noah Guttman and Copyright (C) 2011 Noah Guttman. This script is released and distributed under the terms of the GNU General Public License

#Libraries to use
use lib "/usr/lib/perl5/5.8.8/";
use lib "/usr/lib/perl5/5.8.8/Getopt/";

use strict;
use Getopt::Std;

our ($opt_h);


my @output;

my $longoutput;
my $stat;
        getopts('h');

## Display Help
if ($opt_h){
        print "::UDP Queue Statistics Instructions::\n\n";
        print " -h,             Display this help information\n";
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

@output = (`sudo netstat -uldn |grep udp |awk \'{print \$4"="\$2}\'`);
chomp(@output);
$longoutput = ("Test collects data and always returns OK|");
foreach $stat (@output){
	if ($stat =~ m/^\=0/){
		$longoutput = ("$longoutput$stat;; ");
	}
}
print ("$longoutput\n");
exit 0;
