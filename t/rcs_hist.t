# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}
use ExtUtils::testlib;
use Time::Local ;
use VcsTools::History;
use VcsTools::LogParser ;
use VcsTools::DataSpec::Rcs qw($description);
use Fcntl ;
use MLDBM qw(DB_File);
$loaded = 1;
my $idx = 1;
print "ok ",$idx++,"\n";
my $trace = shift || 0;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# ugly but OK for tests
my @history = <DATA> ;

use strict ;

my $file = 'test.db';
unlink($file) if -r $file ;

my %dbhash;
tie %dbhash,  'MLDBM',    $file , O_CREAT|O_RDWR, 0640 or die $! ;

print "ok ",$idx++,"\n";

my $ds = new VcsTools::LogParser
  (
   description => $description
  ) ;

print "ok ",$idx++,"\n";

Puppet::Storage->dbHash(\%dbhash);
Puppet::Storage->keyRoot('history root');

my $hist = new VcsTools::History 
  (
   storage => new Puppet::Storage(name => 'History test') ,
   name => 'History test',
   how => $trace ? 'print' : undef,
   dataScanner => $ds
  );

print "ok ",$idx++,"\n";

$hist -> update (history => \@history, time => timelocal(localtime) );
print "ok ",$idx++,"\n";

my @revs = $hist->sortRevisions('1.18','1.15');
print "not " unless "@revs" eq "1.15 1.18";
print "ok ",$idx++,"\n";

my $revs = $hist->listGenealogy('1.12','1.7');
print "not " unless "@$revs" eq "1.8 1.9 1.10 1.11 1.12";
print "ok ",$idx++,"\n";



my $resStr = "From History test v1.17:
- bug fix on substitute call.

From History test v1.16:
- Helmut version with quote stuff.

From History test v1.15:
- version 1.01

From History test v1.14:
- added loop.

";

my $ref = $hist->buildCumulatedInfo('1.17','1.13');
#print $ref->{log} ;
print "not " unless $ref->{log} eq $resStr;
print "ok ",$idx++,"\n";

my $gr =  $hist->guessNewRev('1.17');
print "not " unless $gr eq '1.17.1.1';
print "ok ",$idx++,"\n";



__DATA__
RCS file:        RCS/Vpp.pm,v;   Working file:    Vpp.pm
head:            1.18
locks:           ;  strict
access list:   
symbolic names:  v0_2: 1.13;  v0_1: 1.12;  v0_04: 1.11;  v0_03: 1.11;  v0_02: 1.10;  v0_01: 1.8;
comment leader:  "# "
total revisions: 18;    selected revisions: 18
description:
----------------------------
revision 1.18        
date: 99/03/12 14:50:05;  author: domi;  state: Exp;  lines added/del: 3/3
- changed copyright
----------------------------
revision 1.17        
date: 99/03/12 14:48:17;  author: domi;  state: Exp;  lines added/del: 6/5
- bug fix on substitute call.
----------------------------
revision 1.16        
date: 98/09/30 15:53:56;  author: domi;  state: Exp;  lines added/del: 624/180
- Helmut version with quote stuff.
----------------------------
revision 1.15        
date: 98/08/11 13:18:47;  author: domi;  state: Exp;  lines added/del: 5/5
- version 1.01
----------------------------
revision 1.14        
date: 98/08/11 12:03:59;  author: domi;  state: Exp;  lines added/del: 453/289
- added loop.
----------------------------
revision 1.13        
date: 98/03/17 14:48:30;  author: domi;  state: Exp;  lines added/del: 4/5
- removed "use English"
----------------------------
revision 1.12        
date: 97/12/17 12:36:46;  author: domi;  state: Exp;  lines added/del: 17/29
- bug fix: acccept action char made of reg exp meta characters
- can do several subsitute on the same file
----------------------------
revision 1.11        
date: 97/10/20 13:17:41;  author: domi;  state: Exp;  lines added/del: 4/4
- version 0.04
----------------------------
revision 1.10        
date: 97/10/03 11:29:49;  author: domi;  state: Exp;  lines added/del: 29/9
- added ignoreBackslash method
----------------------------
revision 1.9        
date: 97/09/22 15:54:27;  author: domi;  state: Exp;  lines added/del: 10/7
Now we can chain more than one elsif (thanks to Jim Searle for the test
case)
----------------------------
revision 1.8        
date: 97/02/28 15:58:17;  author: domi;  state: Exp;  lines added/del: 242/152
- added getText, getError Function.
- added stuff for "modulisation"
- subsitute does not return the text
----------------------------
revision 1.7        
date: 97/02/18 11:08:52;  author: domi;  state: Exp;  lines added/del: 3/3
- fix bug (printed \$unknown instead of $unknown)
----------------------------
revision 1.6        
date: 97/02/10 13:15:19;  author: domi;  state: Exp;  lines added/del: 4/2
- fix compile bug
----------------------------
revision 1.5        
date: 97/02/04 12:07:32;  author: domi;  state: Exp;  lines added/del: 6/5
- Still better doc
----------------------------
revision 1.4        
date: 97/02/04 11:01:25;  author: domi;  state: Exp;  lines added/del: 69/10
- better doc
----------------------------
revision 1.3        
date: 97/02/03 12:31:08;  author: domi;  state: Exp;  lines added/del: 3/3
- can use {} around variable name
- print $var instead of var, if $var is not defined
----------------------------
revision 1.2        
date: 96/11/08 09:50:06;  author: domi;  state: Exp;  lines added/del: 1/1
- first revision with $Revision$
----------------------------
revision 1.1        
date: 96/11/08 09:49:08;  author: domi;  state: Exp;  
Initial revision
=============================================================================
