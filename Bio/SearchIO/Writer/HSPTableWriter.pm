=head1 NAME

Bio::SearchIO::Writer::HSPTableWriter - Tab-delimited data for Bio::Search::HSP::HSPI objects

=head1 SYNOPSIS

=head2 Example 1: Using the default columns

    use Bio::SearchIO;
    use Bio::SearchIO::Writer::HSPTableWriter;

    my $in = Bio::SearchIO->new();

    my $writer = Bio::SearchIO::Writer::HSPTableWriter->new();

    my $out = Bio::SearchIO->new( -writer => $writer );

    while ( my $result = $in->next_result() ) {
        $out->write_result($result, ($in->report_count - 1 ? 0 : 1) );
    }

=head2 Example 2: Specifying a subset of columns 

    use Bio::SearchIO;
    use Bio::SearchIO::Writer::HSPTableWriter;

    my $in = Bio::SearchIO->new();

    my $writer = Bio::SearchIO::Writer::HSPTableWriter->new( 
                                  -columns => [qw(
                                                  query_name
                                                  query_length
                                                  hit_name
                                                  hit_length
                                                  rank
                                                  frac_identical_query
                                                  expect
                                                  )]  );

    my $out = Bio::SearchIO->new( -writer => $writer,
				  -file   => ">searchio.out" );

    while ( my $result = $in->next_result() ) {
        $out->write_result($result, ($in->report_count - 1 ? 0 : 1) );
    }

=head2 Custom Labels

You can also specify different column labels if you don't want to use
the defaults.  Do this by specifying a C<-labels> hash reference
parameter when creating the HSPTableWriter object.  The keys of the
hash should be the column number (left-most column = 1) for the label(s)
you want to specify. Here's an example:

    my $writer = Bio::SearchIO::Writer::HSPTableWriter->new( 
                               -columns => [qw( query_name 
                                                query_length
                                                hit_name
                                                hit_length  )],
                               -labels  => { 1 => 'QUERY_GI',
  	                                     3 => 'HIT_IDENTIFIER' } );


=head1 DESCRIPTION

Bio::SearchIO::Writer::HSPTableWriter generates output at the finest
level of granularity for data within a search result. Data for each HSP
within each hit in a search result is output in tab-delimited format,
one row per HSP.

=head2 Available Columns

Here are the columns that can be specified in the C<-columns>
parameter when creating a HSPTableWriter object.  If a C<-columns> parameter
is not specified, this list, in this order, will be used as the default.

    query_name
    query_length
    hit_name
    hit_length
    round
    rank
    expect
    score
    bits
    frac_identical_query
    frac_identical_hit
    frac_conserved_query
    frac_conserved_hit
    length_aln_query
    length_aln_hit
    gaps_query
    gaps_hit
    gaps_total
    start_query
    end_query
    start_hit
    end_hit
    strand_query
    strand_hit
    frame
    hit_description
    query_description

For more details about these columns, see the documentation for the
corresponding method in Bio::Search::HSP::HSPI.

=head1 AUTHOR

Steve Chervitz <steve_chervitz@affymetrix.com>

=head1 SEE ALSO

    Bio::SearchIO::Writer::HitTableWriter
    Bio::SearchIO::Writer::ResultTableWriter

=head1 METHODS

=cut

package Bio::SearchIO::Writer::HSPTableWriter;

use strict;
use Bio::SearchIO::Writer::ResultTableWriter;

use vars qw( @ISA );
@ISA = qw( Bio::SearchIO::Writer::ResultTableWriter );


