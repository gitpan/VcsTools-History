package VcsTools::Version ;

use Puppet::Body;
use Puppet::Storage;

use strict;
use vars qw(@ISA $VERSION $test);
use Carp ;
use AutoLoader qw/AUTOLOAD/ ;

$VERSION = sprintf "%d.%03d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/;

$test = 0 ;

# must pass the info data structure when creating it
sub new
  {
    my $type = shift ;
    my %args = @_ ;

    my $self = {};

    $self->{body} = new Puppet::Body(cloth => $self, @_) ;

    my %storeArgs = %{$args{storageArgs}} ;
    croak "No storeArgs defined for VcsTools::Version $self->{name}\n"
      unless defined %storeArgs;
 
    #personalization of the key root
    $storeArgs{keyRoot} .= $args{revision};

    my $usage = $self->{usage} = $args{usage} || 'File';

    if ($usage eq 'MySql')
      {
        $storeArgs{version} = $args{revision};
        require VcsTools::VerSqlStorage;
        $self->{storage} = new VcsTools::VerSqlStorage (%storeArgs) ;
      }
    else
      {
        $self->{storage} =  new Puppet::Storage (%storeArgs) ;
      }


    # mandatory parameter
    foreach (qw/revision manager/)
      {
        die "No $_ passed to $self->{name}\n" unless 
          defined $args{$_};
        $self->{$_} = delete $args{$_} ;
      }
    
    bless $self,$type ;
  }

sub body { return shift->{body}} ;
sub storage { return shift->{storage}} ;

1;

__END__

=head1 NAME

VcsTools::Version - Perl class to manage VCS revision.

=head1 SYNOPSIS

No synopsis given. This object is better used with the History module.

=head1 DESCRIPTION

This class represents one version of a VCS file. It holds all the 
information relevant to this version including the
parent revision, child revision, branches revisions and do on.

Its main function is to provides the functionnality to manage versions
(inluding branches and merges) of a Vcs file: 

=over 4

=item *

Find the common ancestor of 2 revisions (but this does not yet take
merges into account)

=item *

Find the oldest parent of a revision

=item *

Find all children of a revision (taking merges into account)

=back

All these information can be stored in a database. See L<Puppet::Body>
for more details.

=head1 CONVENTION

The following words may be non ambiguous for native english speakers, but it
is not so with us french people. So I prefer clarify these words:

=over 4

=item *

Log: Refers to the information stored with I<one> version.

=item *

History: Refers to a collection of all logs of all versions stored in
the VCS base.

=back

=head1 Constructor

=head2 new(...)

Parameters are :

=over 4

=item *

All parameter of L<Puppet::Body/"Constructor">

=item *

revision : revision number of this version

=item *

manager: the ref of the history object.

=back

=head1 Methods

=head2 update(...)

Parameters are:

=over 4

=item *

info: hash ref of log informations

=back

This methods takes a hash reference containing all informations extracted 
from the VCS log of this version. Then all other complementary informations
(such as upper revision, branches revisions, revision that were eventually
merged in this one) are computed and stored in the database.

=head1  getRevision()

Returns the revision number of this object.

=head1  getUpperRev()

Returns the revision number of the "parent" of this object.

=head1  hasParent()

Returns true if this version has a "parent" object.

=head1  findAncestor(other_revision_number)

Returns the ancestor number of this revision and the other.

Returns undef in case of problems.

=head1  findOldest()

Returns the version number of the oldest parent in the revision tree that it
can find. 

=head1  getLog()

Returns the log of this version object.
 
=head1 AUTHOR

Dominique Dumont, Dominique_Dumont@grenoble.hp.com

Copyright (c) 1998-1999 Dominique Dumont. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), Puppet:Body:(3), VcsTools::History(3)

=cut

sub getVersionObj
  {
    my $self = shift ;
    $self->{manager}->getVersionObj(@_);
  }

sub getLog 
  {
    my $self = shift ;

    return $self->{storage}->getDbInfo('log');
  }

