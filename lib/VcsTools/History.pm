package VcsTools::History ;

use strict;
use VcsTools::Version ;
use Time::Local ;
use Puppet::Body ;
use Puppet::Storage ;
use Carp ;

use vars qw($VERSION);

use AutoLoader qw/AUTOLOAD/ ;

$VERSION = sprintf "%d.%03d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/;

sub new
  {
    my $type = shift ;
    my %args = @_ ;

    my $self = {};
    $self->{name}=$args{name};

    $self->{body} = new Puppet::Body(cloth => $self, @_) ;

    my %storeArgs = %{$args{storageArgs}} ;
    
    croak "No storageArgs defined for VcsTools::History $self->{name}\n"
      unless defined %storeArgs;

    $self->{storageArgs} = \%storeArgs;

    my $usage = $self->{usage} = $args{usage} || 'File' ;
    if ($usage eq 'MySql')
      {
        require VcsTools::HistSqlStorage;
        $self->{storage} = new VcsTools::HistSqlStorage (%storeArgs) ;
      }
    else
      {
        $self->{storage} =  new Puppet::Storage (name => $self->{name},
                                                 %storeArgs) ;
      }

    # mandatory parameter
    foreach (qw/name dataScanner/)
      {
        croak "No $_ passed to $self->{name}\n" unless 
          defined $args{$_};
        $self->{$_} = delete $args{$_} ;
      }

    # modify the key root for all the version objects
    $self->{storageArgs}{keyRoot} .= ' '.$self->{name} ;
    bless $self,$type ;
  }

sub body { return shift->{body}} ;
sub storage { return shift->{storage}} ;

1;

__END__

=head1 NAME

VcsTools::History - Perl class to manage a VCS history.

=head1 SYNOPSIS

 require VcsTools::DataSpec::HpTnd ; # for instance
 my $ds = new VcsTools::DataSpec::HpTnd ;
 my $hist = new VcsTools::History 
  (
   keyRoot => 'history root',
   name => 'History test',
   dataScanner => $ds
  );



=head1 DESCRIPTION

This class represents a whole history of a VCS file. It holds all the
necessary L<VcsTools::Version> objects that makes the complete history
of the file.

Generally, RCS based systems such as VCS or HMS store a few
information with each revision. These information are generally
'Author', 'date', 'branches', 'log'. On top of the common
informations, you can specify your own set of information (for
instance, 'merged from', 'bug fixed') according to the policies
defined on your work place.

On top of the functionnality of the Version object (See
L<VcsTools::Version/"DESCRIPTION">), you can perform various queries
related to the history such as :

=over 4

=item *

Sort revisions: it will return a pair of revisions sorted by
age. Oldest and child. But it will return an error if these two
versions are not parents of each others.

=item *

List a genealogy of versions between 2 revisions of a file. This will
take into account the branches. For instance between 1.1 and 1.2.1.2, it
will return 1.1 1.2 1.2.1.1 1.2.1.2), but between 1.3 and 1.2.1.2 it will
return an error, since these two versions are not parents of each others.

=item *

Build a cumulated log of several revisions. I.e a log description of
all changes made to several consecutive versions (which is handy to
build a log of a merge). This function will return an if these two
versions are not parents of each others.

=back

Furthermore, this class can be used with a GUI by using 
L<Puppet::VcsTools::History> instead. 

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

Will create a new history object.

Parameters are those of L<Puppet::Body> plus :

=over 4

=item *

revision : revision number of this version

=item *

dataScanner : L<VcsTools::DataSpec::Rcs> or
L<VcsTools::DataSpec::HpTnd> (or equivalent) object reference

=back

=head1 Methods

=head2 update(...)

Parameters are:

=over 4

=item *

history: huge string or array ref of all VCS logs, or history hash ref using the format
described in data scanner

=back

This method will:

=over 4

=item *

Parse the content of the history.

=item *

Create all Version objects found in the history

=item *

Update all Version objects with the informations found in each log.

=back

Note that calling this method will clobber all informations previously
stored in the Version objects.

=head2 hasVersion(revision)

Returns 1 if the VCS file contains this revision of the file.

