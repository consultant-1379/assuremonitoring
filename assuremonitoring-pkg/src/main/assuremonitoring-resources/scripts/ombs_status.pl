#!/usr/bin/perl -w

#--------------------------------------------------------------------------
# COPYRIGHT Ericsson 2016
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
#--------------------------------------------------------------------------

=head1 NAME

ombs_status.pl .

=head1 SYNOPSIS

 Use:

   ombs_status.pl [-help]
   ombs_status.pl [-man]
   ombs_status.pl -filename filename

 Examples:

   ombs_status.pl -help

   ombs_status.pl -man


=head1 DESCRIPTION

   The script collects the metrics regarding failure of ombs backup due to db corruption.
   It checks for /eniq/admin/etc/ombs_backup_alarm file and sets Availability as 0.

=over 4

=item help

   -help
   (Optional) Displays the help message.

=item man

   -man
   (Optional) Displays the complete user manual.


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
use vars qw($opt_help $opt_man $opt_debug);

#OMBS Backup Failure metrics
our %ombs_flag_metric = (
   "Availability" => 1.0,
   "ombs availability" => 1.0,
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
}

#================================================================
# Subroutine  : EvalBackupMetrics
# Description : Calculate the Availability of failure flag file.
# Arguments   : N/A
# Returns     : N/A
#================================================================
sub EvalBackupMetrics
{
    my $ombs_flag_file = "/eniq/admin/etc/ombs_backup_alarm";
    if ( -f $ombs_flag_file ) {
        $ombs_flag_metric{"Availability"} = 0.0;
        $ombs_flag_metric{"ombs availability"} = 0.0;
    }
}

#################################################################
# Main
#################################################################

ProcessCmdLineArgs();

InitLog();

EvalBackupMetrics();

if ($ombs_flag_metric{"Availability"} < 1.0) {
   LogError("Unable to find the metrics.", "Terminating the process with exit status 2.");
   EndLog();
   exit 2;
}

foreach (keys %ombs_flag_metric)
{
   LogInfo("backup metric \"$_\" has value \"$ombs_flag_metric{$_}\".");
   printf "$_=%.3f\n", $ombs_flag_metric{$_};
}
EndLog();
exit 0;
