# $Id$
#
# BioPerl module for Bio::Map::fpcmarker
#
# Cared for by Gaurav Gupta <gaurav@genome.arizona.edu>
#
# Copyright Gaurav Gupta
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::Map::FPCMarker - An central map object representing a marker

=head1 SYNOPSIS

   ## get the marker object of $marker from the Bio::Map::FPCMarker
   my $markerobj = $physical->get_markerobj($marker);

   ## acquire all the clones that hit this marker
   foreach my $clone ($markerobj->each_cloneid()) {
       print "   +++$clone\n";
   }

   ## find the position of this marker in $contig
   print "Position in contig $contig"," = ",$markerobj->position($contig),
         "\n";

   ## find the group of the marker
   print "Group : ",$markerobj->group();


See L<Bio::Map::Position> and L<Bio::Map::PositionI> for more information.

=head1 DESCRIPTION

This object handles the notion of a marker.

This object is intended to be used by a map parser like fpc.pm.

=head2 Design principles

A MappableI is a central object in Bio::Map name space. A Map is a holder
class for objects. A MappableI has a Position in a Map.  A MappableI can be
compared to an other MappableI using boolean methods.

=cut


# Let the code begin...

package Bio::Map::FPCMarker;
use vars qw(@ISA);
use strict;
use Bio::Root::Root;
use Bio::Map::MappableI;
use Bio::Map::Position;
use Time::Local;

@ISA = qw(Bio::Root::Root Bio::Map::MappableI);


=head2 new

 Title   : new
 Usage   : my $clone = Bio::Map::FPCMarker->new
                      (
		       -name    => $marker,
		       -type    => $type,
		       -global  => $global,
		       -frame   => $frame,
		       -group   => $group,
		       -subgroup=> $subgroup,
		       -anchor  => $anchor,
		       -clones  => \%clones,
		       -contigs => \%contigs,
		       -position => \%markerpos
		       );

 Function: Initialize a new Bio::Map::FPCMarker object
           Most people will not use this directly but get Markers
           through L<Bio::MapIO::fpc>
 Returns : L<Bio::Map::FPCMarker> object
 Args    :    -name => marker name string,
	      -type    => type string,
	      -global  => global position for marker,
	      -frame   => boolean if marker is framework or placement,
	      -group   => group number for marker,
	      -subgroup=> subgroup number of marker,
	      -anchor  => boolean if marker is anchored,
	      -clones  => all the clone elements in map (hashref),
	      -contigs => all the contig elements (hasref),
	      -position => mapping of marker names to map position (hasref),

=cut

sub new {
   my ($class,@args) = @_;
   my $self= $class->SUPER::new(@args);

   my ($name,$type,$global,$frame,$group,
       $subgroup, $anchor, $clones,$contigs,
       $positions) = $self->_rearrange([qw(NAME TYPE FRAME
					   GROUP SUBGROUP ANCHOR
					   CLONES CONTIGS POSITIONS)],@args);

   $self->name($name)                  if defined $name;
   $self->type($type)                  if defined $type;
   $self->global($global)              if defined $global;
   $self->group($group)                if defined $group;
   $self->subgroup($group)             if defined $subgroup;
   $self->anchor($anchor)              if defined $anchor;

   $self->set_clones($clones)          if defined $clones;
   $self->set_contigs($contigs)        if defined $contigs;
   $self->set_positions($positions)    if defined $positions;

   return $self;
}

=head1 Access Methods

These methods let you get and set the member variables

=head2 name

 Title   : name
 Usage   : my $name = $markerobj->name();
 Function: get the name for this marker
 Returns : scalar representing the current name of this marker
 Args    : none

=cut

sub name {
    my ($self) = shift;
    return $self->{'_name'} = shift if @_;
    return $self->{'_name'};
}

=head2 type

 Title   : type
 Usage   : my $type = $markerobj->type();
 Function: get the type for this marker
 Returns : scalar representing the current type of this marker
 Args    : none

=cut

sub type {
    my ($self) = shift;
    return $self->{'_type'} = shift if @_;
    return $self->{'_type'};
}


=head2 global

 Title   : global
 Usage   : my $type = $markerobj->global();
 Function: get the global position for this marker
 Returns : scalar representing the current global position of this marker
 Args    : none

=cut


sub global {
    my ($self) = shift;
    return $self->{'_global'} = shift if @_;
    return $self->{'_global'};
}

=head2 anchor

 Title   : anchor
 Usage   : my $anchor = $markerobj->anchor();
 Function: indicate if the Marker is anchored or not (True | False)
 Returns : scalar representing the anchor (1 | 0) for this marker
 Args    : none

=cut

