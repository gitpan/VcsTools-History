package VcsTools::DataSpec::HpTnd ;

use strict;

use vars qw(@ISA $VERSION $description @EXPORT_OK) ;
require Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = qw($description readHook);

$VERSION = sprintf "%d.%03d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/;

# $logDataFormat is a array ref which specifies all information that can
# edited or displayed on the history editor.


{
  my $bChangeData = ['none', 'cosmetic', 'minor','major'] ;
  my $changeData = ['none', 'cosmetic', 'major'] ;
  my @state = qw(Dead Exp Team Lab Special Product) ;

  # each entry is a hash made of 
  # - name : name of the field stored in log
  # - var : variable name used in internal hash (default = name), and through
  #         the VcsTools objects
  # - type : is line, enum or array or text
  # - values : possible values of enum type
  # - mode : specifies if the value must be hidden (h) from the user or if 
  #          it can be modified by the user (h|r|w) (default 'w')
  # - pile : define how to pile the data when building a log resume.
  # - help : help string
  # - vcs_mode : if 'r', the info is read from the VCS system but not
  #              written to (ex: the archival date)
  
  $description = 
    [
     { 
      'name'   => 'state', 
      'type'   => 'enum',  
      'vcs_mode' => 'r', # handled specially by HMS
      'values' => \@state
     },
     { 
      'name' => 'branches', 
      'type' => 'array', 
      'vcs_mode' => 'r',
      'mode' => 'h' 
     },
     { 
      'name' => 'Author', 
      'var' => 'author',
      'type' => 'line', 
      'vcs_mode' => 'r',
      'mode' => 'r' 
     },
     { 
      'name' => 'date', 
      'type' => 'line', 
      'vcs_mode' => 'r',
      'mode' => 'r' 
     },
     { 
      'name' => 'merged from', 
      'type' => 'line',
      'var'  => 'mergedFrom' 
     },
     { 
      'name' => 'comes from', 
      'type' => 'line',
      'var'  => 'previous', 
      'help' => 'enter a version if it cannot be figured out by the tool' 
     },
     { 
      'name' => 'writer',
      'type' => 'line', 
      'mode' => 'r' 
     },
     { 
      'name' => 'keywords', 
      'type' => 'array', 
      'pile' => 'push',
      'help' => 
      {
       'class' => 'VcsTools::DataSpec::HpTnd', 
       'section' => 'keywords'
      }
     },
     { 
      'name' => 'fix',
      'type' => 'array',
      'pile' => 'push',
      'help' => 'enter number a la GREhp01243' 
     },
     { 
      'name'   => 'behavior change' , 
      'type'   => 'enum',
      'var'    => 'behaviorChange',
      'values' => $bChangeData ,
      'help' => 
      {
       'class' => 'VcsTools::DataSpec::HpTnd', 
       'section' => 'CHANGE MODEL'
      }
     },
     { 
      'name'   => 'interface change' , 
      'type'   => 'enum',
      'var'    => 'interfaceChange',
      'values' => $changeData ,
      'help' => 
      {
       'class' => 'VcsTools::DataSpec::HpTnd', 
       'section' => 'CHANGE MODEL'
      }

     },
     { 
      'name'   => 'inter-peer change' , 
      'type'   => 'enum',
      'var'    => 'interPeerChange',
      'values' => $changeData ,
      'help' => 
      {
       'class' => 'VcsTools::DataSpec::HpTnd', 
       'section' => 'CHANGE MODEL'
      }
     },
     { 
      'name' => 'misc' , 
      'var'  => 'log', 
      'type' => 'text', 
      'pile' => 'concat',
      'help' => 'Edit all relevant history information. This editor uses most'
      .'emacs key bindings'
     }
    ];
}

# we could add a special field for info like
#bug fixed:

#toto
#titi



1;

# __END__


=head1 NAME

VcsTools::DataSpec::HpTnd - Hp Tnd custom data for HMS logs

=head1 SYNOPSIS

 use VcsTools::DataSpec::HpTnd qw($description readHook);
 use VcsTools::LogParser ;

 my $ds = new VcsTools::LogParser 
  (
   readHook => \&readHook,
   description => $description
  ) ;

=head1 DESCRIPTION

This class contains all the custom information needed to retrieve our
data from our database using the generic L<VcsTools::LogParser> class.

The $description hash ref defines the informations that
are contained in the log of each version of the HMS file.