=head2 guessNewRev(revision)

Returns a fitting revision number to follow the passed revision.

For instance :

=over 4

=item *

guessNewRev(1.2) returns 1.3 if 1.3 does not exist

=item *

guessNewRev(1.2) returns 1.2.1.1 if 1.3 already exists

=item *

guessNewRev(1.2) returns 1.2.2.1 if 1.3 and branch 1.2.1 already exist

=back

=head2 sortRevisions($rev1, $rev2)

Returns ($rev1, $rev2) if $rev1 is the ancestor of $rev2, ($rev2, $rev1) in
the other case.

Returns undef if the revisions are not parents.

=head2 listGenealogy($rev1, $rev2)

Returns a list of all revision between $rev1 and $rev2. Include the youngest 
revision in the list, but not the older.

Croaks if the revision are not parents.

=head2 getInfo($rev)

Returns an info array containing all informations relevant to $rev.

=head2 buildCumulatedInfo($rev1, $rev2)

Returns an info array made of a concatenation of all revision 
 between $rev1 and $rev2.

Croaks if the revisions are not parents.

=head2 addNewVersion(...)

Parameters are:

=over 4

=item *

revision: revision to add (e.g. '1.2.1.1')

=item *

info: hash ref containing the informations related to this revision.

=back

This method will add a new version in this history. Do not call this method
unless the VCS system actually has a new version, i.e. the user just 
performed an archive. 

=head2 getVersionObj(revision)

Returns the object ref of the Version object representing the passed 
revision. Will create the objects as necessary. 

Returns undef if the asked revision does not exist.

=head1 AUTHOR

Dominique Dumont, Dominique_Dumont@grenoble.hp.com

Copyright (c) 1998-1999 Dominique Dumont. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), VcsTools::DataSpec::HpTnd(3), VcsTools::DataSpec::Rcs(3)
VcsTools::Version(3), Puppet::VcsTools::History(3)

=cut


# called only when this history is attached with VcsTools::File
sub update
  {
    my $self = shift ;
    my %args = @_ ; 
    my $history = $args{history}; # array ref of history lines

    die "No archive mod time passed to history update\n" 
      unless defined $args{time};
    die "No history passed to history update\n" 
      unless defined $history;

    if ($self->{usage} eq 'File') # temporary hack
      {
        my $oldTime =  $self->{storage}->getDbInfo('historyUpdateTime') ;
        if (defined $oldTime and $args{time} < $oldTime)
          {
            $self->{body}->printEvent ("History info is already up to date\n");
            return ;
          }
        else
          {
            $self->{storage}->
              storeDbInfo('historyUpdateTime' => timelocal(localtime)) 
          }
      }

    #if $history is not a ref on the infohash, let's get it 
    #from the log stored in $history 
    my $hash = ref($history) eq 'HASH' ? 
      $history : $self->{dataScanner} -> scanHistory($history);
       
    my @version = keys %$hash;

    #if ($self->{usage} eq 'MySql')
    #  {
    #    #for compatibility with VcsTools::Version, we must convert keys
    #    #of the infohashes from dataformat(var) to dataformat(name)
    #    my %nameAndVar = $self->{dataScanner}->getCouples('var');
    #    foreach my $ver (@version)
    #      {
    #        #convert hash keys
    #        foreach my $key (keys %{$hash->{$ver}})
    #          {
    #            $hash->{$ver}{$nameAndVar{$key}} = delete $hash->{$ver}{$key} 
    #            if defined $nameAndVar{$key};
    #          }
    #      }
    #  }

    # must destroy and re-create all relevant version object
    $self->{body}->dropAll();

    # must clean up the old version list
    undef $self->{version} ;

    # version hash must have all revision as keys
    map( $self->{version}{$_} = 1,
         @version) ;
    
    # first, create all version object and store relevant info in it
    map ($self->getVersionObj($_),@version) ;

    # and update the info in there
    map ($self->getVersionObj($_)->update(info => $hash->{$_}),@version) ;

    # verify if all (minus 1) versions have a parent ...
    my @orphan =();
    foreach my $v (@version)
      {
        unless ($self->getVersionObj($v)->hasParent)
          {
            $self->{body}->printEvent("Version $v has no previous version\n");
            push @orphan,$v;
          }
      }
    if (scalar @orphan > 1)
      {
        $self->{body}->printEvent
          ("Warning: $self->{name} has more than one revision without parent\n". join(' - ',@orphan)."\n") ;
        #$self->{body}->showEvent();
      } 
    
    #update the permanent data storage if usage is set to 'File'
    $self->storage()->storeDbInfo(versionList => [keys %$hash])
      if $self->{usage} eq 'File';

  }

