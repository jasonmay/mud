#!/usr/bin/env perl
package MUD::Player;
use Moose;
use MUD::Input::State;

has name => (
    is  => 'rw',
    isa => 'Str'
);

has input_state => (
    is      => 'rw',
    isa     => 'ArrayRef[MUD::Input::State]',
    default => sub { [] },
);

# TODO
sub disconnect {
    my $self = shift;
    my %args = @_;

    return unless $self->id;

    $self->universe->_controller->force_disconnect($self->id, @_);
}

=head1 NAME

MUD::Player - a player XXX TODO FIXME

=head1 DESCRIPTION

This class is a XXX oh shit I don't know if it's possible to override the
player!

=cut

1;
