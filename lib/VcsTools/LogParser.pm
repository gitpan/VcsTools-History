package VcsTools::LogParser ;

use strict;
use Carp;

use vars qw($VERSION) ;
use AutoLoader qw/AUTOLOAD/ ;

$VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/;

# must pass the info data structure when creating it
sub new
  {
    my $type = shift ;
    my %args = @_;

    my $self = {} ;
    foreach (qw/description readHook writeHook/)
      {
        $self->{$_} = delete $args{$_} ;
      }
    
    croak "No description passed to LogParser\n" unless 
      defined $self->{description};

    my $desc = $self->{description};

    # get a regular hash from the description (array format)

    foreach my $item (@$desc)
      {
        my $name = $item->{name};
        my $var = defined $item->{var} ? $item->{var} : $item->{name} ;
        $self->{vcsName}{$name}= $item ; # vcs name
        $self->{internalName}{$var}= $item ;   # variable names
        #sql names
        if (defined $item->{sql})
          {
            $self->{sqlName}{$item->{sql}} = $item;
          }
      }

    bless $self,$type ;
  }

1;

__END__


=head1 NAME

VcsTools::LogParser - Perl class to translate RCS based log to info hash

=head1 SYNOPSIS

 my $ds = new VcsTools::LogParser (description => $big_hash);

 my @log = <DATA>;
 my $info = $ds->scanHistory(\@log) ;

 my $piledInfo = $ds->pileLog
  (
   'pile_test',
   [
    [ '3.10', $info->{'3.10'}],
    ['3.11', $info->{'3.11'}],
    ['3.12', $info->{'3.12'}],
    ['3.13', $info->{'3.13'}],
   ]
  ) ;

 print $ds->buildLogString ($piledInfo);

=head1 DESCRIPTION

This class is used to translate the log of a VCS file into 
a hash containing all relevant informations and vice-versa.

Currently, LogParser should work on all RCS based VCS systems. It
has been tested with RCS and HP HMS.

The description hash ref defines the informations that
are contained in the log of each version of the VCS file.

LogParser can also concatenate several logs into one according to the
rules defined in the description hash.

=head1 Contructor

=head2 new(...)

=over 4

=item *

description: has ref containing the description of the fields that can be
found in the VCS log.

=item *

readHook: Sub ref. See scanHistory method.

=back

=head1 Methods

=head2 scanHistory(log)

Analyse the history of a file and returns a hash ref containing all relevant
informations. The keys of the hash are made from the revision numbers found 
in the history log.

The log can be either a string or an array ref.

Once the log has been analysed and the informations have been stored in the
info hash according to the description, the 'readHook' passed to the
constructor will be called with the info hash ref as parameter. This gives
user the possibility to add its custom treatments to get more informations
from the log.

=head2 getDescription()

Return the hash ref describing the VCS log.

=head2 buildLogString(info_hash_ref)

Returns a log string from the info hash. The log string may be archived as is
in the VCS base.

=head2 pileLog(...)

Returns an info hash made of all informations about revision passed in the
array ref.

Parameters are:

=over 4

=item *

The first parameter is the name of the concerned Vcs file. This field
is necessary to build a readable cumulated log.

=item *

The second parameter is an array ref made where each element is an array 
ref made of the version number and the info hash ref of this revision.
(See example below)

=back

=head1 DESCRIPTION FORMAT

Each element of the array is a hash ref. This hash ref contains :

=over 4

=item *

name : name of the field as seen by the user or by the VCS system.

=item *

var : variable name used in internal hash (default = name), and through
the VcsTools objects. 

=item *

type : is either line, enum or array or text (see below)

=item *

values : array ref containing the possible values of enum type 
(ignored for other types)

=item *

mode : specifies if the value must be hidden (h) from the user or if 
it can be only read or also modified by the user (h|r|w) (default 'w')

=item *

pile: specify how the information are cumulated. (optional)

