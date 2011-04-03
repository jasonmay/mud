#!/usr/bin/env perl
package MUD::Universe;
use Moose;

has players => (
    is      => 'ro',
    isa     => 'HashRef[MUD::Player]',
    default => sub { +{} },
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

MUD::Universe - the MUD's universe data

=head1 SYNOPSIS

  my $universe = MUD::Universe->new(
      spawn_player_code => sub {
          MUD::Player->new(...);
      },
  );