Needless to say this file is tailored for HP Tnd needs and HMS keywords.
Nevertheless, it can be used as a template for other VCS systems and other
needs.

=head1 HP TND DATA DESCRIPTION

=head2 state

Taken from 'state' HMS field. It can be either Dead Exp Team Lab 
Special or Product according to the level of confidence. 

=head2 branches

Taken from 'branches' HMS field. List the branches of a version.
read-only value.

=head2 author

Taken from 'Author' HMS field. Name of the author of the revision or
the name of the last guy who modified the HMS log.

=head2 date

Date of the archive. Set by HMS. read-only value.

=head2 merged from

Specifies if this version is a merge between the parent revision
and another revision.

=head2 comes from

Explicitely specifies the parent revision. Use this field when
the parent cannot be infered. For instance, when the revision number jump
from 1.19 to 2.1, set the 'comes from' field of the revision '2.1' to '1.19'.

=head2 writer

The original writer of this version. Since HMS changes the 'Author' field
whenever you edit the history of a version, this field keeps track of the
guy who actually archived this version.

=head2 keywords

Keyword which refers to the functionnality added in this version.
(could be 'ANSI', 'cosmetic', 'doc_update' ...).

=head2 fix

Official names of the bugs fixed in this version (a la 'GREhp01234').

=head2 misc

Miscellaneous comments about this version.

=head1 CHANGE MODEL

The 3 following keywords try to provide a model for changes introduced with
each revision of a file.

=head2 behavior change

Specify whether this code can smoothly replace the previous revision.
Can be 'none', 'cosmetic', 'minor','major'

Still need a clear definition of what it means.

=head2 interface change 

Specify the amount of change seen from the compiler's point of view. For 
a header file, for instance, 'cosmetic' might mean 're-compilation needed',
'major' might mean 'code change needed in user code'.

Can be 'none', 'cosmetic', 'major'

=head2 inter-peer change

Specify whether this code can inter-work with the previous revision.

Can be 'none', 'cosmetic', 'major'

=head1 HOOKS

=head2 readHook(hash ref)

This method will try to get more information from the log of each revision.

If the 'fix' field is empty, readHook will look for GREhpxxxx keywords in
the log to guess what was fixed in this revision. Of course, it may guess
wrong if the log contains "I<Gee I forgot to fix GREhp00007>".

If the 'keywords' field is empty, readHook will look for keywords matching
C</\b([A-Z\d]{2,})\b/> in the log to guess what was added in this revision.
The result is often relevant, but is sometime silly.

=head1 AUTHOR

Dominique Dumont, Dominique_Dumont@grenoble.hp.com

Copyright (c) 1998-1999 Dominique Dumont. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1)

=cut

#'

sub readHook
  {
    my $info = shift ;

    foreach my $rev (keys %$info)
      {
        # set writer as author by default of previous version
        if (defined $info->{$rev}{author} and 
            not defined $info->{$rev}{writer})
          {
            $info->{$rev}{writer} = $info->{$rev}{author};
          }

        &guessKeywords($info,$rev) unless defined $info->{$rev}{keywords} ;

        &guessFix($info,$rev) unless defined $info->{$rev}{fix} ;

        if (defined $info->{$rev}{branches})
          {
            foreach my $branch (@{$info->{$rev}{branches}})
              {
                my $found = 0 ;
                for my $try (0..10)
                  {
                    my $bt = $branch . ".$try" ;
                    if (defined $info->{$bt})
                      {
                        $branch = $bt;
                        $found = 1 ;
                        last ;
                      }
                  }
                die "Error in history: 1st revision of branch $branch unknown\n"
                  unless $found ;
              }
          }
      }
  }

sub guessKeywords
  {
    my $info = shift ;
    my $rev = shift ;
    my %seen = () ;
    
    my @w = grep ( {! /^GREhp/ and ! $seen{$_}++ } 
                   ($info->{$rev}{log} =~ /\b([A-Z_\d]{2,})\b/g) ) ;
    
    $info->{$rev}{keywords}= \@w if scalar @w > 0;
  }

sub guessFix
  {
    my $info = shift ;
    my $rev = shift ;
    my %seen = () ;
    my @f = grep {! $seen{$_} ++} sort ($info->{$rev}{log} =~ /(GREhp\d+)/g) ;
    $info->{$rev}{fix}= \@f if scalar @f > 0;
  }

1;