sub guessNewRev
  {
    my $self = shift ;
    my $rev = shift ;

    return '1.0' unless defined $rev ;

    #? $self->{body}->printEvent("guessNewRev: Revision $rev does not exist\n");

    my $newRev = $rev ;
    $newRev =~ s/(\d+)$/$1+1/e ;
    
    if ($self->hasVersion($newRev))
      {
        # simple increment does not work, must branch
        $newRev = $rev . '.1.1' ;
        while ($self->hasVersion($newRev))
          {
            $newRev =~ s/(\d+)(\.\d+)$/($1+1).$2/e ;
          }
      }
    return $newRev ;
  }

sub hasVersion
  {
    my $self = shift ;
    my $rev = shift ;

    unless (defined $self->{version})
      {
        map( $self->{version}{$_} = 1,
#Bob             @{$self->{body}->getContent('versionList')}) ;
             @{$self->{storage}->getDbInfo('versionList')}) ;
      }
    
    return defined $self->{version}{$rev} ;
  }

# return ancestor, child
sub sortRevisions
  {
    my $self = shift ;

    croak "cannot sort more or less than 2 revs \n" if scalar(@_) != 2 ;

    my $rev1 = shift ; 
    my $rev2 = shift ; 

    my $obj1 = $self->getVersionObj($rev1) ;
    
    croak "undefined version for $self->{name} v $rev1\n" 
      unless defined $obj1;

    my $anc = $obj1 -> findAncestor($rev2) ;
    
    unless (defined $anc and ($anc eq $rev1 or  $anc eq $rev2))
      {
        $self->{body}->printEvent( "cannot sort these rev $rev1 and $rev2 for $self->{name} (different branches)\n");
        return undef;
      }
        
    return $anc eq $rev1 ? ($rev1, $rev2) :  ($rev2, $rev1) ;
  }

sub listGenealogy
  {
    my $self = shift ;

    my ($anc,$child) ;

    if (scalar(@_) == 2)
      {
        ($anc,$child) = $self->sortRevisions(@_);
      }
    elsif (scalar(@_) == 1)
      {
        $child = shift ; 
        my $obj1 = $self->getVersionObj($child) ;
    
        croak "undefined version for $self->{name} v $child\n" 
          unless defined $obj1;

        $anc = $obj1 -> findOldest() ;
      }
    else
      {
        croak "cannot sort more than 2 revs or less than 1\n" ;        
      }

    my $tmpRev = $child ;
    my @result = () ;
        
    while ($tmpRev ne $anc)
      {
        unshift @result, $tmpRev ;
        $tmpRev = $self->getVersionObj($tmpRev)->getUpperRev();
      }

    return \@result ;
  }

sub getInfo
  {
    my $self = shift ;

    my @array = ( );
    my @keys = $self->{dataScanner}->getKeys() ;
    return $self->getVersionObj(shift)->storage()->getDbInfo(@keys) ;
  }

sub buildCumulatedInfo
  {
    my $self = shift ;

    croak "cannot build cumul info on more than 2 revs \n" 
      if scalar(@_) > 2 ;
    
    my @array = ( );
    my @keys = $self->{dataScanner}->getKeys() ;
    foreach my $r (@{$self->listGenealogy(@_)})
      {
        push @array, 
        [$r, $self->getVersionObj($r)->storage()->getDbInfo(@keys)] ;
      }

    return $self->{dataScanner}->pileLog($self->{name}, \@array);
  }

## TBD a revoir

# user select archive
# File set up default info array,
# File run editor on default array
# user select archive button
# File checks-in the file
# File asks history to create new version.

