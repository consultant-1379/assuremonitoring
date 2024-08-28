#--------------------------------------------------------------------------
# COPYRIGHT Ericsson 2014
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
#--------------------------------------------------------------------------

package LogUtil;

#################################################################
# Modules
#################################################################

use strict;
use FindBin;
use lib "$FindBin::Bin";
use File::Basename;
use Data::Dumper;
use POSIX qw(strftime);
use Exporter 'import';

#################################################################
# Variables
#################################################################

# Command line variables.
use vars qw($opt_debug);

# Script performance measurement variables.
use vars qw($seconds $start_ms $end_ms);

# Log Variables
our $logdir = "/opt/assuremonitoring-plugins/log/";
our $logname = basename($0);
our $logfile = "$logdir/$logname.log";

# Export Variable
our @EXPORT = qw (
   InitLog
   EndLog
   RotateLogs
   LogMsg
   LogInfo
   LogError
   $opt_debug
);

#################################################################
# Log Utilities
#################################################################

sub InitLog {
   if ( scalar(@_) == 1 ) {
      my $file_ext = basename(shift);
      $logname = "$logname"."_"."$file_ext";
      $logfile = "$logdir/$logname";
   }

   unless (-d $logdir) {
      system("mkdir -m 775 $logdir");
   }

   RotateLogs();

   unless (-f $logfile) {
       open LOGFILE, "+>", $logfile or die $!;
       print LOGFILE strftime "%F %X :$logname started.\n\n", localtime;
       close LOGFILE;
   }
}

sub EndLog {
   open LOGFILE, ">>", $logfile or die $!;
   print LOGFILE strftime "\n%F %X :$logname ends.\n", localtime;
   close LOGFILE;
}

sub RotateLogs {
    my $no_of_logs = 10;

    for(my $y = $no_of_logs - 1; $y >= 1; $y--)
    {
        my $x = $y - 1;
        rename "$logfile.$x", "$logfile.$y" if (-f "$logfile.$x");
    }
    rename $logfile, "$logfile.0" if (-f $logfile);
}

sub LogMsg {
    my @msgs = @_;

    if (defined $opt_debug) {
       print "@msgs"."\n";
    }

    open(LOG, ">>$logfile") || die "Cannot open logfile $logfile: $!";
    print LOG "@msgs"."\n";
    close(LOG);

}

sub LogInfo {
    my ($first, @msgs) = @_;
    my @output = ();
    push @output,     "INFO: $first";
    push @output, map "      $_", @msgs;
    chomp @output;
    @output = map "$_\n", @output;
    LogMsg(@output);
}

sub LogError {
    my ($first, @msgs) = @_;
    my @output = ();
    push @output,     "ERROR: $first";
    push @output, map "      $_", @msgs;
    chomp @output;
    @output = map "$_\n", @output;
    LogMsg(@output);
}

1;