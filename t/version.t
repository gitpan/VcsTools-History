# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..11\n"; }
END {print "not ok 1\n" unless $loaded;}
use ExtUtils::testlib;
use VcsTools::Version;
use Puppet::Storage ;
use Fcntl ;
use MLDBM qw(DB_File);
require Tk::ErrorDialog; 
$loaded = 1;
my $idx = 1;
print "ok ",$idx++,"\n";
my $trace = shift || 0;
$VcsTools::Version::test = $trace ;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# must have method getVersionObj and printDebug

use strict;

my %versions;

sub getVersionObj
  {
    my $rev = shift ;
    return $versions{$rev} ;
  }

sub addNewVersion
  {
    my $v = shift ;
    my $u = shift ;
    my $m = shift ;

    my $name = 'v'.$v ;
    $versions{$v} = new VcsTools::Version 
        (
         name => $name,
         getBrotherSub => \&getVersionObj,
         storage => new Puppet::Storage(name => $name) ,
         revision => $v
        ) ;

    my $log = {'log' => 'dummy add', author => 'bibi'};
    $log->{mergedFrom} = $m if defined $m ;
    $versions{$v} -> update
      (
       info => $log,
       upper => $u 
      )
  }



my $file = 'test.db';
unlink($file) if -r $file ;

my %dbhash;
tie %dbhash,  'MLDBM',    $file , O_CREAT|O_RDWR, 0640 or die $! ;

Puppet::Storage->dbHash(\%dbhash);
Puppet::Storage->keyRoot('key root');

foreach my $root (qw/1. 1.1.1. 1.2.1. 1.4.1. 1.1.1.2.1. 2./)
  {
    foreach my $i (1 .. 5 )
      {
        my $v = $root.$i ;
        # warn "making version $v\n";
        my $name = 'v'.$v ;
        $versions{$v} = 
          new VcsTools::Version 
            (
             name => $name,
             getBrotherSub => \&getVersionObj,
             storage => new Puppet::Storage(name => $name) ,
             revision => $v) ;
          }
  }

# store info after all version objects are known by getVersionObj
foreach my $v (keys %versions)
  {
    my %local = ( author => 'bibi') ;
    $local{branches} = ['1.1.1.1','1.2.1.1']     if $v eq '1.1' ;
    $local{branches} = ['1.1.1.2.1.1'] if $v eq '1.1.1.2' ;
    $local{branches} = ['1.4.1.1']     if $v eq '1.4' ;
    $local{mergedFrom} = '1.1.1.1'   if $v eq '1.3' ;
    
    $versions{$v}->update (info => \%local);
  }

print "ok ",$idx++,"\n";

# find ancestor of 1.1.1.1 1.2.1.4

my $anc = $versions{'1.1.1.1'}-> findAncestor('1.2.1.4');

print "not " unless $anc eq '1.1';
print "ok ",$idx++,"\n";

#find elder
my $old = $versions{'1.1.1.5'}-> findOldest();
print "not " unless $old eq '1.1';
print "ok ",$idx++,"\n";

my @children = $versions{'1.1'}-> findChildren();
print "not " unless scalar @children == 25;
print "ok ",$idx++,"\n";

my @children2 = $versions{'1.1.1.1'}-> findChildren();
print "not " unless scalar @children2 == 18;
print "ok ",$idx++,"\n";

addNewVersion('2.6','2.5');
my @new = $versions{'2.5'}-> findChildren();
print "@new\n" if $trace;
print "not " unless "@new" eq  '2.5 2.6';
print "ok ",$idx++,"\n";

# jump
addNewVersion('3.0','2.6');
@new = $versions{'2.5'}-> findChildren();
print "@new\n" if $trace;
print "not " unless "@new" eq  '2.5 2.6 3.0';
print "ok ",$idx++,"\n";

# branches 
addNewVersion('2.6.1.1','2.6');
@new = $versions{'2.5'}-> findChildren();
print "@new\n" if $trace;
print "not " unless "@new" eq  '2.5 2.6 2.6.1.1 3.0';
print "ok ",$idx++,"\n";

# merge 
addNewVersion('3.1','3.0','2.6.1.1');
@new = $versions{'2.5'}-> findChildren();
print "@new\n" if $trace;
print "not " unless "@new" eq  '2.5 2.6 2.6.1.1 3.0 3.1';
print "ok ",$idx++,"\n";

@new = $versions{'2.6.1.1'}-> findChildren();
print "@new\n" if $trace;
print "not " unless "@new" eq  '2.6.1.1 3.1';
print "ok ",$idx++,"\n";
