#!perl
package MUD::Controller;
use Moose;
extends 'IO::Multiplex::Intermediary::Client';

has starting_state => (
    is       => 'rw',
    isa      => 'MUD::Input::State',
);

has universe => (
    is => 'rw',
    isa => 'MUD::Universe',
    required => 1,
);

sub mud_message {
    return unless $ENV{MUD_DEBUG} && $ENV{MUD_DEBUG} > 0;
    my $self = shift;
    my $msg = shift;
    print STDERR sprintf("\e[0;33m[MUD]\e[m ${msg}\n", @_);
}

around build_response => sub {
    my $orig     = shift;
    my $self     = shift;
    my $wheel_id = shift;
    my $input    = shift;
    my $player   = $self->universe->players->{$wheel_id};

    if (!$player) {
        warn "Attempt to get response from non-existent player";
        return '';
    }

    return '' unless @{$player->input_state};
    return $player->input_state->[0]->run(
        $player,
        $self->$orig($wheel_id, $input, @_),
    );
};

around connect_hook => sub {
    my $orig   = shift;
    my $self   = shift;
    my $data   = shift;

    my $id = $data->{data}->{id};
    my $player = $self->universe->players->{$id}
                = $self->universe->spawn_player_code->($self->universe, $id);

    return $self->$orig($data, @_);
};

around disconnect_hook => sub {
    my $orig   = shift;
    my $self   = shift;
    my $data   = shift;

    my $id = $data->{data}->{id};
    my $player = delete $self->universe->players->{$id};

    return $self->$orig($data, @_);
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

MUD::Controller - Logic that coordinates gameplay and I/O

=head1 SYNOPSIS

  my $controller = MUD::Controller->new(
      universe => $universe,
  );

=head1 DESCRIPTION

The flow of the controller starts when a player sends a command.
The controller figures out who sent the command and relays it to
the logic that reads the command and comes up with a response (Game).

  Server <---> Controller <---> Game

=head1 ATTRIBUTES

=over

=item host

This attribute is for the host the server runs on.

=item port

This attribute is for the host the server runs on.

=item universe

This is a MUD::Universe object the controller has access to
for actual game interaction.

=back

=head1 METHODS

=over

=item run

=item custom_startup

=item send

=back

