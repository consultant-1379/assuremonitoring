#!/usr/bin/perl -w

=head1 NAME

rollingsnapshot.pl - Monitors availability of Rolling snapshot on an Eniq Events and Eniq Stats system.

=head1 SYNOPSIS

 Use:

   rollingsnapshot.pl [-help]
   rollingsnapshot.pl [-man]
   rollingsnapshot.pl -filename filename

 Examples:

   rollingsnapshot.pl -help

   rollingsnapshot.pl -man

   rollingsnapshot.pl -filename "/eniq/local_logs/rolling_snapshot_logs/prep_roll_snap.log"

=head1 DESCRIPTION

   The script collects the metrics regarding availability of rolling snapshot.
   It checks for the successful creation of snapshot and backup in the respective logs to depict the availability.
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

our $EniqConfDir = "/eniq/installation/config";
our $CurrServerType = "$EniqConfDir/installed_server_type";
our @CoServerType = qw(eniq_coordinator eniq_events stats_coordinator);
our $SunOSIniFile = "/eniq/installation/config/SunOS.ini";
our $StorageTypeFile = "/eniq/installation/config/san_details";
our $StorageType = "";

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
   our %rollingsnapshot_metrics = (
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
# Subroutine  : GetServerType
# Description : Subroutine determines the server type.
# Arguments   : N/A
# Returns     : $installServerType
#================================================================
sub GetServerType
{
   if (-f $CurrServerType){
      open(FILE, "$CurrServerType") or die("ERROR: Unable to open file $CurrServerType : $!");
         my $line = <FILE>;
         chomp $line;
         my $installServerType = $line;
      close(FILE);
      return $installServerType;
   }
   else{
      LogError("$CurrServerType files is not available.");
      exit 2;
   }
}

#================================================================
# Subroutine  : GetStorageType
# Description : Subroutine determines the storage type.
# Arguments   : N/A
# Returns     : $StorageType
#================================================================
sub GetStorageType
{
   my $StorageType = "";
   my $StorageFile = "";
   my @lines;
   my $line;
   if (-f $SunOSIniFile){
      $StorageFile = $SunOSIniFile;
   }
   elsif (-f $StorageTypeFile){
      $StorageFile = $StorageTypeFile;
   }
   else{
      LogError("$SunOSIniFile and $StorageTypeFile files are not available.");
      exit 2;
   }
   
   if (-s $StorageFile) {
      open(FILE, "$StorageFile") or die("ERROR: Unable to open file $StorageFile : $!");
      @lines = <FILE>;
      foreach $line (@lines) {
         chomp $line;
         if ($line =~ m/STORAGE_TYPE=(.*)$/) {
            $StorageType = $1;
            close(FILE);
            return $StorageType;
         }
      }
   }

   if (! $StorageType){
      LogError("Could not read STORAGE_TYPE param");
      exit 2;
   }
}
#================================================================
# Subroutine  : SANAndNASAvailablity
# Description : Check the Availability of NAS and SAN Snapshot
# Arguments   : N/A
# Returns     : $check_san_snapshot, $check_nas_snapshot
#================================================================
sub SANAndNASAvailablity
{
   system("/eniq/bkup_sw/bin/manage_san_snapshots.bsh -a list -f ALL >> /dev/null 2>&1");
   my $check_san_snapshot = $? >> 8;
   system("/eniq/bkup_sw/bin/manage_nas_snapshots.bsh -a list -f ALL >> /dev/null 2>&1");
   my $check_nas_snapshot = $? >> 8;
   return ($check_san_snapshot, $check_nas_snapshot);
}
#================================================================
# Subroutine  : EvalBackupMetrics
# Description : Calculate the Availability and seconds since last
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
   my $CheckStorageType = "";
   my ($mday, $month, $yr, $hr, $min, $sec, $msg);
   my $num = 1;
   my $installServer = GetServerType();
   system("/eniq/bkup_sw/bin/manage_zfs_snapshots.bsh -a list -f ALL >> /dev/null 2>&1");
   my $zfs_snapshot = $? >> 8;
   my $nas_snapshot = 0;
   my $san_snapshot = 0;

   if (grep {$_ eq $installServer} @CoServerType){
      ($nas_snapshot, $san_snapshot) = SANAndNASAvailablity();
   }
   elsif ($installServer eq "eniq_stats"){
      $CheckStorageType = GetStorageType();
      if ($CheckStorageType eq "raw"){
         ($nas_snapshot, $san_snapshot) = SANAndNASAvailablity();
      }
   }

   if (($nas_snapshot == 0) && ($zfs_snapshot == 0) && ($san_snapshot == 0))
   {
      open(FILE, "<$opt_filename") or die ("Can't open file file_to_reverse: $!");

      @lines = reverse <FILE>;
      foreach $line (@lines) {
         if ($num && (($mday, $month, $yr, $hr, $min, $sec, $msg) = ($line =~ $cmd_output_re))) {
            if ($line =~ "successfully created") {
               $month --;
               $rollingsnapshot_metrics{"Availability"} = 1.0;
               $backup_time = timelocal($sec, $min, $hr, $mday, $month, $yr);
               $rollingsnapshot_metrics{"time_since_last_backup"} = $current_time - $backup_time;
               $num--;
            }
         }
      }
      close(FILE);
    }
}

#################################################################
# Main
#################################################################

ProcessCmdLineArgs();

InitLog();

EvalBackupMetrics();

if ($rollingsnapshot_metrics{"Availability"} < 1.0) {
   LogError("Unable to find the metrics.", "Terminating the process with exit status 2.");
   EndLog();
   exit 2;
}

foreach (keys %rollingsnapshot_metrics)
{
   LogInfo("backup metric \"$_\" has value \"$rollingsnapshot_metrics{$_}\".");
   printf "$_=%.3f\n", $rollingsnapshot_metrics{$_};
}

EndLog();
exit 0;

