package VcsTools::DataSpec::Rcs ;

use strict;

use vars qw(@ISA $VERSION $description @EXPORT_OK) ;
require Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = qw($description readHook);

$VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/;

# $logDataFormat is a array ref which specifies all information that can
# edited or displayed on the history editor.


{
  my @state = qw(Dead Exp Product) ;

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
      'name' => 'misc' , 
      'var'  => 'log', 
      'type' => 'text', 
      'pile' => 'concat',
      'help' => 'Edit all relevant history information. This editor uses most'
      .'emacs key bindings'
     }
    ];
}


sub readHook
  {
    my $info = shift ;

    foreach my $rev (keys %$info)
      {
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


1;


=head1 NAME

VcsTools::DataSpec::Rcs - Rcs data description

=head1 SYNOPSIS

 use VcsTools::DataSpec::Rcs qw($description readHook);
 use VcsTools::LogParser ;

 my $ds = new VcsTools::LogParser 
  (
   readHook => \&readHook,
   description => $description
  ) ;

=head1 DESCRIPTION

This class contains all the custom information needed to retrieve 
data from an RCS log using the generic L<VcsTools::LogParser> class.

The $description hash ref defines the informations that
are contained in the log of each version of the RCS file.

This class can be used as a template for other VCS systems and other
needs.

The readHook is used to find the first revision of a branch. For instance
a branch is named 1.5.1 in the VCS history, the readHook will find that
the actual first revision of the branch is 1.5.1.1.

=head1 RCS DATA DESCRIPTION

=head2 state

Taken from 'state' RCS field. It can be either Dead Exp or Product
according to the level of confidence.

=head2 branches

Taken from 'branches' RCS field. List the branches of a version.
read-only value.

=head2 Author

Taken from 'Author' RCS field. Name of the author of the revision or
the name of the last guy who modified the RCS log.

=head2 date

Date of the archive. Set by RCS. read-only value.

=head2 misc

Miscellaneous comments about this version.

=head1 AUTHOR

Dominique Dumont, Dominique_Dumont@grenoble.hp.com

Copyright (c) 1998-1999 Dominique Dumont. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1)

=cut

#'


1;