# return 1 if a previous object was found, 0 if not
sub update
  {
    my $self = shift ;
    my %args = @_ ; # array ref of log lines
    my $stored_info = $args{info};
    
    $self->{body}->printDebug("Updating info on version $self->{revision}\n");
    # must update the info gotten from the log info

    # if the upper parameter is specified, then this version object was just
    # created. Depending on this upper parameter we may need to
    # update the 'branch' info of the upper object or create the 'previous'
    # field of this object (jump in revision)

    # Try to figure out the 'canonical upper object'
    my $tmp = $self->{revision} ;
    $tmp =~ s/(\d+)$/$1-1/e ; # decrement rev

    my $upperObj = $self->getVersionObj($tmp) ;

    if (defined $upperObj)
      {
        if (defined $stored_info->{previous} and $tmp ne $stored_info->{previous} )
          {
            croak "Major problem: $self->{name} version $self->{revision} has ",
            "declared previous rev ", $stored_info->{previous},
            " and implicit previous rev $tmp\n" ;
          }
        elsif (defined $args{upper} and $tmp ne $args{upper})
          {
             croak "Major problem: $self->{name} version $self->{revision} has ",
            "declared upper rev ", $args{upper},
            " and implicit previous rev $tmp\n" ;
          }
        $stored_info->{upper} = $tmp ;
        $upperObj->storage()->storeDbInfo(lower=> $self->{revision}) ;
      }
    elsif (defined $args{upper})
      {
        # we have either a branch or a jump
        my @a = split(/\./,$self->{revision});
        my @b = split(/\./,$args{upper}) ;
        $upperObj = $self->getVersionObj($args{upper}) ;
        croak "Major error: Cannot find object for upper revision: $args{upper}\n"
          unless defined $upperObj;

        if (scalar @a ne scalar @b)
          {
            # it's a new branch
            $upperObj-> addBranch($self->{revision});
            $stored_info->{upper} = $args{upper} ;
          }
        else
          {
            # it's a jump
            $stored_info->{previous}=$args{upper} ;
            $upperObj->storage()->storeDbInfo(lower=> $self->{revision}) ;
          }
        
      }
    elsif (defined $stored_info->{previous})
      {
        # only during the scan of the history log

        $upperObj = $self->getVersionObj($stored_info->{previous}) ;
        die "Major problem: $self->{name} version $self->{revision} has a ",
        "non-existent previous version $stored_info->{previous}\n"
          unless defined $upperObj ;
        $stored_info->{upper} = $stored_info->{previous} ;
        $upperObj->storage()->storeDbInfo(lower=> $self->{revision}) ;
      }

    if (defined $stored_info->{mergedFrom})
      {
        my $otherObj = $self->getVersionObj($stored_info->{mergedFrom}) ;

        die "Non existant version $stored_info->{mergedFrom} in mergedFrom field\n"
          unless defined $otherObj ;

        my $ref = $otherObj->addMergedIn($self->{revision});
      }

    if (defined $stored_info->{branches})
      {
        # update the upper revision of each branched object
        foreach my $b (@{$stored_info->{branches}})
          {
            my $obj = $self->getVersionObj($b) ;
            if (defined $obj)
              {
                $obj ->storage()-> storeDbInfo (upper => $self->{revision}) ;
              }
            else
              {
                warn "$self->{name} v$self->{revision} has a non-existant branch: $b";
              }
          }
      }

    if (defined $stored_info->{log} and $stored_info->{log} !~ /\n$/)
      {
        $stored_info->{log}.="\n";
      }

    $self->{storage}->storeDbInfo(%$stored_info) ;
  }

# internal
sub addBranch
  {
    my $self = shift ;
    my $b = shift;
    my $ref = $self->{storage}->getDbInfo('branches') ;
    my @array = defined $ref ? @$ref : () ;
    push @array, $b ;
    $self->{storage}->storeDbInfo(branches => \@array) ;
  }

# internal
sub addMergedIn
  {
    my $self = shift ;
    my $b = shift;

    # emulate a push 
    my $ref = $self->{storage}->getDbInfo('mergedIn') ;
    my @array = defined $ref ? @$ref : () ;
    push @array, $b ;
    $self->{storage}->storeDbInfo(mergedIn => \@array) ;
  }

sub getRevision
  {
    my $self = shift ;
    return $self->{revision};
  }

sub getUpperRev
  {
    my $self = shift ;
    return $self->{storage}->getDbInfo('upper');
  }

sub hasParent
  {
    my $self = shift ;
    return defined $self->{storage}->getDbInfo('upper') ;
  }

sub findOldest
  {
    my $self = shift ;

    my $rev = $self->{revision} ; 
    
    my $upper = $self->{storage}->getDbInfo('upper') ;
    if (defined $upper)
      {
        return $self->{manager}->getVersionObj($upper) ->findOldest();
      }
    else
      {
        # return the oldest version found
        return $rev ;
      }
    }

