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

sub disconnect {
    my $self = shift;
    my %args = @_;

    return unless $self->id;

    $self->universe->_controller->force_disconnect($self->id, @_);
}

=head1 NAME

MUD::Player - the player that logs in

=head1 SYNOPSIS

  my $player = MUD::Player->new(
      name => 'jasonmay',
      input_state => [
          $login_state,
      ],
  );

=cut

1;
