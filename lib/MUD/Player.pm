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

has io => (
    is      => 'rw',
    isa     => 'POE::Wheel::ReadWrite',
);

sub disconnect {
    my $self = shift;
    $self->io->shutdown_output;
}

=head1 NAME

MUD::Player - a player XXX TODO FIXME

=head1 DESCRIPTION

This class is a XXX oh shit I don't know if it's possible to override the
player!

=cut

1;
