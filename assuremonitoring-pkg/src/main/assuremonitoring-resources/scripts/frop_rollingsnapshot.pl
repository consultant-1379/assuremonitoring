#!/usr/bin/perl -w

#--------------------------------------------------------------------------
# COPYRIGHT Ericsson 2017
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
#--------------------------------------------------------------------------

=head1 NAME

frop_rollingsnapshot.pl - Monitors availability of FROP Backup on an FROP Blade for Eniq Stats system.

=head1 SYNOPSIS

 Use:

   frop_rollingsnapshot.pl [-help]
   frop_rollingsnapshot.pl [-man]
   frop_rollingsnapshot.pl -filename filename

 Examples:

   frop_rollingsnapshot.pl -help

   frop_rollingsnapshot.pl -man

   frop_rollingsnapshot.pl -filename "/ericsson/frh/log/frh_backup/frh_backup.log"

=head1 DESCRIPTION

   The script collects the metrics regarding availability of FROP Rolling Snapshot.
   It checks for the successful creation of rolling snapshot in the respective logs to depict the availability.
   It also calculates time since last successful rolling snapshot on frop blade.


=over 4

=item help

   -help
   (Optional) Displays the help message.

=item man

   -man
   (Optional) Displays the complete user manual.

=item filename

   -filename filename
   (Required) The complete name of the file, including the filepath.
              The script checks for the file with name beginning with the filename to collect the metrics.

=back

=cut

#################################################################
# Modules
#################################################################

use lib "/opt/assuremonitoring-plugins/lib/perlUtils";
use strict;
use Getopt::Long;
use Pod::Usage ();
use File::Find;
use File::Basename;
use Data::Dumper;
use POSIX qw(strftime);
use Switch;
use Time::Local;
use LogUtil;

#################################################################
# Global Variables
#################################################################

# Command line variables.
use vars qw($opt_filename $opt_help $opt_man $opt_debug);

my $cmd_output_re = qr{
    \A
    #    day     month    year    hr      min      sec
    \s*\[(\d{4})-(\w+)-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})\]\s+(.*)
    \z
}xms;
our %mon2num = qw(
                    jan 01  feb 02  mar 03  apr 04  may 05  jun 06
                    jul 07  aug 08  sep 09  oct 10 nov 11 dec 12
                );
   # General Metric variables

   #Backup Metrics
   our %fropbackup_metrics = (
   "Availability" => 0.0,
   "time_since_last_backup" => 0.0
   );

#################################################################
# Subroutines
#################################################################
#================================================================
# Subroutine  : ProcessCmdLineArgs
# Description : Process the command line arguments.
# Arguments   : N/A
# Returns     : N/A
#================================================================

sub ProcessCmdLineArgs
{
   Getopt::Long::Configure("pass_through");
   GetOptions (
      "filename=s" => \$opt_filename,
      "help" => \$opt_help,
      "man" => \$opt_man,
      "debug" => \$opt_debug
   );

   if (defined $opt_man) {
      Pod::Usage::pod2usage( -exitstatus => 0, -verbose => 2);
   }

   if (defined $opt_help) {
      Pod::Usage::pod2usage( -exitstatus => 0 );
   }

      unless (defined($opt_filename)) {
      print "\nERROR: Incorrect syntax.\n";
      Pod::Usage::pod2usage( -exitstatus => 1 );
   }

   chomp($opt_filename);
}

#================================================================
# Subroutine  : EvalBackupMetrics
# Description : Calculate the Availability and time since last
#               backup values
# Arguments   : N/A
# Returns     : N/A
#================================================================

sub EvalBackupMetrics
{

my @lines;
my $line;
my $backup_time;
my $current_time = time;
my ($mday, $month, $yr, $hr, $min, $sec, $msg);

open(FILE, "<$opt_filename") or die ("Can't open file file_to_reverse: $!");

@lines = reverse <FILE>;
foreach $line (@lines) {
    if (($yr, $month, $mday, $hr, $min, $sec, $msg) = ($line =~ $cmd_output_re)) {
        if ($line =~ "End backup.") {
            my $mon = $mon2num{lc $month};
            $yr =~ /.*(\d{2})/;
            my $year = $1;
            $mon --;
            $fropbackup_metrics{"Availability"} = 1.0;
            $backup_time = timelocal($sec, $min, $hr, $mday, $mon, $year);
            $fropbackup_metrics{"time_since_last_backup"} = $current_time - $backup_time;
            last;
        }
    }
}
}

#################################################################
# Main
#################################################################

ProcessCmdLineArgs();

InitLog("$opt_filename");

EvalBackupMetrics();

if ($fropbackup_metrics{"Availability"} < 1.0) {
   LogError("Unable to find the metrics.", "Terminating the process with exit status 2.");
   EndLog();
   exit 2;
}

foreach (keys %fropbackup_metrics)
{
   LogInfo("backup metric \"$_\" has value \"$fropbackup_metrics{$_}\".");
   printf "$_=%.3f\n", $fropbackup_metrics{$_};
}

EndLog();
exit 0;