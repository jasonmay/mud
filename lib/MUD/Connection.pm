package MUD::Connection;
use Moose;

use Data::UUID::LibUUID;

has name => (
    is  => 'rw',
    isa => 'Str'
);

has input_states => (
    is   => 'rw',
    isa  => 'ArrayRef[MUD::Input::State]',
    lazy => 1,
    builder => '_build_input_states',
);

sub _build_input_states { [] }

has markings => (
    is => 'ro'
);

has associated_player => (
    is  => 'ro',
    isa => 'Maybe[MUD::Player]',
);

sub input_state { $_[0]->input_states->[0] }

sub disconnect {
    my $self = shift;
    my $txn_id;
    $txn_id = shift || new_uuid_string();

    return unless $self->id;

    $self->universe->_controller->force_disconnect($self->id, $txn_id, @_);
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
