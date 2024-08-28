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
use Time::HiRes qw/gettimeofday/;
use LogUtil;
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

1;
