#!perl
package MUD::Controller;
use IO::Socket;
use POE qw(Component::Client::TCP Wheel::ReadWrite);
use Moose;
use namespace::autoclean;
use MUD::Player;
use MUD::Input::State;
use MUD::Universe;
use JSON;
use Carp;
use DDS;

local $| = 1;

has socket => (
    is       => 'rw',
    isa      => 'POE::Wheel::ReadWrite',
    clearer  => 'clear_socket',
);

has host => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => 'localhost',
);

has port => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    default => 9000
);

has starting_state => (
    is       => 'rw',
    isa      => 'MUD::Input::State',
);

has universe => (
    is => 'rw',
    isa => 'MUD::Universe',
    required => 1,
);

sub BUILD {
    my $self = shift;
    $self->_mud_start;
}

sub mud_message {
    return unless $ENV{MUD_DEBUG} && $ENV{MUD_DEBUG} > 0;
    my $self = shift;
    my $msg = shift;
    print STDERR sprintf("\e[0;33m[MUD]\e[m ${msg}\n", @_);
}

sub custom_startup { }

# start the server
sub _mud_start {
    my ($self) = @_;
    POE::Component::Client::TCP->new(
        RemoteAddress   => $self->host,
        RemotePort      => $self->port,
        Connected       => sub { _server_connect($self,    @_) },
        Disconnected    => sub { _server_disconnect($self, @_) },
        ServerInput     => sub { _server_input($self,      @_) },
    );

    $self->custom_startup(@_);
}

# handle client input
sub _server_connect {
    my $self = shift;
    $self->mud_message("Connected");
    $self->socket($_[HEAP]{server});
};

# handle client input
sub _server_disconnect {
    my $self = shift;
    $self->clear_socket;
    delete $_[HEAP]{server};
};

# handle client input
sub _server_input {
    my $self = shift;
    my ($input) = $_[ARG0];
    $input =~ s/[\r\n]*$//;
    $_[HEAP]{server}->put($self->parse_json($input));
};

sub _response {
    my $self     = shift;
    my $wheel_id = shift;
    my $input    = shift;
    my $player   = $self->universe->players->{$wheel_id};

    if (!$player) {
        warn "Attempt to get response from non-existent player";
        return '';
    }

    return '' unless @{$player->input_state};
    return $player->input_state->[0]->run($player, $input);
}

sub perform_connect_action {
    my $self   = shift;
    my $data   = shift;

    warn "perform_connect_action";
    my $id = $data->{data}->{id};
    my $player = $self->universe->players->{$id}
                = $self->universe->spawn_player_code->($self->universe, $id);

    return to_json({param => 'null'});
}

sub perform_input_action {
    my $self   = shift;
    my $data   = shift;

    warn "perform_input_action";
    return to_json(
        {
            param => 'output',
            data => {
                value => $self->_response(
                    $data->{data}->{id},
                    $data->{data}->{value}
                ),
                id => $data->{data}->{id},
            }
        }
    );
}

sub perform_disconnect_action {
    my $self   = shift;
    my $data   = shift;

    my $id = $data->{data}->{id};
    my $player = delete $self->universe->players->{$id};

    return to_json(
        {
            param => 'disconnect',
            data  => {
                success => 1,
            },
        }
    );
}

sub parse_json {
    my $self = shift;
    my $json = shift;
    my $data = eval { from_json($json) };

    if ($@) { warn $@; return }

    my %actions = (
        'connect'    => sub { $self->perform_connect_action($data)    },
        'input'      => sub { $self->perform_input_action($data)      },
        'disconnect' => sub { $self->perform_disconnect_action($data) },
    );

    return $actions{ $data->{param} }->()
        if exists $actions{ $data->{param} };


    return to_json({param => 'null'});
}

sub force_disconnect {
    my $self = shift;
    my $id = shift;
    my %args = @_;

    $self->socket->put(to_json(
        {
            param => 'disconnect',
            data => {
                id => $id,
                %args,
            }
        }
    ));
}

sub send {
    my $self = shift;
    my ($id, $message) = @_;

    $self->socket->put(to_json(
        {
            param => 'output',
            data => {
                value => $message,
                id => $id,
            }
        }
    ));
}


sub run {
    my $self = shift;
    POE::Kernel->run();
}

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

=cut

__PACKAGE__->meta->make_immutable;

1;