sub anchor {
    my ($self) = shift;
    return $self->{'_anchor'} = shift if @_;
    return $self->{'_anchor'};
}


=head2 framework

 Title   : framework
 Usage   : $frame = $markerobj->framework();
 Function: indicate if the Marker is framework or placement (1 | 0)
 Returns : scalar representing if the marker is framework
           (1 if framework, 0 if placement)
 Args    : none

=cut

sub framework {
    my ($self) = shift;
    return $self->{'_frame'} = shift if @_;
    return $self->{'_frame'};
}


=head2 group

 Title   : group
 Usage   : $grpno = $markerobj->group();
 Function: get the group number for this marker. This is a
           generic term, used for Linkage-Groups as well as
	   for Chromosomes.
 Returns : scalar representing the group number of this marker
 Args    : none

=cut


sub group {
    my ($self) = shift;
    $self->{'_group'} = shift if @_;
    return $self->{'_group'} || 0;
}

=head2 subgroup

 Title   : subgroup
 Usage   : $subgroup = $marker->subgroup();	
 Function: get the subgroup for this marker. This is a
           generic term: subgroup here could represent subgroup
	   of a Chromosome or of a Linkage Group
	   The user must take care of which subgroup he/she is
           querying for.	
 Returns : scalar representing the subgroup of this marker
 Args    : none

=cut

sub subgroup {
    my ($self) = shift;
    $self->{'_subgroup'} = shift if @_;
    return $self->{'_subgroup'} || 0;
}



=head2 position

 Title   : position
 Usage   : $markerpos = $markerobj->position($ctg);
 Function: get the position of the marker in the contig
 Returns : scalar representing the position of the markernumber of
           the contig
 Args    : $ctg is necessary to look for the position of the marker
           in that contig.

=cut

sub position {
    my ($self,$ctg) = @_;
    return 0 unless defined $ctg;

    return 0 unless( defined defined $self->{'_position'} &&
		     defined $self->{'_position'}{$ctg});
    return $self->{'_position'}{$ctg};
}

=head2 each_I<E<lt>elementE<gt>>id

 Title   : each_<element>id
 Usage   : my @clones  = $markerobj->each_cloneid();
 	   my @contigs = $markerobj->each_contigid();
 Function: retrieves all the elements in a map unordered
 Returns : list of Bio::Map::MappableI ids (names)
 Args    : type of elements you want (clones, contigs)

=cut

sub each_cloneid{
    my ($self) = @_;
    return $self->_each_element('clones');
}

sub each_contigid{
    my ($self) = @_;
    return $self->_each_element('contigs');
}

sub _each_element{
    my ($self, $type) = @_;

    $type = 'clones' unless defined $type;
    $type = lc("_$type");

    return keys %{$self->{$type} || {}};
}

=head2 set_clones

 Title   : set_clones
 Usage   : $marker->set_clones(\%clones)
 Function: Set the clones hashref
 Returns : None
 Args    : Hashref of clone names to clones


=cut

sub set_clones{
   my ($self,$clones) = @_;
   if( defined $clones && ref($clones) =~ /HASH/ ) {
       $self->{'_clones'} = $clones;
   }
}

=head2 set_contigs

 Title   : set_contigs
 Usage   : $marker->set_contigs(\%contigs)
 Function: Set the contigs hashref
 Returns : None
 Args    : Hashref of contig names to contigs


=cut

sub set_contigs{
   my ($self,$contigs) = @_;
   if( defined $contigs && ref($contigs) =~ /HASH/ ) {
       $self->{'_contigs'} = $contigs;
   }
}

=head2 set_positions

 Title   : set_positions
 Usage   : $marker->set_positions(\%markerpos)
 Function: Set the positions hashref
 Returns : None
 Args    : Hashref of marker positions


=cut

sub set_positions{
   my ($self,$pos) = @_;
   if( defined $pos && ref($pos) =~ /HASH/ ) {
       $self->{'_positions'} = $pos;
   }
}

1;


=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to the
Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org              - General discussion
  http://bioperl.org/MailList.shtml  - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via the
web:

  http://bugzilla.bioperl.org/

=head1 AUTHOR - Gaurav Gupta

Email gaurav@genome.arizona.edu

=head1 PROJECT LEADERS

Jamie Hatfield            jamie@genome.arizona.edu

Dr. Cari Soderlund        cari@genome.arizona.edu

=head1 PROJECT DESCRIPTION

The project was done in Arizona Genomics Computational Laboratory (AGCoL)
at University of Arizona.

This work was funded by USDA-IFAFS grant #11180 titled "Web Resources for
the Computation and Display of Physical Mapping Data".

For more information on this project, please refer:
  http://www.genome.arizona.edu

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut
