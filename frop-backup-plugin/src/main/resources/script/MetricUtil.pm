#--------------------------------------------------------------------------
# COPYRIGHT Ericsson 2014
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
#--------------------------------------------------------------------------

package MetricUtil;

#################################################################
# Modules
#################################################################

use strict;
use File::Basename;
use File::Copy;
use Data::Dumper;
use POSIX qw(strftime);
use LogUtil;
use Time::Local;
use Exporter 'import';

#################################################################
# Variables
#################################################################

# Time
our $epoc = time();

# Export variables`
our @EXPORT = qw (
   GetSearchDateHour
   GetCurrentDateHour
   Description
   GetRotatedFileList
   GetMetrics
   CalculateHourlyRate
   ConvertBytes
   GetSearchDateHMS
   GetCurrentDateHMS
   GetCSLMetrics
);

#################################################################
# Metric Utilities
#################################################################

#================================================================
# Subroutine  : GetSearchDateHour
# Description : Get the previous time to search.
# Arguments   : The last nth hour. Default is 1.
# Returns     : Array
#               ( the search date in YYYY-MM-DD format ,
#                 the search hour )
#================================================================

sub GetSearchDateHour {
   my $delay = 1;
   my $prev_time = $epoc -  $delay * 60 * 60;
   my $prev_date =  strftime "%F", localtime($prev_time);
   my $prev_hour =  strftime "%H", localtime($prev_time);
   return ("$prev_date", "$prev_hour");
}

#================================================================
# Subroutine  : GetSearchDateHMS
# Description : Get the previous
# Arguments   : The delay in minutes.
# Returns     : Array
#               ( the search date in YYYY-MM-DD format ,
#                 the search time in HH:MM:SS format )
# NOTE: 1 second is added to avoid getting back the same time again.
#================================================================

sub GetSearchDateHMS {
   my $delay = 5;
   if (scalar(@_) == 1) {
      $delay = shift;
   }
   chomp($delay);
   my $prev_time = $epoc -  $delay * 60 + 1;
   my $prev_date =  strftime "%F", localtime($prev_time);
   my $prev_hh_mm_ss = strftime "%T", localtime($prev_time);
   return ("$prev_date", "$prev_hh_mm_ss");
}

#================================================================
# Subroutine  : GetCurrentDateHMS
# Description : Get the current time.
# Arguments   : N/A
# Returns     : Array
#               ( The current date in YYYY-MM-DD format,
#                 the current time in HH:MM:SS )
#================================================================

sub GetCurrentDateHMS {
   my $cur_date = strftime "%F", localtime();
   my $curr_hh_mm_ss = strftime "%T", localtime();
   return ("$cur_date", "$curr_hh_mm_ss");
}

#================================================================
# Subroutine  : GetCurrentDateHour
# Description : Get the current time.
# Arguments   : N/A
# Returns     : Array
#               ( The current date in YYYY-MM-DD format,
#                 the current hour )
#================================================================

sub GetCurrentDateHour {
   my $cur_date = strftime "%F", localtime();
   my $cur_hour = strftime "%H", localtime();
   return ("$cur_date", "$cur_hour");
}

#================================================================
# Subroutine  : GetRotatedFileList
# Description : This subroutine returns the list of all the files
#               that has been rotated.
#               This list returns a date sorted list with the
#               latest file first and the oldest at last.
# Arguments   : complete filename (along with the path).
# Returns     : Array
#               (Date sorted array with lastest at first index
#                and oldest at last)
#================================================================

sub GetRotatedFileList {
   my $filename = shift;
   my @sort_array = ();
   my @tmp_list = ();
   foreach (glob "$filename*") {
      push (@tmp_list, $_);
   }

   @sort_array = sort { -M $a <=> -M $b} @tmp_list;
   return \@sort_array;
}

#================================================================
# Subroutine  : GetMetrics
# Description : Get the metrics from the file by parsing from
#               the given data.
# Arguments   : complete filename ,
#               the timestamp expected in the file,
#               the keyword expected in the file.
# Returns     : hash of the metrics
#================================================================

