#!/usr/bin/env perl
package MUD::Universe;
use Moose;
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

# sub that can be overridden so the user can use their own
# MUD::Player super-class
sub spawn_player {
    my $self = shift;
    my $player = $self->spawn_player_code->($self, @_);
    return $player;
}

1;

