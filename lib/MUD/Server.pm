#!perl
package MUD::Server;
use IO::Socket;
use POE qw(Wheel::SocketFactory Wheel::ReadWrite Filter::Stream Driver::SysRW);
use MooseX::POE;
use MUD::Player;
use MUD::Input::State;
use MUD::Universe;

local $| = 1;

has port => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    default => 6715
);

#has connections => (
#    is      => 'rw',
#    isa     => 'HashRef[MUD::Player]',
#    default => sub { +{} }
#);

has starting_state => (
    is       => 'rw',
    isa      => 'MUD::Input::State',
    required => 1
);

has welcome_message => (
    is      => 'rw',
    isa     => 'Str',
    default => 'Enter your name: '
);

has universe => (
    is => 'rw',
    isa => 'MUD::Universe',
    default => sub { MUD::Universe->new }
);

sub mud_message {
    return unless $ENV{'MUD_DEBUG'} > 0;
    my $self = shift;
    my $msg = shift;
    print STDERR sprintf("\e[0;33m[MUD]\e[m ${msg}\n", @_);
}

# sub that can be overridden so the user can use their own
# MUD::Player super-class
sub spawn_player {
    my $self = shift;
    return MUD::Player->new(input_state => [$self->starting_state]);
}

# Start the server.
sub mud_start {
    my ($self) = @_;
    $_[HEAP]{server} = POE::Wheel::SocketFactory->new(
        BindPort => $self->port,
        SuccessEvent => "on_client_accept",
        FailureEvent => "on_server_error",
        Reuse        => 'yes',
    );
};

# Begin interacting with the client.
sub mud_client_accept {
    my ($self) = @_;
    my $client_socket = $_[ARG0];
    my $io_wheel = POE::Wheel::ReadWrite->new(
        Handle => $client_socket,
        Driver => POE::Driver::SysRW->new(),
        Filter => POE::Filter::Stream->new(),
        InputEvent => "on_client_input",
        ErrorEvent => "on_client_error",
    );
    $_[HEAP]{client}{ $io_wheel->ID() } = $io_wheel;
    my $id = $io_wheel->ID();
    $self->mud_message("Connection [%d] :)", $id);
    $self->universe->players->{$id} = $self->spawn_player($id, $self->universe);
    $self->universe->players->{$id}->io($io_wheel);
    $_[HEAP]{client}{$id}->put($self->welcome_message);
};

# Shut down server.
sub mud_server_error {
    my ($self) = @_;
    my ($operation, $errnum, $errstr) = @_[ARG0, ARG1, ARG2];
    $self->mud_message("Server $operation error $errnum: $errstr\n");
    delete $_[HEAP]{server};
};

sub _response {
    my $self     = shift;
    my $wheel_id = shift;
    my $input    = shift;
    my $player = $self->universe->players->{$wheel_id};

    return '' unless @{$player->input_state};
    return $player->input_state->[0]->run($player, $input);
}

# Handle client input.
sub mud_client_input {
    my ($self) = @_;
    my ($input, $wheel_id) = @_[ARG0, ARG1];
    my $player = $self->universe->players->{$wheel_id};
    $input =~ s/[\r\n]*$//;
    $_[HEAP]{client}{$wheel_id}->put($self->_response($wheel_id, $input));
};

# Handle client error, including disconnect.
sub mud_client_error {
    my ($self) = @_;
    my $wheel_id = $_[ARG3];
    delete $_[HEAP]{client}{$wheel_id};
    $self->mud_message("Disconnection [%d] :(", $wheel_id);
};

event START            => \&mud_start;
event on_client_accept => \&mud_client_accept;
event on_server_error  => \&mud_server_error;
event on_client_input  => \&mud_client_input;
event on_client_error  => \&mud_client_error;

sub run {
    my $self = shift;
    POE::Kernel->run();
}

=head1 NAME

MUD::Server - the core class for running your MUD

=head1 SYNOPSIS

  # see MUD::Input::State for information on input-states
  my $starting_state = My::Input::State::Subclass->new;
  MUD::Server->new(starting_state => $starting_state);

=head1 DESCRIPTION

MUD::Server is the class you run in order for your MUD to
run. It can be subclassed to override a few methods:

=over

=item *

spawn_player

This method originally looks like this:

  sub spawn_player {
      my $self = shift;
      return MUD::Player->new(
          input_state => [$self->starting_state]
      );
  }

The reason you would override this is to let the server know
that you have a MUD::Player subclass:

  package MyMUD::Server;
  use base 'MUD::Server';

  sub spawn_player {
      my $self = shift;
      return MyMUD::Player->new(
          input_state => [$self->starting_state]
      );
  }

  ...

=back

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

1;
