# -*-Perl-*- Test Harness script for Bioperl
# $Id$

use strict;

BEGIN {
    use lib '.';
    use Bio::Root::Test;
    
    test_begin(-tests => 30);
	
	use_ok('Bio::Root::Root');
    use_ok('Bio::Seq');
}

ok my $obj = Bio::Root::Root->new();
isa_ok($obj, 'Bio::Root::RootI');

eval { $obj->throw('Testing throw') };
ok $@ =~ /Testing throw/;# 'throw failed';

# doesn't work in perl 5.00405
#my $val;
#eval {
#    my ($tfh,$tfile) = $obj->tempfile();
#    local * STDERR = $tfh;
#    $obj->warn('Testing warn');
#    close $tfh;    
#    open(IN, $tfile) or die("cannot open $tfile");    
#    $val = join("", <IN>) ;
#    close IN;
#    unlink $tfile;
#};
#ok $val =~ /Testing warn/;
#'verbose(0) warn did not work properly' . $val;

$obj->verbose(-1);
eval { $obj->throw('Testing throw') };
ok $@=~ /Testing throw/;# 'verbose(-1) throw did not work properly' . $@;

eval { $obj->warn('Testing warn') };
ok !$@;

$obj->verbose(1);
eval { $obj->throw('Testing throw') };
ok $@ =~ /Testing throw/;# 'verbose(1) throw did not work properly' . $@;

# doesn't work in perl 5.00405
#undef $val;
#eval {
#    my ($tfh,$tfile) = $obj->tempfile();
#    local * STDERR = $tfh;
#    $obj->warn('Testing warn');
#    close $tfh;
#    open(IN, $tfile) or die("cannot open $tfile");    
#    $val = join("", <IN>);
#    close IN;
#    unlink $tfile;
#};
#ok $val =~ /Testing warn/;# 'verbose(1) warn did not work properly' . $val;

my @stack = $obj->stack_trace();
is scalar @stack, 2;

my $verbobj = Bio::Root::Root->new(-verbose=>1,-strict=>1);
is $verbobj->verbose(), 1;

$Bio::Root::Root::DEBUG = 1;
my $seq = Bio::Seq->new();
is $seq->verbose, 1;

# test for bug #1343
my @vals = Bio::Root::RootI->_rearrange([qw(apples pears)], 
					-apples => 'up the',
					-pears  => 'stairs');
eval { $obj->throw_not_implemented() };
ok $@ =~ /Bio::Root::NotImplemented/;

is shift @vals, 'up the';
is shift @vals, 'stairs';

# tests for _set_from_args()
# Let's not pollute Bio::Root::Root namespace if possible
# Create temp classes instead which inherit Bio::Root::Root, then test

package Bio::Foo1;
use base qw(Bio::Root::Root);
sub new {
		my $class = shift;
		my $self = {};
		bless $self, ref($class) || $class;
	
		$self->_set_from_args(\@_);
		
		return $self;
	};

package main;

$obj = Bio::Foo1->new(-verbose => 1, t1 => 1, '--Test-2' => 2);
ok ! $obj->can('t1'), 'arg not callable';

package Bio::Foo2;
use base qw(Bio::Root::Root);
sub new {
		my $class = shift;
		my $self = {};
		bless $self, ref($class) || $class;
	
		$self->_set_from_args(\@_, -create => 1);
		
		return $self;
	};

package main;

$obj = Bio::Foo2->new(-verbose => 1, t3 => 1, '--Test-4' => 2);
ok $obj->can('t3'), 'arg callable since method was created';
ok $obj->can('test_4'), 'mal-formed arg callable since method was created with good name';
for my $m (qw(t3 test_4)) {
    ok (UNIVERSAL::can('Bio::Foo2',$m), "Methods in new package/class namespace");
    ok (!UNIVERSAL::can('Bio::Root::Root',$m), "Methods don't pollute original Bio::Root::Root namespace");
}

package Bio::Foo3;
use base qw(Bio::Root::Root);
sub new {
		my $class = shift;
		my $self = {};
		bless $self, ref($class) || $class;
	
		$self->_set_from_args(\@_, -methods => ['verbose', 't5'], -create => 1);
		
		return $self;
	};

package main;

$obj = Bio::Foo3->new(-verbose => 1, t5 => 1, '--Test-6' => 2);
ok $obj->can('t5'), 'arg callable since method was created';
ok ! $obj->can('test_6'), 'arg not in method list not created';

ok (UNIVERSAL::can('Bio::Foo3','t5'), "Methods in new package/class namespace");
ok (!UNIVERSAL::can('Bio::Root::Root','t5'), "Methods don't pollute original Bio::Root::Root namespace");

package Bio::Foo4;
use base qw(Bio::Root::Root);
sub new {
		my $class = shift;
		my $self = {};
		bless $self, ref($class) || $class;
		
		my %args = @_;
		
		$self->_set_from_args(\%args, -methods => {(verbose => 'v',
									         		test7 => 't7',
													test_8 => 't8')},
								      -create => 1);
		
		return $self;
	};

# with synonyms
package main;

$obj = Bio::Foo4->new(-verbose => 1, t7 => 1, '--Test-8' => 2);
is $obj->verbose, 1, 'verbose was set correctly';
is $obj->t7, 1, 'synonym was set correctly';
is $obj->test7, 1, 'real method of synonym was set correctly';
is $obj->test_8, 2, 'mal-formed arg correctly resolved to created method';
is $obj->t8, 2, 'synonym of set method was set correctly';

for my $m (qw()) {
    ok (!UNIVERSAL::can('Bio::Foo4','t7'), "Methods in new package/class namespace");
    ok (!UNIVERSAL::can('Bio::Root::Root','t7'), "Methods don't pollute original Bio::Root::Root namespace");
}

