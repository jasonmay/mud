#!/usr/bin/env perl
package MUD::Universe;
use Moose;
use namespace::autoclean;
use MUD::Player;

has players => (
    is  => 'rw',
    isa => 'HashRef[MUD::Player]',
    default => sub { +{} },
);

has spawn_player_code => (
    is => 'ro',
    isa => 'CodeRef',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

1;

