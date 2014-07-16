use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package CPAN::Changes::Group::Dependencies::Stats;

our $VERSION = '0.001000';

# ABSTRACT: Create a Dependencies::Stats section detailing summarised differences

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo;
use CPAN::Meta::Prereqs::Diff;
use MooX::Lsub qw( lsub );

lsub new_prereqs => sub { die 'Required attribute <new_prereqs> was not provided' };
lsub old_prereqs => sub { die 'Required attribute <old_prereqs> was not provided' };
lsub prereqs_diff => sub {
  my ($self) = @_;
  return CPAN::Meta::Prereqs::Diff->new(
    new_prereqs => $self->new_prereqs,
    old_prereqs => $self->old_prereqs,
  );
};

my $sym_add = '+';
my $sym_upg = '↑';
my $sym_dwn = '↓';
my $sym_rmv = '-';

sub _phase_rel_changes {
  my ( $self, $phase, $rel, $phases ) = @_;
  return unless exists $phases->{$phase};
  return unless exists $phases->{$phase}->{$rel};

  my $stash = $phases->{$phase}->{$rel};

  my @parts;
  if ( $stash->{Added} > 0 ) {
    push @parts, $sym_add . $stash->{Added};
  }
  if ( $stash->{Upgrade} > 0 ) {
    push @parts, $sym_upg . $stash->{Upgrade};
  }
  if ( $stash->{Downgrade} > 0 ) {
    push @parts, $sym_dwn . $stash->{Downgrade};
  }
  if ( $stash->{Removed} > 0 ) {
    push @parts, $sym_rmv . $stash->{Removed};
  }
  return unless @parts;
  return join q[ ], @parts;
}

sub _phase_changes {
  my ( $self, $phase, $phases ) = @_;

  my @out;
  my @extra;

  if ( my $recommends = $self->_phase_rel_changes( $phase, 'recommends', $phases ) ) {
    push @extra, 'recommends: ' . $recommends;
  }
  if ( my $suggested = $self->_phase_rel_changes( $phase, 'suggests', $phases ) ) {
    push @extra, 'suggests: ' . $suggested;
  }

  if ( my $required = $self->_phase_rel_changes( $phase, 'requires', $phases ) ) {
    push @out, $required;
  }
  if (@extra) {
    push @out, sprintf '(%s)', join q[, ], @extra;
  }
  if (@out) {
    return sprintf '%s: %s', $phase, join q[ ], @out;
  }
  return;
}

sub _phase_rel_stats {
  my ($self)  = @_;
  my (@diffs) = $self->prereqs_diff->diff(
    phases => [qw( configure build runtime test develop )],
    types  => [qw( requires recommends suggests conflicts )],
  );
  my $phases = {};
  for my $diff (@diffs) {
    my $phase_m = $diff->phase;

    my $rel = $diff->type;

    if ( not exists $phases->{$phase_m} ) {
      $phases->{$phase_m} = {};
    }
    if ( not exists $phases->{$phase_m}->{$rel} ) {
      $phases->{$phase_m}->{$rel} = { Added => 0, Upgrade => 0, Downgrade => 0, Removed => 0, Changed => 0 };
    }
    my $stash = $phases->{$phase_m}->{$rel};

    $stash->{Added}++   if $diff->is_addition;
    $stash->{Removed}++ if $diff->is_removal;
    if ( $diff->is_change ) {
      $stash->{Upgrade}++   if $diff->is_upgrade;
      $stash->{Downgrade}++ if $diff->is_downgrade;
      if ( not $diff->is_upgrade and not $diff->is_downgrade ) {
        $stash->{Changed}++;
      }
    }
  }
  return $phases;
}

sub changes {
  my ($self) = @_;
  my @changes = ();

  my $phases = $self->_phase_rel_stats;

  for my $phase ( sort keys %{$phases} ) {
    push @changes, $self->_phase_changes( $phase, $phases );
  }
  return \@changes;
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Changes::Group::Dependencies::Stats - Create a Dependencies::Stats section detailing summarised differences

=head1 VERSION

version 0.001000

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
