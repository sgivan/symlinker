#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  symlinker.pl
#
#        USAGE:  ./symlinker.pl  
#
#  DESCRIPTION:  Script to create a directory structure of symlinks to another directory structure.
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr. Scott A. Givan (sag), givans@missouri.edu
#      COMPANY:  University of Missoure, USA
#      VERSION:  1.0
#      CREATED:  01/21/2015 09:33:45 AM
#     REVISION:  ---
#===============================================================================

use 5.010;      # Require at least Perl version 5.10
use autodie;
use Getopt::Long; # use GetOptions function to for CL args
use warnings;
use strict;
use File::chdir;
use Cwd qw/ abs_path /;

my ($debug,$verbose,$help,$infile,$root_path,$remove_last);
my $obt = 1;# organize by type
my $pwd = abs_path();

my $result = GetOptions(
    "infile:s"      =>  \$infile,
    "root:s"        =>  \$root_path,
    "obt"           =>  \$obt,
    "removelast"    =>  \$remove_last,
    "debug"         =>  \$debug,
    "verbose"       =>  \$verbose,
    "help"          =>  \$help,
);

help() if (!$infile);

say "wd: '$pwd'" if ($debug);
open(my $infh,"<",$infile);

my $tally = 0;
my $max_tally = 100000;
my $max_dups = 10;
while (<$infh>) {
    ++$tally;

    chomp(my $filename = $_);
    say "file: '$filename'" if ($debug);
    my $first_suffix = (0);

    if ($obt) {

        if ($remove_last) {
            # if file has two suffixes, remove the last one
            if ($filename =~ /(\/.+\/.+\..+)\.(.+)$/) {
                $filename = $1;
                $first_suffix = $2;
            }
        }


        if ($filename =~ /\/.+\/(.+\.(.+?))$/) {
            say "will symlink '$filename'" if ($debug);
            my $suffix = $2;
            my $symlink_name = $1;
            $symlink_name .= ".$first_suffix" if ($first_suffix);
            say "suffix: '$suffix'" if ($debug);
            say "symlink name: '$symlink_name'" if ($debug);
            if (!-d $suffix) {
                mkdir($suffix);
            }
            $CWD = $suffix;# from File::chdir

            my $dup = 0;
            while (-e $symlink_name) {
                ++$dup;
                my ($pre,$post,$post2) = split /\./, $symlink_name;
                $pre .= "_dup${dup}";
                $symlink_name = $pre . "." . $post;
                $symlink_name .= ".$post2" if ($post2);
                if ($dup >= $max_dups) {
                    say "max dups >= $max_dups for file '$symlink_name'";
                    exit(1);
                }
            }
            $filename .= ".$first_suffix" if ($first_suffix);
            
            if (!symlink($root_path ."/" . $filename,$symlink_name)) {
                die "can't create a symlink to '${root_path}/${filename}': $!";
            }
            
            $CWD = $pwd;
        }
    }

    last if ($debug && $tally >= $max_tally);
}

close($infh);

if ($help) {
    help();
    say "exiting now";
    exit(0);
}

sub help {

say <<HELP;

    "infile:s"      you must provide an infile
    "root:s"        root path of input files
    "obt"           organize by file type as determined by file suffix
    "removelast"    if files have more than one suffix, remove the last one
    "debug"     
    "verbose"   
    "help"      

HELP
exit(0);
}

