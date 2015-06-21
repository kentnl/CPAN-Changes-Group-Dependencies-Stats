use strict;
use warnings;

use Test::More;

# FILENAME: attach.t
# CREATED: 07/24/14 17:13:46 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test attaching data to a release
use Test::Differences qw( eq_or_diff );

use CPAN::Changes::Group::Dependencies::Stats;
use CPAN::Changes;
use CPAN::Changes::Release;

my $sample = <<'EOF';
1.7.5 2013-08-01T09:48:11Z
 [Group]
 - Child Entry Line 1
 - Child Entry Line 2
EOF

if ( CPAN::Changes->load_string( $sample )->serialize ne $sample ) {
  plan skip_all => "Serialization scheme of CPAN::Changes $CPAN::Changes::VERSION is different to that of 0.30";
}


my $release = CPAN::Changes::Release->new(
  version => '0.01',
  date    => '2009-07-06',

);

my $stats = CPAN::Changes::Group::Dependencies::Stats->new(
  old_prereqs => {},
  new_prereqs => { runtime => { requires => { 'Moo' => 2 } } },
);

my $other_stats = CPAN::Changes::Group::Dependencies::Stats->new(
  name        => "Other::Name",
  old_prereqs => {},
  new_prereqs => {},
);

$release->attach_group($stats)       if $stats->has_changes;
$release->attach_group($other_stats) if $other_stats->has_changes;

my $string = $release->serialize;

eq_or_diff $string, <<'EOF', 'Serialize as expected';
0.01 2009-07-06
 [Dependencies::Stats]
 - runtime: +1

EOF

done_testing;

