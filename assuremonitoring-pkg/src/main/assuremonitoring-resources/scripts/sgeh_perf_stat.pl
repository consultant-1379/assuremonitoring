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

 sgeh_perf_stat.pl - Collects performance statistics for SGEH feature on ENIQ EVENTS system.

=head1 SYNOPSIS

 Use:

   sgeh_perf_stat.pl [-help]
                     [-man]
                     [-time] timestamp
                     -filename filename
                     -keyword keyword

 Examples:

   sgeh_perf_stat.pl -help

   sgeh_perf_stat.pl -man

   sgeh_perf_stat.pl -time "2014-06-06 00" -filename "/eniq/log/sw_log/mediation_gw/wfinstr/wfinstr.log" -keyword "SGEH.WF_SGEH_Processing_NFS"

   sgeh_perf_stat.pl -filename "/eniq/log/sw_log/mediation_gw/wfinstr/wfinstr.log" -keyword "SGEH.WF_SGEH_Processing_NFS"

=head1 DESCRIPTION

   The script collects the performance statistics for the feature.
   The performance statistics are collected from the file based on the timestamp and the keyword.
   If timestamp is not provided, then the last hour is taken as default.
   The script looks for all the file, including the rotated files, to collect the performance statistics.
   The script assumes that the files will have timestamp at the start of each line followed by the keyword.


=over 4

=item help

   -help
   (Optional) Displays the help message.

=item man

   -man
   (Optional) Displays the complete user manual.


=item time

   -time timestamp
   (Optional) The timestamp found in the file.
              The default time is the last hour in "YYYY-MM-DD HH".
              For example, if the current time is "Thu Jun 26 08:56:03 IST 2014",
              then the default time is "2014-06-26 07".

=item filename

   -filename filename
   (Required) The complete name of the file, including the filepath.
              The script checks for all the files with name beginning with the filename to collect the metrics.

=item keyword

   -keyword keyword
   (Required) The keyword for the feature in the file to collect the metrics.
=cut

#################################################################
# Modules
#################################################################

use lib "/opt/assuremonitoring-plugins/lib/perlUtils";
use strict;
use Getopt::Long;
use Pod::Usage ();
use Data::Dumper;
use Switch;
use LogUtil;
use MetricUtil;

#################################################################
# Globals
#################################################################

# Command line variables. Debug variable $opt_debug is exported from LogUtil.
use vars qw($opt_key $opt_filename $opt_help $opt_time $opt_man);

# Search time variables.
use vars qw($search_date $search_hour $current_date $current_hour);

# Script performance measurement variables.
use vars qw($seconds $start_ms $end_ms);

# General Metric variables
our $metric_hashref = {};
our $similarFileList = [];
our $epoc = time();

# SGEH Metrics
our %sgeh_metrics = (
   "Availability" => 0.0,
   "event_rate" => 0.0,
   "succ23_rate" => 0.0,
   "err23_rate" => 0.0,
   "succ4_rate" => 0.0,
   "err4_rate" => 0.0,
   "files" => 0.0,
   "volume" => 0.0
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

sub ProcessCmdLineArgs {
   Getopt::Long::Configure("pass_through");
   GetOptions (
      "keyword=s" => \$opt_key,
      "filename=s" => \$opt_filename,
      "time:s" => \$opt_time,
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

   unless (defined($opt_key) && defined ($opt_filename)) {
      print "\nERROR: Incorrect syntax.\n";
      Pod::Usage::pod2usage( -exitstatus => 1 );
   }

   chomp($opt_key);
   chomp($opt_filename);
   chomp($opt_time) if (defined $opt_time);
}


#================================================================
# Subroutine  : SetSgehMetrics
# Description : Calculate the SGEH metrics and sets it.
# Arguments   : Reference of the fetched record hash
#               Reference of the sgeh metric hash to store values.
# Returns     : N/A
#================================================================

sub SetSgehMetrics {
   my $record_hash = shift;
   my $sgeh_hash = shift;
   my $total_event = 0.0;

   foreach ( "Succ23", "Err23", "Succ4", "Err4" ) {
      if ( exists $record_hash->{$_} ) {

         $total_event += $record_hash->{$_};

         switch($_) {
            case "Succ23" { $sgeh_hash->{"succ23_rate"} += $record_hash->{$_} / 3600; }

            case "Err23"  { $sgeh_hash->{"err23_rate"} += $record_hash->{$_} / 3600; }

            case "Succ4"  { $sgeh_hash->{"succ4_rate"} += $record_hash->{$_} / 3600; }

            case "Err4"   { $sgeh_hash->{"err4_rate"} += $record_hash->{$_} / 3600; }
         }

      }
   }

   $sgeh_hash->{"event_rate"} += $total_event / 3600;
   $sgeh_hash->{"files"} += $record_hash->{"Files"};
   $sgeh_hash->{"volume"} = ConvertBytes($record_hash->{"Bytes"}, "gb");
}

#################################################################
# Main
#################################################################

ProcessCmdLineArgs();

InitLog();

$similarFileList = GetRotatedFileList($opt_filename);

unless ( defined $opt_time ) {
   ($search_date, $search_hour) = GetSearchDateHour();
   $opt_time = "$search_date $search_hour";
}

if (defined $opt_debug) {
  LogInfo "Debug is defined";
}

LogInfo("Searching for metrics for time $opt_time.");

foreach my $instr_file (@$similarFileList) {
   LogInfo("Processing file $instr_file.");
   $metric_hashref = GetMetrics($instr_file, $opt_time, $opt_key);
   unless ( (scalar (keys %$metric_hashref)) == 0 ) {
      LogInfo("Found the metrics in file $instr_file.", "Setting the Availability to 1.0.");
      $sgeh_metrics{"Availability"} = 1.0;
      last;
   }
}

# Exit with status 2 because
# the availability was always 100% even when we
# were throwing the output as "0.000" from script.

if ($sgeh_metrics{"Availability"} < 1.0) {
   LogError("Unable to find the metrics.", "Terminating the process with exit status 2.");
   EndLog();
   exit 2;
}

if (defined $opt_debug) {
   LogInfo(Dumper $metric_hashref);
}

SetSgehMetrics($metric_hashref, \%sgeh_metrics);

foreach (keys %sgeh_metrics) {
   LogInfo("sgeh metric \"$_\" has value \"$sgeh_metrics{$_}\".");
   printf "$_=%.3f\n", $sgeh_metrics{$_};
}

EndLog();