sub GetMetrics {
   my $metric_file = shift;
   my $metric_time = shift;
   my $metric_key = shift;

   my $op_metrics_hash = {};
   my @base_metric_array = ();

   # Creating a temporary file for processing
   my $temp_metric_file = "/tmp/".basename($metric_file).".".$$;
   LogInfo "Creating a temporary copy of file $metric_file to $temp_metric_file";
   copy($metric_file,$temp_metric_file) or die "Copy failed: $!";

   open SOURCE, "$temp_metric_file" or die "ERROR: Unable to open file $metric_file : $!";
   foreach my $line (<SOURCE>) {
      chomp($line);
      @base_metric_array = ();
      if ( $line =~ /^$metric_time.*$metric_key/ ) {
         push (@base_metric_array, ($line =~ /(\w+=\w+)/g)) ;
      }

      foreach my $metric_pair (@base_metric_array) {
         chomp($metric_pair);
         if ( my ($metric_key, $metric_val) = $metric_pair =~ /^(\w+)\=(\d*)$/ ) {
            $op_metrics_hash->{$metric_key} += $metric_val;
         }
      }
   }
   close SOURCE;

   LogInfo "Cleaning the temporary copy $temp_metric_file .";
   unlink($temp_metric_file) or die "File removal failed: $!";

   return $op_metrics_hash;
}

#================================================================
# Subroutine  : CalculateHourlyRate
# Description : Calculates the rate per second for the passed
#               parameter.
# Arguments   : Metric in hour.
# Returns     : Rate
#================================================================

sub CalculateHourlyRate {
   my $metric = shift;
   my $hr_rate = 0.0 + $metric / 3600;
   return $hr_rate;
}

#================================================================
# Subroutine  : ConvertBytes
# Description : Convert input byte to MB / GB.
# Arguments   : Byte Value,
#               mb / gb
# Returns     : byte in mb / gb.
#================================================================

sub ConvertBytes {
   my $value = shift;
   my $convertTo = shift;

   # MB / GB => Bytes
   my %conversion = (
      "gb" => 1073741824,
      "mb" => 1048576
   );

   $value = 0.0 + ($value / $conversion{$convertTo});
   return $value;
}

#================================================================
# Subroutine  : convert_to_seconds
# Description : Convert the given time to seconds.
# Arguments   : Time in YYYY-MM-DD HH:MM:SS
# Returns     : Epoch time
#================================================================

sub convert_to_seconds {
  my $time_fmt = shift;
  chomp($time_fmt);
  my $time = "";
  if ( $time_fmt =~ /^(\d+)\-(\d+)\-(\d+)\s*(\d+)\:(\d+)\:(\d+)/ ) {
     my $month = $2;
     $month = $month - 1;
     $time = timelocal($6,$5,$4,$3,$month,$1);
  }
  return $time;
}

#================================================================
# Subroutine  : GetCSLMetrics
# Description : Get the metrics from the file by parsing from
#               the given data.
# Arguments   : complete filename ,
#               the start time stamp,
#               the end time stamp,
#               the keyword expected in the file.
# Returns     : hash of the metrics
#================================================================

sub GetCSLMetrics {

   my $metric_file = shift;
   my $metric_start_time = shift;
   my $metric_end_time = shift;
   my $metric_key = shift;

   my @base_metric_array = ();
   my $op_metrics_hash = {};

   my ($start,$end) = map convert_to_seconds($_), ($metric_start_time, $metric_end_time);

   # Creating a temporary file for processing
   my $temp_metric_file = "/tmp/".basename($metric_file).".".$$;
   LogInfo "Creating a temporary copy of file $metric_file to $temp_metric_file";
   copy($metric_file,$temp_metric_file) or die "Copy failed: $!";

   open SOURCE , "<", $temp_metric_file or die "ERROR: Unable to open file $metric_file : $!";
   foreach my $line (<SOURCE>) {
      chomp($line);
      if ($line =~ /^(\d+\-\d+\-\d+\s*\d+\:\d+\:\d+).*COUNTER/) {
         my $time_in_line_hms = $1;
         chomp($time_in_line_hms);
         my $time_in_line = convert_to_seconds($time_in_line_hms);
         chomp($time_in_line);
         if ($time_in_line >= $start && $time_in_line <= $end) {
            push (@base_metric_array, ($line =~ /(\w+=\w+)/g)) ;
            $op_metrics_hash->{"files"} += 1;
         }
      }
   }

   foreach my $metric_pair (@base_metric_array) {
       chomp($metric_pair);
       if ( my ($metric_key, $metric_val) = $metric_pair =~ /^(\w+)\=(\d*)$/ ) {
           $op_metrics_hash->{$metric_key} += $metric_val;
       }
   }
   close SOURCE;

   LogInfo "Cleaning the temporary copy $temp_metric_file .";
   unlink($temp_metric_file) or die "File removal failed: $!";

   return ($op_metrics_hash);
}

1;
