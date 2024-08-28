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

backlog.pl - Utility script for ENIQ backlog OSS-MT plugin.

=head1 SYNOPSIS

 Use:

   backlog.pl [-help]
              [-man]
              -function function
              -interface interface

 Examples:

   backlog.pl -help

   backlog.pl -man

   backlog.pl -function get_server_metrics

   backlog.pl -function get_service_metrics -interface INTF_DIM_E_SGEH_3G-eniq_events_topology

=head1 DESCRIPTION

   The script is a utility script for ENIQ backlog OSS-MT plugin.
   It calculates and returns metrics for server and service resource.

=over 4

=item help

   -help
   (Optional) Displays the help message.

=item man

   -man
   (Optional) Displays the complete user manual.


=item function

   -function function
   (Required) Utility function to be called in the script.
    Script provides get_active_interfaces, get_server_metrics,
    get_service_metrics utility functions.

=item interface

   -interface interface
   (Required) Name of the interface for which backlog and
    file processed count is to be calculated. This is required
    for function get_service_metrics.

=back

=cut

#################################################################
# Modules
#################################################################

use lib "/opt/assuremonitoring-plugins/lib/perlUtils";
use strict;
use Getopt::Long;
use Pod::Usage ();
use Switch;
use LogUtil;
use Time::Local;

#################################################################
# Globals
#################################################################

our ($function, $interface, $help, $man);

#################################################################
# Subroutines
#################################################################

#================================================================
# Subroutine  : process_cmd_agruments
# Description : Process the command line arguments.
# Arguments   : N/A
# Returns     : N/A
#================================================================

sub process_cmd_agruments {
   Getopt::Long::Configure("pass_through");

   GetOptions (
      "function=s" => \$function,
      "interface=s" => \$interface,
      "help" => \$help,
      "man" => \$man
   );

   if (defined $man) {
      Pod::Usage::pod2usage( -exitstatus => 0, -verbose => 2);
   }

   if (defined $help) {
      Pod::Usage::pod2usage( -exitstatus => 0 );
   }

   if (!defined($function)) {
      print "\nERROR: Incorrect syntax.\n\n";
      Pod::Usage::pod2usage( -exitstatus => 1, -verbose => 2 );
   }

   chomp($function);

   if ( !(($function eq "get_active_interfaces") ||
          ($function eq "get_server_metrics")    ||
          ($function eq "get_service_metrics"))) {
      print "\nERROR: Incorrect syntax.\n\n";
      Pod::Usage::pod2usage( -exitstatus => 1, -verbose => 2 );
   }

   if ($function eq "get_service_metrics") {
      if (!defined($interface)){
         print "\nERROR: Incorrect syntax.\n\n";
         Pod::Usage::pod2usage( -exitstatus => 1, -verbose => 2 );
      }
   }

   chomp($interface) if (defined $interface);
}

#================================================================
# Subroutine  : get_active_interfaces
# Description : Prints active interfaces in the system.
# Arguments   : N/A
# Returns     : N/A
#================================================================

sub get_active_interfaces {

   LogInfo("Fetching active interfaces on the system.");

   my $active_interfaces = `/usr/bin/su - dcuser /eniq/sw/installer/get_active_interfaces | grep 'INTF_'`;

   chomp($active_interfaces);
   printf "$active_interfaces";
}

#================================================================
# Subroutine  : get_server_metrics
# Description : Calculates server metrics.
# Arguments   : N/A
# Returns     : N/A
#================================================================

sub get_server_metrics {

   LogInfo("Fetching metrics for Server resource Backlog.");

   my $activeInterfaces = 0;
   my $output = `/usr/bin/su - dcuser /eniq/sw/installer/get_active_interfaces | grep 'INTF_'`;

   chomp($output);
   my @interfaces = split ("\n", $output);

   foreach $interface (@interfaces){
      my @splits = split (" ", $interface);

      if ($#splits == 1){
         $activeInterfaces++;
      }
   }

   printf "Availability=1.0\n";
   printf "activeInterfaces=$activeInterfaces\n";

}

#================================================================
# Subroutine  : get_service_metrics
# Description : Calculates service metrics.
# Arguments   : N/A
# Returns     : N/A
#================================================================

sub get_service_metrics {

   LogInfo("Fetching metrics for service resource Interface $interface.");

   our ($line, $last_log, $log_time, $backlog_found, $backlog, $file_processed);
   our ($current_time, $current_year, $current_month);
   our ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);

   $backlog_found = 0;
   $file_processed = 0;
   $current_time = time;

   ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($current_time);

   $current_year = 1900 + $year;
   $current_month = 1 + $mon;

   if ($current_month < 10 ){
      $current_month = "0$current_month";
   }

   if ($mday < 10 ){
      $mday = "0$mday";
   }

   open(FILE, "/eniq/log/sw_log/engine/engine-${current_year}_${current_month}_$mday.log") or die ("Can't open file file_to_reverse: $!");

   my @lines = reverse <FILE>;
   close(FILE);

   # Scanning for log in reverse.
   foreach $line (@lines) {

      # Identifying log with interface name.
      if ($line =~ m#$interface#) {
         if ( $line =~ /\d+\.\d+\s+(\d+)\:(\d+)\:(\d+).*created\s+(\d+)\sfiles\s*\((\d+)\s+files/ ) {
            $log_time = timelocal($3,$2,$1,$mday,$mon,$year);

            #Consider log only if it is not more than 15 minutes older else exit.
            if (($current_time - $log_time) <= 900) {
               if ($backlog_found == 0){
                  $backlog=$5;
                  $backlog_found = 1;
               }
               $file_processed = $file_processed + $4;
            } else {
               last;
            }
         }
      }
   }

   if ($backlog_found == 1) {
      LogInfo("Metrics retrieved for service resource Interface $interface.");

      printf "Availability=1.0\n";
      printf "backlog=$backlog\n";
      printf "fileProcessed=$file_processed\n";
   }else {
      LogInfo("Metrics not available for service resource Interface $interface.");

      printf "Availability=0.0\n";
      exit 2;
   }
}

#################################################################
# Main
#################################################################

process_cmd_agruments();

InitLog();

switch ($function) {
   case "get_active_interfaces" { get_active_interfaces(); }
   case "get_server_metrics"    { get_server_metrics(); }
   case "get_service_metrics"   { get_service_metrics(); }
}

EndLog();

exit 0;