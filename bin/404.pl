#!/usr/bin/perl
use strict;
use warnings;
use LWP;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;
use MIME::Base64;

# Create a new useragent to submit information with.
my $ua = LWP::UserAgent->new(); 

# Define variables so we can use them later.
my (@files, $key, $user, $man, $help);
my $OptResult = GetOptions(
                            "help"   =>    \$help,
                            "man"    => \$man,
                            "user=s" => \$user,
                            "key=s"  => \$key,
                            "file=s@" => \@files,
                           );

# Display the help information if the user requests it, or doesn't supply
# their ISC userid and userkey along with a list of files
pod2usage( -verbose => 1 ) if ($help);
pod2usage( -verbose => 2 ) if ($man);
if (!defined($user) && !defined($key) && !defined($files[0])) {
    pod2usage( -verbose => 1 );
    exit;    
}
=head1 NAME

404Project - Used to send Apache 404 logs to SANS Internet Storm Center 

=head1 SYNOPSYIS

Usage: $0 [--help] [--man] --file apche_access.log --user ISC_ID --key ISC_User_Key
    
=head1 OPTIONS

=over 8

=item B<-h>

Print a brief help message and exit.

=item B<-f LogFile>

Point to the log file you wish to send 404 from.

=item B<-u ISCUserID>

This is your Internet Storm Center ID

=item B<-k ISCUserKey>

This is the key associated with your ISC_ID.

=back

=head1 DESCRIPTION

B<404Project.pl> will read the given input log file(s) parse them and send the
log entries with a 404 status to the SANS Internet Storm Center 404 Project

=cut

my %months = (
  'Jan' => '01',
  'Feb' => '02',
  'Mar' => '03',
  'Apr' => '04',
  'May' => '05',
  'Jun' => '06',
  'Jul' => '07',
  'Aug' => '08',
  'Sep' => '09',
  'Oct' => '10',
  'Nov' => '11',
  'Dec' => '12'
);

foreach my $file (@files) {
    open(FILE, "<$file") || die "Unable to read file: $file: $!\n";
    while(<FILE>) {
        if ($_ =~ m!^(\d+\.\d+\.\d+\.\d+) - .+ \[(..)/(...)/(....):(..:..:..) .....\] "(GET|POST) (.*) HTTP/..." 404 \d+ "[^"]+" "([^"]+)"!) {
            my $reqMon   = $months{$3};
            my $sData = $user . $key . $7 . $1 . $8 . $4 . "-" . $reqMon . "-" . $2 . $5;
            if ($sData !~ m/^$/) {
                $sData = encode_base64($sData); 
            } 
            print "Submitting: \"$4-$reqMon-$2 $5\" $1 $7\n";
            my $result = $ua->post("http://isc.sans.edu/weblogs/404project.html?id=$user&version=1",    Content => $sData);
            if($result->is_success) {
                print "URL OK\n";
            } elsif ($result->is_redirect) {
                print "REDIRECT\n";
                print Dumper($result);
            } else {
                print "Other...\n";
                print Dumper($result);
            }
        } 
    }
}
