# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}
use VcsTools::DataSpec::HpTnd qw(readHook);
my $idx = 1;
print "ok ",$idx++,"\n";
$loaded = 1;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $info = 
  {
   '1.19' =>
   {
    'log' => "First Revision for OC1.2\n"
   },
   '1.20' =>
   {
    'log' => "fixed bloody GREhp1234\n and GREhp2345\n"
   },
   '1.21' =>
   {
    'fix' => [qw/GREhp1234/],
    'log' => "fixed BLOODY GREhp1234\n but not ZZT GREhp2345\n"
   },
   '1.22' =>
   {
    'keywords' => [qw/DUMMY/],
    'log' => "fixed BLOODY GREhp1234\n but not ZZT GREhp2345\n"
   },
  };

readHook($info) ;
print "ok ",$idx++,"\n";

print "not " unless 
  join(':',@{$info->{'1.20'}{fix}}) eq "GREhp1234:GREhp2345";
print "ok ",$idx++,"\n";

print "not " if defined $info->{'1.20'}{keywords} ;
print "ok ",$idx++,"\n";

print "not " if defined $info->{'1.19'}{fix} ;
print "ok ",$idx++,"\n";


print "not " unless 
  join(':',@{$info->{'1.21'}{fix}}) eq "GREhp1234";
print "ok ",$idx++,"\n";

print "not " unless 
  join(':',@{$info->{'1.21'}{keywords}}) eq "BLOODY:ZZT";
print "ok ",$idx++,"\n";

print "not " unless 
  join(':',@{$info->{'1.22'}{fix}}) eq "GREhp1234:GREhp2345";
print "ok ",$idx++,"\n";

print "not " unless 
  join(':',@{$info->{'1.22'}{keywords}}) eq "DUMMY";
print "ok ",$idx++,"\n";
