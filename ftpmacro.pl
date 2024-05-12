#!/usr/bin/env perl

use strict;
use Net::FTP;

my $macrofile = $ARGV[0];

if (! $macrofile)
{
   die "Provide path to microfile.\n";
}

if (! -e $macrofile)
{
   die "Macrofile: $macrofile does not exist.\n";
}

if (! -r $macrofile)
{
   die "Macrofile: $macrofile is not readable.\n";
}

my %contents;

# Defaults.  Which may be clobbered by macrofile.
$contents{username} = 'anonymous';
$contents{password} = 'anonymous';
$contents{hostname} = 'localhost';
$contents{debug}    = 0;
$contents{passive}  = 0;

open MACROFILE, $macrofile or die "Can't open $macrofile!\n";

while (my $line = <MACROFILE>)
{
   chomp $line;
   if ($line =~ /(\w+)\s?:\s?(.*)/)
   {
      $contents{$1} = $2;
   }
}

close MACROFILE or die "Can't close $macrofile!\n";;

my $ftp = Net::FTP->new($contents{hostname}, Debug => $contents{debug}, Passive => $contents{passive})
  or die "Cannot connect to ftp server: " . $contents{hostname} . "$@";
 
$ftp->login($contents{username}, $contents{password})
  or die "Cannot login ", $ftp->message;

foreach my $key (sort grep { /^cmd\d+/ } keys %contents)
{
   my ($cmd1, $cmd2) = split/\s/, $contents{$key};

   if ($cmd1 eq 'dir' || $cmd1 eq 'ls')
   {
      my @results = $ftp->$cmd1($cmd2)
         or die "Error running command: $cmd1 $cmd2 ", $ftp->message();

      printf("%s: %s %s output: \n%s\n", $key, $cmd1, $cmd2, join ",\n", @results);
   }
   else
   {
      $ftp->$cmd1($cmd2)
         or die "Error running command: $cmd1 $cmd2 ", $ftp->message();
   }
}
 
$ftp->quit();