# called to add a new version of the file (after an archive)
sub addNewVersion
   {
     my $self = shift ;
     my %args = @_ ;
   
     foreach (qw/revision info/)
       {
         croak "No $_ passed to $self->{name}-> addNewVersion\n" unless
           defined $args{$_};
       }

     croak "No after passed to $self->{name}-> addNewVersion\n" unless
       exists $args{after}; # can be set to undef if first revision

     my $revision = $args{revision} ;

     $self->{body}->printEvent("Adding new version $revision");

     # error check ($self->{version} must be tested before $self->{version}{$revision}, or $self->{version} will become defined)
     croak "Can't archive an existing version ($args{revision})\n"
       if defined $self->{version} and defined $self->{version}{$revision} ;
   
     # create new version object
     my $obj = $self->createVersionObj($revision) ;
   
     # store any info in this new object
     $obj->update(info => $args{info}, upper => $args{after}) ;

     # store this new revision in my data base
     if ($self->{usage} eq 'File')
       {
         my $array = $self->{storage}->getDbInfo('versionList');
         push @$array, $revision ;
         $self->{storage}->storeDbInfo(versionList => $array) ;
       }

     $self->{version}{$revision} = 1 ;

     $self->{body}->acquire(name => $revision, body => $obj->body()) ;

     return $obj ;
   }


sub getVersionObj
  {
    my $self = shift ;
    my $rev = shift ;

    my $obj = $self->{body}->getContent($rev);
    return $obj->cloth()  if defined $obj ;

    unless (defined $self->{version})
      {
        my $ref = $self->{storage}->getDbInfo('versionList') ;
        my @list = ref($ref) ? @$ref : () ;
        map( $self->{version}{$_} = 1,@list);
      }

    if (defined $self->{version}{$rev})
      {
        my $obj = $self->createVersionObj($rev) ;
        $self->{body}->acquire(name => $rev, body => $obj->body()) ;
        return $obj ;
      }
    
    #$self->{body}->printEvent("Attempted to create ghost version for rev $rev\n");
    return undef ;
  }

#internal do not call from outside because there's no sanity checks
sub createVersionObj
  {
    my $self = shift ;
    my $rev = shift ;

    $self->{body}->printDebug("Creating version object for rev $rev\n");
    
    return new VcsTools::Version  
      (
       name => $rev,
       title => "$self->{name} v$rev",
       storageArgs => $self->{storageArgs},
       trace => $self->{trace},
       usage => $self->{usage},
       manager => $self,
       revision => $rev
      ) ;
  }

sub getInfoHash
  {
    my $self = shift ;
    my $p = shift ;
    
    unless (defined $p)
      {
        #will return the whole history if no param is passed
        return $self->storage()->getDbInfo();
      }
    
    my $revObj = ref($p) ? $p : $self->getVersionObj($p);
    my @keys = $self->{dataScanner}->getKeys() ;
    return $revObj->storage()->getDbInfo(@keys);
  }

sub getLog
  {
    my $self = shift ;
    my %args = @_ ;
    my $key =  $args{key} ; #optional
    my $h = $self->getInfoHash($args{version});
    
    return defined $key ? $h->{$key} :
      $self->{dataScanner}->buildLogString($h);
  }

1;

__END__




# Pas testee
# sub findMerge
#   {
#     my $self = shift ;
#     my $rev1 = shift ;
#     my $rev2 = shift ;

#     # find in history if rev1 and rev2 are merged. return the merge version
#     foreach (("$rev1-$rev2","$rev2-$rev1"))
#       {
#         if (defined $self->{myDbHash}{info}{mergeList}{$_}) 
#           {
#             my $rev =  $self->{myDbHash}{info}{mergeList}{$_} ;

#             while ($self->{myDbHash}{state} eq 'Dead')
#               {
#                 my $old = $rev ;
#                 $rev = $self->{myDbHash}{lower} ;
#                 unless (defined $rev)
#                   {
#                     croak "Found Dead $self->{name} version $old for merge\n"  ;
#                     return undef ;
#                   } 
#               }
#             return $rev ;
#           }
#       }

#     return undef ;
#   }
