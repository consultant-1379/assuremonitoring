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

rollingsnapshot_status.pl .

=head1 SYNOPSIS

 Use:

   .pl [-help]
   rollingsnapshot_status.pl [-man]
   rollingsnapshot_status.pl -filename filename

 Examples:

   rollingsnapshot_status.pl -help

   rollingsnapshot_status.pl -man


=head1 DESCRIPTION

   The script collects the metrics regarding failure of rolling snapshot status due to db corruption.
   It checks for /eniq/admin/etc/roll_snap_alarm file and sets Availability as 0.

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

#Rolling Snapshot failure metrics
our %rollingsnap_flag_metric = (
   "Availability" => 1.0,
   "rolling snapshot availability" => 1.0,
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
# Subroutine  : EvalRollingSnapFailureStatus
# Description : Calculate the Availability of failure flag file.
# Arguments   : N/A
# Returns     : N/A
#================================================================
sub EvalRollingSnapFailureStatus
{
    my $ombs_flag_file = "/eniq/admin/etc/roll_snap_alarm";
    if ( -f $ombs_flag_file ) {
        $rollingsnap_flag_metric{"Availability"} = 0.0;
        $rollingsnap_flag_metric{"rolling snapshot availability"} = 0.0;
    }
}

#################################################################
# Main
#################################################################

ProcessCmdLineArgs();

InitLog();

EvalRollingSnapFailureStatus();

if ($rollingsnap_flag_metric{"Availability"} < 1.0) {
   LogError("Unable to find the metrics.", "Terminating the process with exit status 2.");
   EndLog();
   exit 2;
}

foreach (keys %rollingsnap_flag_metric)
{
   LogInfo("backup metric \"$_\" has value \"$rollingsnap_flag_metric{$_}\".");
   printf "$_=%.3f\n", $rollingsnap_flag_metric{$_};
}
EndLog();
exit 0;
