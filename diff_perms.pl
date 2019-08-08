#!/usr/bin/perl
# *******************************************************************************
# Script: diff_perms.pl
# 
# Description:  Permissions check for any filesystem. Compares permissions between runs and emails any changes found
# 
# Parameters:
#     First argument is filesystem to check
# 
# Outputs:    Email of permissions changes found
# 
# Assumes:    Scheduled as crontab job.
# 
# Example:    
# ./diff_perms.pl "/tmp/"
# 
# 
# Tested Against:    Specify component versions tested against this script.
#                     OS version:         RHEL 7.6
# 
# Version:   1.0
# Date:     November 20, 2017
# Author:     Joshua Woleben
# *******************************************************************************

my $directory = $ARGV[0];
chomp ($directory);

my $status_file = $directory;
$status_file =~s/\//_/g;

print "Status file: /tmp/$status_file\n";

my $first_time = 0;
my @last_perms;
my $line;
my %last_stat;
my @current_perms;
my %curret_stat;
my $email_list="person\@example.com";
my @diff;

print "Checking for first use...\n";
# Check for current file
if (-e "/tmp/$status_file") {
        open LAST_STAT,"/tmp/$status_file";
        @last_perms = <LAST_STAT>;
        close LAST_STAT;

        # Load file array into hash
        foreach $line (@last_perms) {
                if ($line=~m#(.*),(.*),(.*),(.*)#) {
                        $last_stat{$1}=$2.",".$3.",".$4;
                }
        }
}
else {
        $first_time = 1;
}

print "Getting current permissions...\n";
# Get current permissions
@current_perms = `find -L $directory -type d -exec stat -c "%n,%U,%G,%a" {} \\;`;


# Load current permissions into hash
foreach $line (@current_perms) {
        if ($line=~m#(.*),(.*),(.*),(.*)#) {
                $current_stat{$1}=$2.",".$3.",".$4;
        }
}

if ($first_time == 1) {
        print "Writing file...\n";
        open STAT,">/tmp/$status_file";
        print STAT @current_perms;
        print "Writing perms to file for first use...\n";
        close STAT;
        exit(0);
}
open EMAIL,">/tmp/usermail.log";
# Compare permissions
print "Comparing permissions...\n";
while (($file, $perms) = each(%current_stat)) {
        if ($current_stat{$file} ne $last_stat{$file}) {
                print EMAIL "$file has changed permissions.\n";
                print EMAIL "Original permissions: ".$last_stat{$file}."\n";
                print EMAIL "Current permissions: ".$current_stat{$file}."\n";
        }
}
close EMAIL;

open FINAL,">/tmp/$status_file";
print FINAL @current_perms;
close FINAL;

if (!-z "/tmp/usermail.log") {
        print `cat /tmp/usermail.log | mailx -s "File permissions changes" "$email_list"`;
}

print `rm /tmp/usermail.log`;
