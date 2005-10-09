# $Id$
#
# BioPerl module for Bio::TreeIO::newick
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::TreeIO::newick - TreeIO implementation for parsing 
  Newick/New Hampshire/PHYLIP format.

=head1 SYNOPSIS

  # do not use this module directly
  use Bio::TreeIO;
  my $treeio = new Bio::TreeIO(-format => 'newick', 
                               -file => 't/data/LOAD_Ccd1.dnd');
  my $tree = $treeio->next_tree;

=head1 DESCRIPTION

This module handles parsing and writing of Newick/PHYLIP/New Hampshire format.

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

=head1 AUTHOR - Jason Stajich

Email jason@bioperl.org

Describe contact details here

=head1 CONTRIBUTORS

Additional contributors names and emails here

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::TreeIO::newick;
use vars qw(@ISA $DefaultBootstrapStyle);
use strict;

use Bio::TreeIO;
use Bio::Event::EventGeneratorI;

#initialize some package variables, could use 'our' but fails in perl < 5.6

$DefaultBootstrapStyle = 'traditional';
@ISA = qw(Bio::TreeIO );


=head2 new

 Title   : new
 Args    : -print_count => boolean  default is false

=cut

sub _initialize { 
    my $self = shift;
    $self->SUPER::_initialize(@_);
    my ($print_count,$style) = $self->_rearrange([qw(PRINT_COUNT 
						   BOOTSTRAP_STYLE)],
					  @_);
    $self->print_tree_count($print_count || 0);
    $self->bootstrap_style($style || $DefaultBootstrapStyle);
    return;
}


=head2 next_tree

 Title   : next_tree
 Usage   : my $tree = $treeio->next_tree
 Function: Gets the next tree in the stream
 Returns : L<Bio::Tree::TreeI>
 Args    : none


=cut