For array data type, it can be 'push'. In this case, the array elements
are pushed, then sorted and redundant infos are discarded.

For text data type, is can be 'concat'. In this case, the text strings are
concatenated together and with each file name and revision number.

=item *

vcs_mode: if 'r', the info is read from the VCS system but not
written to (ex: the archival date) (optional, defaults to 'w')

=item *

help : The help information can either be a string that will be displayed 
with a Tk::Dialog or a pointer to a Pod file that will be displayed with a
Tk::pod window.

In case of pod information, the help hash must be like :

 {
   'class' => 'Your::Class',
   'section' => 'DECRIPTION' # optionnal
 }

=back

=head1 EXAMPLE

Here's an example of a cumulated log :

 From pile_test v3.12:
   - coupled with tcapIncludes
   - does not compile in ANSI

 From pile_test v3.11:
 bugs fixed :

 - GREhp10971   :  TC_P_ABORT address format doesn't respect addr option.



=head1 AUTHOR

Dominique Dumont, Dominique_Dumont@grenoble.hp.com

Copyright (c) 1998-1999 Dominique Dumont. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1)

=cut

#'


# returns a hash ref containing all extracted infos
sub scanHistory
  {
    my $self = shift ;
    my $p = shift ;

    my $history = ref $p ? $p : [split(/\n/, $p)] ; # $p may be a string
    my %info = ();

    my ($revision,$line) ;
    

  MAINLOOP: while()
    {
      $line = shift @$history ;
      last unless defined $line ;

      chomp($line) ;

      
      if ($line =~ /^[-=]+$/) 
        {
          undef $revision ; 
          next ;
        }

      if (not defined $revision and $line =~ /^revision\s*([\d.]+)\s*$/) 
        {
          $revision = $1 ; 
          next ;
        }

      if (defined $revision)
        {
          next if $self->getFields(\%info,$revision,$line) ;
          $info{$revision}{'log'} .= $line."\n";
        }
    }
    
    # call hook if it was defined 
    &{$self->{readHook}}(\%info) if defined $self->{readHook}; 

    $self->{info} = \%info ;
    return \%info ;
  }

sub getDescription
  {
    my $self = shift ;
    return $self->{description} ;
  }

# internal
sub storeValue
  {
    my $self = shift ;
    my $infoRef = shift ;
    my $rev = shift ;
    my $fieldName = shift ;
    my $value = shift ;
    
    return 0 unless defined $value ;
    return 0 unless defined $self->{vcsName}{$fieldName};

    my $varName = $self->{vcsName}{$fieldName}{var} || $fieldName;

    #print "$fieldName, $varName, $value\n";

    if ($self->{vcsName}{$fieldName}{type} eq 'array' )
      {
        my @array = split(/[\s,;]+/,$value) ;
        $infoRef->{$rev}{$varName} = \@array ;
        return 1;
      }
    elsif (defined $self->{vcsName}{$fieldName})
      {
        $infoRef->{$rev}{$varName} = $value;
        return 1;
      }
    return 0;
  }

sub getFields
  {
    my $self = shift ;
    my $info = shift ;
    my $rev = shift ;
    my $line = shift ;

    # for lines a la 
    my @fields = split (/\s*:\s*/,$line);

    if (scalar @fields == 2)
      {
        # simple case like
        # stuff: .....
        return $self->storeValue($info,$rev,@fields);
      }
    else
      {
        # more complex stuff like
        # date: 1997/09/24 13:34:02; author: herve; state: Exp;  lines: +4 -4
        # or completely random text

        my $found = 0;
        foreach my $field (split (/\s*;\s*/,$line))
          {
            $found ++ if 
              $self->storeValue($info,$rev,split(/\s*:\s*/,$field,2));
          }
        return $found ;
      }
  }

sub bdLogHeader
  {
    my $self = shift ;
    my $info = shift ; # hash ref containing all infos (without revision)

    my $logStr ;
    foreach my $item (@{$self->{description}})
      {
        my $varName = defined $item->{var} ? $item->{var} : $item->{name} ;

        # skip special cases handled by vcs
        next if (defined $item->{vcs_mode} and  $item->{vcs_mode} eq 'r');

        # skip blank entries
        next unless defined $info->{$varName} ;

        if ($item->{type} eq 'array')
          {
            $logStr .= $item->{name}.": ".join(', ',@{$info->{$varName}})."\n";
          }
        elsif ($item->{type} eq 'text' and $varName eq 'log')
          {
            next; # log is a special case
          }
        else
          {
            $logStr .= $item->{name}.": ". $info->{$varName}. "\n" ;
          }
      }

    return $logStr ;
  }

sub buildLogString
  {
    my $self = shift ;
    my $info = shift ; # hash ref containing all infos (without revision)

    my $logStr = $self->bdLogHeader($info);

    $logStr .= &{$self->{writeHook}}($info) if defined $self->{writeHook};

    $logStr .= $info->{'log'} if defined $info->{'log'} ;

    return $logStr ;
  }

# test OK, ajouter dans pgm test.
#if no arg is passed internal names are returned
#else, the names related to the arg are returned
#eg sql if param is 'sql'
#and vcs_name if param is 'vcs'
sub getKeys
  {
    my $self = shift ;
    my $arg = shift || '';
    return keys %{$self->{sqlName}} if $arg eq 'sql';
    return keys %{$self->{vcsName}} if $arg eq 'vcs';
    return keys %{$self->{internalName}};
  }


sub getRelations
  {
    my $self = shift ;
    my $arg = shift;
    return %{$self->{sqlName}} if $arg eq 'sql';
    return %{$self->{vcsName}} if $arg eq 'vcs';
    return %{$self->{internalName}} if $arg eq 'var';
    
    die "Internal error: no relation name passed to LogParser::getRelations";
  }

#DEPRECATED
#if param name, only key=name => value=var couples are returned
#if param var, only key=var => value=name couples are returned
#if no param is passed all couples are returned
sub getCouples
  {
    my $self = shift;
    my $way = shift;

    carp "LogParser::getCouples method is deprecated";

    my %tmp;
    foreach (@{$self->{description}})
      {
        if (not defined $way or $way eq 'var')
          {
            $tmp{$_->{var}} = $_->{name};
          }
        if (not defined $way or $way eq 'name')
          {
            $tmp{$_->{name}} = $_->{var};
          }
     }
    return %tmp;
  }


# TBD accept more conventional parameters
# TBD accept with no name and rev for simple piling without "From xx rev yy:"
sub pileLog
  {
    my $self = shift ;
    my $name = shift ; # file name
    my $infoSet = shift ; # [ [ rev, info_ref], ... ,[ancestor, info_ref] ]

    # pile logs and other infos from bottom to top
    my %result ;

    foreach my $elt (@$infoSet)
      {
        my ($tmpRev,$info) = @$elt ;

        foreach my $item (@{$self->{description}})
          {
            next unless defined $item->{'pile'} ;

            my $varName = defined $item->{var} ? $item->{var} : $item->{name};

            next unless defined $info->{$varName} ;

            if ($item->{pile} eq 'push' )
              {
                my @array = defined $result{$varName} ?
                  @{$result{$varName}}:();
                my %hash ;
                map( $hash{$_} = 1, @array, @{$info->{$varName}});
                @{$result{$varName}} = sort keys %hash ;
              } 
            elsif ($item->{pile} eq 'concat')
              {
                next if not defined $info->{$varName} or 
                  $info->{$varName} =~ /^[\s\n]*$/ ;
                my $str = defined $result{$varName} ? $result{$varName} : '' ;
                $result{$varName} = 
                  "From $name v$tmpRev:\n". 
                    $info->{$varName}."\n".
                      $str;
              } 
          }
      }
    
    return \%result ;
  }

