# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use ExtUtils::testlib;
use Data::Dumper ;
use VcsTools::DataSpec::HpTnd qw($description readHook);
use VcsTools::LogParser ;

my $idx = 1;
print "ok ",$idx++,"\n";
$loaded = 1;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
use strict ;
use vars qw($description);
my $trace = shift || 0;

my $ds = new VcsTools::LogParser 
  (
   readHook => \&readHook,
   description => $description
  ) ;

my $info ;

print "ok ",$idx++,"\n";

$info = $ds->scanHistory([<DATA>]) ;

my $str=<<'EOF';
$VAR1 = {
          '5.0.1.1' => {
                         'state' => 'Exp',
                         'log' => 'dummy branch 1
',
                         'Author' => 'rgachet @ somewhere',
                         'writer' => 'rgachet @ somewhere',
                         'date' => '1998/03/04 17:04:22'
                       },
          '5.0.2.1' => {
                         'state' => 'Exp',
                         'log' => 'dummy branch 1
',
                         'Author' => 'rgachet @ somewhere',
                         'writer' => 'rgachet @ somewhere',
                         'date' => '1998/03/04 17:04:22'
                       },
          '5.0' => {
                     'state' => 'Exp',
                     'log' => 'bugs fixed :

 - GREhp12347   :  Prepare source module for NT
',
                     'Author' => 'rgachet @ somewhere',
                     'branches' => [
                                     '5.0.1.1',
                                     '5.0.2.1'
                                   ],
                     'fix' => [
                                'GREhp1234',
                                'GREhp2345'
                              ],
                     'keywords' => [
                                     'NT'
                                   ],
                     'writer' => 'rgachet @ somewhere',
                     'date' => '1998/03/04 17:04:22'
                   },
          '4.14' => {
                      'keywords' => [
                                      'HPSS7'
                                    ],
                      'state' => 'Exp',
                      'log' => 'toto: dummy
bugs fixed :

 - GREhp12065   :  HPSS7 stack killed when application sends a SCCP_N_COORD primitive
',
                      'Author' => 'herve',
                      'writer' => 'herve',
                      'date' => '1998/02/06 14:24:09',
                      'fix' => [
                                 'GREhp12065'
                               ],
                      'interfaceChange' => 'cosmetic'
                    }
        };
EOF

print Dumper($info),"\n\n" if $trace ;

print "not " unless Dumper($info) eq $str;
print "ok ",$idx++,"\n";

my $pile = $ds->pileLog('test',
                     [
                      [ '5.0', $info->{'5.0'}],
                      ['4.14', $info->{'4.14'}]
                     ]
                    ) ;

$str=<<'EOF';
$VAR1 = {
          'keywords' => [
                          'HPSS7',
                          'NT'
                        ],
          'log' => 'From test v4.14:
toto: dummy
bugs fixed :

 - GREhp12065   :  HPSS7 stack killed when application sends a SCCP_N_COORD primitive

From test v5.0:
bugs fixed :

 - GREhp12347   :  Prepare source module for NT

',
          'fix' => [
                     'GREhp12065',
                     'GREhp1234',
                     'GREhp2345'
                   ]
        };
EOF

print Dumper($pile),"\n\n" if $trace;
print "not " unless Dumper($pile) eq $str;
print "ok ",$idx++,"\n";

$str = <<'EOF';
writer: rgachet @ somewhere
keywords: NT
fix: GREhp1234, GREhp2345
bugs fixed :

 - GREhp12347   :  Prepare source module for NT
EOF

my $res = $ds->buildLogString($info->{'5.0'});
print $res,"\n\n" if $trace ;
print "not " unless $res eq $str ;
print "ok ",$idx++,"\n";

$str = <<'EOF';
writer: herve
keywords: HPSS7
fix: GREhp12065
interface change: cosmetic
toto: dummy
bugs fixed :

 - GREhp12065   :  HPSS7 stack killed when application sends a SCCP_N_COORD primitive
EOF

$res = $ds->buildLogString($info->{'4.14'});
print $res,"\n\n" if $trace ;
print "not " unless $res eq $str ;
print "ok ",$idx++,"\n";

__DATA__

file:  /7UP/code/tcap/FileRevList
type:  RCS
head: 5.0
symbolic names:
keyword substitution: kv
total revisions: 91;	selected revisions: 91
description:
----------------------------
revision 5.0
date: 1998/03/04 17:04:22;  author: rgachet;  state: Exp;  lines: +2 -2
Author: rgachet @ somewhere
branches: 5.0.1; 5.0.2 ;
fix: GREhp1234, GREhp2345
bugs fixed :

 - GREhp12347   :  Prepare source module for NT
----------------------------
revision 4.14
date: 1998/02/06 14:24:09;  author: herve;  state: Exp;  lines: +2 -2
Author: herve
toto: dummy
interface change: cosmetic
bugs fixed :

 - GREhp12065   :  HPSS7 stack killed when application sends a SCCP_N_COORD primitive
----------------------------
revision 5.0.1.1
date: 1998/03/04 17:04:22;  author: rgachet;  state: Exp;  lines: +2 -2
Author: rgachet @ somewhere
dummy branch 1
----------------------------
revision 5.0.2.1
date: 1998/03/04 17:04:22;  author: rgachet;  state: Exp;  lines: +2 -2
Author: rgachet @ somewhere
dummy branch 1
=================================================

