#!/usr/bin/perl -w

#--------------------------------------------------------------------------
# COPYRIGHT Ericsson 2014
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
#--------------------------------------------------------------------------

=head1 NAME

ombs_backup.pl - Monitors availability of OMBS Backup on an Eniq Events and Eniq Stats system.

=head1 SYNOPSIS

 Use:

   ombs_backup.pl [-help]
   ombs_backup.pl [-man]
   ombs_backup.pl -filename filename

 Examples:

   ombs_backup.pl -help

   ombs_backup.pl -man

   ombs_backup.pl -filename "/eniq/local_logs/backup_logs/prep_eniq_backup.log"

=head1 DESCRIPTION

   The script collects the metrics regarding availability of ombs backup.
   It checks for the successful creation of backup in the respective logs to depict the availability.
   It also calculates time since last successfull backup.


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
use Time::HiRes qw/gettimeofday/;
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
    \s*(\d{2})\.(\d{2})\.(\d{2})_(\d{2}):(\d{2}):(\d{2})\s+-\s*(.*)
    \z
}xms;

   # General Metric variables

   #Backup Metrics
   our %ombsbackup_metrics = (
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
   if (($mday, $month, $yr, $hr, $min, $sec, $msg) = ($line =~ $cmd_output_re)) {
        if ($line =~ "ENIQ Server successfully prepared for Backup") {
           $month --;
           $ombsbackup_metrics{"Availability"} = 1.0;
           $backup_time = timelocal($sec, $min, $hr, $mday, $month, $yr);
           $ombsbackup_metrics{"time_since_last_backup"} = $current_time - $backup_time;
           last; 
        }
   }
}
}

#################################################################
# Main
#################################################################

ProcessCmdLineArgs();

InitLog();

EvalBackupMetrics();

if ($ombsbackup_metrics{"Availability"} < 1.0) {
   LogError("Unable to find the metrics.", "Terminating the process with exit status 2.");
   EndLog();
   exit 2;
}

foreach (keys %ombsbackup_metrics)
{
   LogInfo("backup metric \"$_\" has value \"$ombsbackup_metrics{$_}\".");
   printf "$_=%.3f\n", $ombsbackup_metrics{$_};
}

EndLog();
exit 0;