sub next_tree{
   my ($self) = @_;
   local $/ = ";\n";
   return unless $_ = $self->_readline;
   s/[\r\n]//gs;
   my $despace = sub {my $dirty = shift; $dirty =~ s/\s+//gs; return $dirty};
   my $dequote = sub {my $dirty = shift; $dirty =~ s/^"?\s*(.+?)\s*"?$/$1/; return $dirty};
   s/([^"]*)(".+?")([^"]*)/$despace->($1) . $dequote->($2) . $despace->($3)/egsx;

   $self->debug("entry is $_\n");
#   my $empty = chr(20);
 
   # replace empty labels with a tag
#   s/\(,/\($empty,/ig;
#   s/,,/,$empty,/ig;
#   s/,,/,/ig;
#   s/,\)/,$empty\)/ig;
#   s/\"/\'/ig;

   my $chars = '';
   $self->_eventHandler->start_document;
   my ($prev_event,$lastevent,$id) = ('','','');
   foreach my $ch ( split(//,$_) ) {
       if( $ch eq ';' ) {
	   return $self->_eventHandler->end_document($chars);
       } elsif( $ch eq '(' ) {
	   $chars = '';
	   $self->_eventHandler->start_element( {'Name' => 'tree'} );
       } elsif($ch eq ')' ) {
	   if( length($chars) ) {
	       if( $lastevent eq ':' ) {
		   $self->_eventHandler->start_element( { 'Name' => 'branch_length'});
		   $self->_eventHandler->characters($chars);
		   $self->_eventHandler->end_element( {'Name' => 'branch_length'});
		   $lastevent = $prev_event;
	       } else { 
		   $self->debug("internal node, id with no branchlength is $chars\n");
		   $self->_eventHandler->start_element( { 'Name' => 'node' } );
		   $self->_eventHandler->start_element( { 'Name' => 'id' } );
		   $self->_eventHandler->characters($chars);
		   $self->_eventHandler->end_element( { 'Name' => 'id' } );
		   $id = $chars;
	       }
	       my $leafstatus = 0;
	       if( $lastevent ne ')' ) {
		   $leafstatus = 1;
	       }

	       $self->_eventHandler->start_element({'Name' => 'leaf'});
	       $self->_eventHandler->characters($leafstatus);
	       $self->_eventHandler->end_element({'Name' => 'leaf'});
	       $id = '';
	   } else {
	       $self->_eventHandler->start_element( {'Name' => 'node'} );
	   }

 	   $self->_eventHandler->end_element( {'Name' => 'node'} );
	   $self->_eventHandler->end_element( {'Name' => 'tree'} );
	   $chars = '';
       } elsif ( $ch eq ',' ) {
	   if( length($chars) ) {
	       if( $lastevent eq ':' ) {
		   $self->_eventHandler->start_element( { 'Name' => 'branch_length'});
		   $self->_eventHandler->characters($chars);
		   $self->_eventHandler->end_element( {'Name' => 'branch_length'});
		   $lastevent = $prev_event;
		   $chars = '';		   
	       } else { 
		   $self->debug("leaf id with no branchlength is $chars\n");
		   $self->_eventHandler->start_element( { 'Name' => 'node' } );
		   $self->_eventHandler->start_element( { 'Name' => 'id' } );
		   $self->_eventHandler->characters($chars);
		   $self->_eventHandler->end_element( { 'Name' => 'id' } );
		   $id = $chars;
	       }
	   } else {
	       $self->_eventHandler->start_element( { 'Name' => 'node' } );
	   }
	   my $leafstatus = 0;
	   if( $lastevent ne ')' ) {
	       $leafstatus = 1;
	   }
	   $self->_eventHandler->start_element({'Name' => 'leaf'});
	   $self->_eventHandler->characters($leafstatus);
	   $self->_eventHandler->end_element({'Name' => 'leaf'});
	   $self->_eventHandler->end_element( {'Name' => 'node'} );
	   $chars = '';
	   $id    = '';
       } elsif( $ch eq ':' ) {
	   $self->debug("id with a branchlength coming is $chars\n");
	   $self->_eventHandler->start_element( { 'Name' => 'node' } );
	   $self->_eventHandler->start_element( { 'Name' => 'id' } );	   
	   $self->_eventHandler->characters($chars);
	   $self->_eventHandler->end_element( { 'Name' => 'id' } );	   
	   $id = $chars;
	   $chars = '';
       } else { 	   
	   $chars .= $ch;
	   next;
       }
       $prev_event = $lastevent;
       $lastevent = $ch;
   }
   return undef;
}

=head2 write_tree

 Title   : write_tree
 Usage   : $treeio->write_tree($tree);
 Function: Write a tree out to data stream in newick/phylip format
 Returns : none
 Args    : L<Bio::Tree::TreeI> object

=cut

sub write_tree{
   my ($self,@trees) = @_;      
   if( $self->print_tree_count ){ 
       $self->_print(sprintf(" %d\n",scalar @trees));
   }
   foreach my $tree( @trees ) {
       my @data = _write_tree_Helper($tree->get_root_node,
				     $self->bootstrap_style);
       #if($data[-1] !~ /\)$/ ) {
	#   $data[0] = "(".$data[0];
	#   $data[-1] .= ")";
       #}
       $self->_print(join(',', @data), ";\n");   
   }
   $self->flush if $self->_flush_on_write && defined $self->_fh;
   return;
}

sub _write_tree_Helper {
    my ($node,$style) = @_;
    $style = '' unless defined $style;
    return () if (!defined $node);

    my @data;
    
    foreach my $n ( $node->each_Descendent() ) {
	push @data, _write_tree_Helper($n,$style);
    }
    
    # let's explicitly write out the bootstrap if we've got it
    my $id = $node->id_output;
    my $bs = $node->bootstrap; # bs better not have any spaces?
    $bs =~ s/\s+//g if defined $bs;
    my $bl = $node->branch_length;
    if( @data ) {
	$data[0] = "(" . $data[0];
	$data[-1] .= ")";

	if( $node->is_Leaf ) { 
	    $node->debug("node is a leaf!  This is unexpected...");

	    $id ||= '';
	    if( ! defined $bl || ! length($bl) ||
		($style && $style =~ /nobranchlength/i) ) {
		$data[-1] .= $id;
	    } elsif( defined $bl && length($bl) ) { 
		$data[-1] .= "$id:$bl";
	    } else { 
		$data[-1] .= $id;
	    }
	} else { 
	    if( ! defined $bl || ! length($bl) ||
		($style && $style =~ /nobranchlength/i) ) {
		
		if( defined $id || defined $bs ) {
		    $data[-1] .= defined $bs ? $bs : $id;
		}
	    } elsif( $style =~ /molphy/i ) {
		if( defined $id ) {
		    $data[-1] .= $id;
		}
		if( $bl =~ /\#/) {
		    $data[-1] .= $bl;
		} else { 
		    $data[-1] .= ":$bl";
		}
		if( defined $bs ) { 
		    $data[-1] .= "[$bs]";
		}
	    } else {
		# traditional style of 
		# ((A:1,B:2)81:3);   where 3 is internal node branch length
		#                    and 81 is bootstrap/node label
		if( defined $bs || defined $id ) {
		    $data[-1] .= defined $bs ? "$bs:$bl" : "$id:$bl";
		} elsif( $bl =~ /\#/ ) {
		    $data[-1] .= $bl;
		} else { 
		    $data[-1] .= ":$bl"; 
		}
	    }
	}
    } elsif( defined $id || defined $bl ) {
	my $str;
	$id ||= '';
	if( ! defined $bl || ! length($bl) ||
	    ($style && $style =~ /nobranchlength/i) ) {
	    $str = $id;
	} elsif( defined $bl && length($bl) ) { 
	    $str = "$id:$bl";
	} else { 
	    $str = $id;
	}
	push @data, $str;
    }
    return @data;
}

=head2 print_tree_count

 Title   : print_tree_count
 Usage   : $obj->print_tree_count($newval)
 Function: Get/Set flag for printing out the tree count (paml,protml way)
 Returns : value of print_tree_count (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub print_tree_count{
    my $self = shift;
    return $self->{'_print_tree_count'} = shift if @_;
    return $self->{'_print_tree_count'} || 0;
}

=head2 bootstrap_style

 Title   : bootstrap_style
 Usage   : $obj->bootstrap_style($newval)
 Function: A description of how bootstraps and branch lengths are
           written, as the ID part of the internal node or else in []
           in the branch length (Molphy-like; I'm sure there is a
           better name for this but am not sure where to go for some
           sort of format documentation)

           If no branch lengths are requested then no bootstraps are usually
           written (unless someone REALLY wants this functionality...)

           Can take on strings which contain the possible values of
           'nobranchlength'   --> don't draw any branch lengths - this
                                  is helpful if you don't want to have to 
                                  go through and delete branch len on all nodes
           'molphy' --> draw bootstraps (100) like
                                  (A:0.11,B:0.22):0.33[100];
           'traditional' --> draw bootstraps (100) like
                                  (A:0.11,B:0.22)100:0.33;
 Returns : value of bootstrap_style (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub bootstrap_style{
    my $self = shift;
    my $val = shift;
    if( defined $val ) {

	if( $val !~ /^nobranchlength|molphy|traditional/i ) {
	    $self->warn("requested an unknown bootstrap style $val, expect one of nobranchlength,molphy,traditional, not updating value.  Default is $DefaultBootstrapStyle\n");
	} else { 
	    $self->{'_bootstrap_style'} = $val;
	}
    }
    return $self->{'_bootstrap_style'} || $DefaultBootstrapStyle;
}


1;