# Does not take merges into account

# if it takes merge into account, it will get more than one ancestor,
# in this case, the different ancestor should all be children of the
# other, then different ancestor will have to be compared to find the
# youngest child of them

sub findAncestor
  {
    my $self = shift ;
    my $other = shift ;

    my $rev = $self->{revision} ;

    my $top = $rev ;
    my $done = {} ;

    # first look down
    if ($self->isOtherRevDown($done,$other))
      {
        print("$rev is child and ancestor\n") if $test;
        return $rev  ;
      }

    # search higher 
    my $upper = $self->{storage}->getDbInfo('upper') ;
    if (defined $upper)
      {
        my $obj = $self->getVersionObj( $upper);
        if ($obj->isAncestorUp($done, $other,\$top))
          {
            print("Found ancestor $top\n") if $test;
            return $top ;
          }
      }
    else
      {
        print("Can't find ancestor of $rev and $other\n") if $test;
        return undef ;
      }
  }

#internal method
sub isAncestorUp
  {
    my $self = shift ;
    my $done = shift ;
    my $other = shift ;
    my $topRef = shift ;

    my $rev = $self->{revision} ; 
    
    print("Looking up  rev $rev, top is $$topRef, other $other\n") if $test;
    return 0 if defined $done->{$rev} ;

    if ($rev eq $other) { $$topRef = $rev; return 1 ;} ;
    $done->{$rev} = 1 ;

    my $branches = $self->{storage}->getDbInfo('branches') ;
    # if branches search down for each branch, store $top
    if (defined $branches)
      {
        $$topRef = $rev ;
        foreach my $branch ( @$branches )
          {
            return 1 if $self->{manager} -> getVersionObj($branch)
              ->isOtherRevDown($done,$other) ;
          }
      }

    my $lower = $self->{storage}->getDbInfo('lower') ;
    # follow main branch if we come from branch
    if (defined $lower)
      {
        return 1 if $self->{manager} -> getVersionObj($lower) 
          ->isOtherRevDown($done,$other);
      }

    # else go higher
    my $upper = $self->{storage}->getDbInfo('upper');
    if (defined $upper)
      {
        return $self->{manager} 
          ->getVersionObj($upper)
          ->isAncestorUp($done,$other,$topRef);
      }
    else
      {
        #else fail
        return 0 ;
      }
  }

# internal method
sub isOtherRevDown
  {
    my $self = shift ;
    my $done = shift ;
    my $other = shift ;

    my $rev = $self->{revision} ; 

    print("Looking down rev $rev, other $other\n") if $test;

    return 0 if defined $done->{$rev} ;
    $done->{$rev} = 1 ;


    # if rev eq leaf return 1
    return 1 if ($rev eq $other) ;

    # if branches search down each branch
    my $branches = $self->{storage}->getDbInfo('branches');
    if (defined $branches)
      {
        foreach my $branch ( @$branches )
          {
            return 1 if $self->getVersionObj($branch)
              ->isOtherRevDown($done,$other) ;
          }
      }

    # else go down
    my $lower = $self->{storage}->getDbInfo('lower') ;
    if (defined $lower)
      {
        return $self->getVersionObj($lower) ->isOtherRevDown($done,$other);
      }
    else
      {
        #else fail
        return 0 ;
      }
  }


# Pas testee car je ne suis pas sur de l'utilite ...

# will return all child revision (including the children resulting from 
# a merge)
sub findChildren
  {
    my $self = shift ;
    my $hash = shift || {}; # ref of a hash
    my $level = shift || 0;
    
    my $rev = $self->{revision} ; 

    $hash->{$rev} =$level++ ;

    # if branches search down each branch
    my $stuff = $self->{storage}->getDbInfo('branches') ;
    if (defined  $stuff)
      {
        foreach my $branch ( @$stuff )
          {
            $self->getVersionObj($branch) ->findChildren($hash, $level) ;
          }
      }
    
    $stuff = $self->{storage}->getDbInfo('mergedIn') ;
    if (defined  $stuff)
      {
        foreach my $branch ( @$stuff )
          {
            $self->getVersionObj($branch) ->findChildren($hash, $level) ;
          }
      }

    # else go down
    my $lower = $self->{storage}->getDbInfo('lower');
    if (defined $lower)
      {
        $self->getVersionObj($lower) ->findChildren($hash,$level) ;
      }

    return sort keys %$hash ;
  }
