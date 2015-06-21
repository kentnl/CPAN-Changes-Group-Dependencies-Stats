use strict;
use warnings;

use Test::More;

# FILENAME: attach.t
# CREATED: 07/24/14 17:13:46 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test attaching data to a release
use CPAN::Changes;

BEGIN {
  my $sample_version = '0.400002';
  my $sample         = <<'EOF';
1.7.5 2013-08-01T09:48:11Z
 [Group]
 - Child Entry Line 1
 - Child Entry Line 2
EOF

  return if CPAN::Changes->load_string($sample)->serialize eq $sample;
  plan
    skip_all => sprintf "Serialization scheme of CPAN::Changes %s is different to that of %s",
    $CPAN::Changes::VERSION, $sample_version;
}
use Test::Differences qw( eq_or_diff );
use CPAN::Changes::Group::Dependencies::Stats;
use CPAN::Changes::Release;

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

