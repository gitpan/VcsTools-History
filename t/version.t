# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..11\n"; }
END {print "not ok 1\n" unless $loaded;}
use ExtUtils::testlib;
use VcsTools::Version;
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
package Dummy ;
use Puppet::Body ;

# must have method getVersionObj and printDebug

sub new 
  {
    my $type = shift ;
    my %args = @_ ;

    my $self = {} ;
    $self->{dbHash} = $args{dbHash} ;

    $self->{body} = new Puppet::Body(cloth => $self, @_) ;
    
    bless $self,$type ;

    #create Dummy revisions

    my @v_new=  (
                 storageArgs => 
                 {
                  keyRoot => 'dummy V', 
                  dbHash => $self->{dbHash}
                  },
                 manager => $self,
                ) ;

    foreach my $root (qw/1. 1.1.1. 1.2.1. 1.4.1. 1.1.1.2.1. 2./)
      {
        foreach my $i (1 .. 5 )
          {
            my $v = $root.$i ;
            # warn "making version $v\n";
            my $name = 'v'.$v ;
            $self->{version}{$v} = 
              new VcsTools::Version (name => $name,
                                     @v_new,revision => $v) ;
            $self->{body}->acquire(body => $self->{version}{$v}->body);
          }
      }

    # store info after all version objects are known by getVersionObj
    foreach my $v (keys %{$self->{version}})
      {
        my %local  ;
        $local{branches} = ['1.1.1.1','1.2.1.1']     if $v eq '1.1' ;
        $local{branches} = ['1.1.1.2.1.1'] if $v eq '1.1.1.2' ;
        $local{branches} = ['1.4.1.1']     if $v eq '1.4' ;
        $local{mergedFrom} = '1.1.1.1'   if $v eq '1.3' ;
        
        $self->{version}{$v}->update (info => \%local);
      }

    return $self;
  }

sub addNewVersion
  {
    my $self= shift ;
    my $v = shift ;
    my $u = shift ;
    my $m = shift ;

    my @v_new=  (
                 keyRoot => 'dummy V',
                 manager => $self,
                 dbHash => $self->{dbHash}
                ) ;
    my $name = 'v'.$v ;
    $self->{version}{$v} = new VcsTools::Version 
        (
         name => $name,
         storageArgs =>
         {
          keyRoot => 'dummy V',
          dbHash => $self->{dbHash}
         },
         manager => $self,
         revision => $v
        ) ;

    my $log = {'log' => 'dummy add'};
    $log->{mergedFrom} = $m if defined $m ;
    $self->{body}->acquire(body => $self->{version}{$v}->body);
    $self->{version}{$v} -> update
      (
       info => $log,
       upper => $u 
      )
  }

sub getVersionObj
  {
    my $self = shift ;
    my $rev = shift ;
    if (defined $self->{version}{$rev})
      {
        return $self->{version}{$rev} ;
      }

    return undef ;
  }

package main ;

use strict ;

my $file = 'test.db';
unlink($file) if -r $file ;

my %dbhash;
tie %dbhash,  'MLDBM',    $file , O_CREAT|O_RDWR, 0640 or die $! ;

my $dummy = new Dummy (dbHash => \%dbhash,
                     keyRoot => 'key root',
                     name =>"dummy history");

print "ok ",$idx++,"\n";

# find ancestor of 1.1.1.1 1.2.1.4

my $anc = $dummy->getVersionObj('1.1.1.1')-> findAncestor('1.2.1.4');

print "not " unless $anc eq '1.1';
print "ok ",$idx++,"\n";

#find elder
my $old = $dummy->getVersionObj('1.1.1.5')-> findOldest();
print "not " unless $old eq '1.1';
print "ok ",$idx++,"\n";

my @children = $dummy->getVersionObj('1.1')-> findChildren();
print "not " unless scalar @children == 25;
print "ok ",$idx++,"\n";

my @children2 = $dummy->getVersionObj('1.1.1.1')-> findChildren();
print "not " unless scalar @children2 == 18;
print "ok ",$idx++,"\n";

$dummy->addNewVersion('2.6','2.5');
my @new = $dummy->getVersionObj('2.5')-> findChildren();
print "@new\n" if $trace;
print "not " unless "@new" eq  '2.5 2.6';
print "ok ",$idx++,"\n";

# jump
$dummy->addNewVersion('3.0','2.6');
@new = $dummy->getVersionObj('2.5')-> findChildren();
print "@new\n" if $trace;
print "not " unless "@new" eq  '2.5 2.6 3.0';
print "ok ",$idx++,"\n";

# branches 
$dummy->addNewVersion('2.6.1.1','2.6');
@new = $dummy->getVersionObj('2.5')-> findChildren();
print "@new\n" if $trace;
print "not " unless "@new" eq  '2.5 2.6 2.6.1.1 3.0';
print "ok ",$idx++,"\n";

# merge 
$dummy->addNewVersion('3.1','3.0','2.6.1.1');
@new = $dummy->getVersionObj('2.5')-> findChildren();
print "@new\n" if $trace;
print "not " unless "@new" eq  '2.5 2.6 2.6.1.1 3.0 3.1';
print "ok ",$idx++,"\n";

@new = $dummy->getVersionObj('2.6.1.1')-> findChildren();
print "@new\n" if $trace;
print "not " unless "@new" eq  '2.6.1.1 3.1';
print "ok ",$idx++,"\n";
