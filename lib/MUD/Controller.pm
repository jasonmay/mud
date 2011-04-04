#!perl
package MUD::Controller;
use Moose;
use Class::MOP ();
extends 'IO::Multiplex::Intermediary::Client';

use constant connection_class => 'MUD::Connection';

has universe => (
    is => 'rw',
    isa => 'MUD::Universe',
    required => 1,
);

has input_states => (
    is      => 'ro',
    isa     => 'HashRef[MUD::Input::State]',
    traits  => ['Hash'],
    handles => {
        set_input_state  => 'set',
        get_input_state  => 'get',
        has_input_states => 'count',
    },
);

has connections => (
    is => 'ro',
    isa => 'HashRef[MUD::Connection]',
    traits  => ['Hash'],
    handles => {
        add_connection  => 'set',
        connection      => 'get',
        has_connections => 'count',
    },
);

around build_response => sub {
    my $orig     = shift;
    my $self     = shift;
    my ($wheel_id, $input, $txn_id) = @_;

    my $conn = $self->connection($wheel_id);

    if (!$conn) {
        warn "Attempt to get response from non-existent connection";
        return '';
    }

    return '' unless $conn->input_state;
    return $conn->input_state->run(
        $self,
        $conn,
        $self->$orig(@_),
        $txn_id,
    );
};

around connect_hook => sub {
    my $orig   = shift;
    my $self   = shift;
    my $data   = shift;

    my $id = $data->{data}->{id};
    Class::MOP::load_class($self->connection_class);
    my $conn = $self->new_connection;

    $self->add_connection($id => $conn);

    # XXX used to spawn_player_code here - probably won't be using that'
    #     anymore...?

    return $self->$orig($data, @_);
};

around disconnect_hook => sub {
    my $orig   = shift;
    my $self   = shift;
    my $data   = shift;

    my $id = $data->{data}->{id};
    $self->connection($id)->disconnect();

    return $self->$orig($data, @_);
};

sub new_connection { $_[0]->connection_class->new }

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