# Array fields: column, object, method[/argument], printf format, column label
# Methods for result object are defined in Bio::Search::Result::ResultI.
# Methods for hit object are defined in Bio::Search::Hit::HitI.
# Methods for hsp object are defined in Bio::Search::HSP::HSPI.
# Tech note: If a bogus method is supplied, it will result in all values to be zero.
#            Don't know why this is.
# TODO (maybe): Allow specification of signif_format (i.e., separate mantissa/exponent)
my %column_map = (
                  'query_name'            => ['1', 'result', 'query_name', 's', 'QUERY' ],
                  'query_length'          => ['2', 'result', 'query_length', 'd', 'LEN_Q'],
                  'hit_name'              => ['3', 'hit', 'hit_name', 's', 'HIT'],
                  'hit_length'            => ['4', 'hit', 'hit_length', 'd', 'LEN_H'],
                  'round'                 => ['5', 'hit', 'psiblast_round', 'd', 'ROUND', 'hit'],
                  'rank'                  => ['6', 'hsp', 'rank', 'd', 'RANK'],
                  'expect'                => ['7', 'hsp', 'expect', '.1e', 'EXPCT'],
                  'score'                 => ['8', 'hsp', 'score', 'd', 'SCORE'],
                  'bits'                  => ['9', 'hsp', 'bits', 'd', 'BITS'],
                  'frac_identical_query'  => ['10', 'hsp', 'frac_identical/query', '.2f', 'FR_IDQ'],
                  'frac_identical_hit'    => ['11', 'hsp', 'frac_identical/hit', '.2f', 'FR_IDH'],
                  'frac_conserved_query'  => ['12', 'hsp', 'frac_conserved/query', '.2f', 'FR_CNQ'],
                  'frac_conserved_hit'    => ['13', 'hsp', 'frac_conserved/hit', '.2f', 'FR_CNH'],
                  'length_aln_query'      => ['14', 'hsp', 'length/query', 'd', 'LN_ALQ'],
                  'length_aln_hit'        => ['15', 'hsp', 'length/hit', 'd', 'LN_ALH'],
                  'gaps_query'            => ['16', 'hsp', 'gaps/query', 'd', 'GAPS_Q'],
                  'gaps_hit'              => ['17', 'hsp', 'gaps/hit', 'd', 'GAPS_H'],
                  'gaps_total'            => ['18', 'hsp', 'gaps/total', 'd', 'GAPS_QH'],
                  'start_query'           => ['19', 'hsp', 'start/query', 'd', 'START_Q'],
                  'end_query'             => ['20', 'hsp', 'end/query', 'd', 'END_Q'],
                  'start_hit'             => ['21', 'hsp', 'start/hit', 'd', 'START_H'],
                  'end_hit'               => ['22', 'hsp', 'end/hit', 'd', 'END_H'],
                  'strand_query'          => ['23', 'hsp', 'strand/query', 'd', 'STRND_Q'],
                  'strand_hit'            => ['24', 'hsp', 'strand/hit', 'd', 'STRND_H'],
                  'frame'                 => ['25', 'hsp', 'frame', 's', 'FRAME'],
                  'hit_description'       => ['26', 'hit', 'hit_description', 's', 'DESC_H'],
                  'query_description'     => ['27', 'result', 'query_description', 's', 'DESC_Q'],
                 );

sub column_map { return %column_map }


=head2 to_string()

Note: this method is not intended for direct use. 
The SearchIO::write_result() method calls it automatically 
if the writer is hooked up to a SearchIO object as illustrated in 
the L<SYNOPSIS> section.

 Title     : to_string()
           :
 Usage     : print $writer->to_string( $result_obj, [$include_labels] );
           :
 Argument  : $result_obj = A Bio::Search::Result::ResultI object
           : $include_labels = boolean, if true column labels are included (default: false)
           :
 Returns   : String containing tab-delimited set of data for each HSP
           : in each Hit of the supplied ResultI object. 
           :
 Throws    : n/a
=cut

sub to_string {
    my ($self, $result, $include_labels) = @_;

    my $str = $include_labels ? $self->column_labels() : '';
    my $func_ref = $self->row_data_func;
    my $printf_fmt = $self->printf_fmt;

    foreach my $hit($result->hits) {
	foreach my $hsp($hit->hsps) {
	    my @row_data  = &{$func_ref}($result, $hit, $hsp);
	    $str .= sprintf "$printf_fmt\n", @row_data;
	}
    }
    $str =~ s/\t\n/\n/gs;
    return $str;
}


1;
