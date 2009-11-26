#!perl
package MUD::Controller;
use IO::Socket;
use POE qw(Component::Client::TCP Wheel::ReadWrite);
use MooseX::POE;
use namespace::autoclean;
use MUD::Player;
use MUD::Input::State;
use MUD::Universe;
use JSON;
use DDS;

local $| = 1;

has socket => (
    is       => 'rw',
    isa      => 'POE::Wheel::ReadWrite',
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

sub mud_message {
    return unless $ENV{MUD_DEBUG} && $ENV{MUD_DEBUG} > 0;
    my $self = shift;
    my $msg = shift;
    print STDERR sprintf("\e[0;33m[MUD]\e[m ${msg}\n", @_);
}

# start the server
sub _mud_start {
    my ($self) = @_;
    POE::Component::Client::TCP->new(
        RemoteAddress   => $self->host,
        RemotePort      => $self->port,
        Connected       => sub { _server_connect($self,    @_) },
        Disconnected    => sub { _server_disconnect($self, @_) },
        ServerInput     => sub { _server_input($self,      @_) },
    )
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
    $self->socket(undef);
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

    return '' unless @{$player->input_state};
    return $player->input_state->[0]->run($player, $input);
}

sub perform_connect_action {
    my $self   = shift;
    my $data   = shift;

    my $id = $data->{data}->{id};
    my $player = $self->universe->players->{$id}
                = $self->universe->spawn_player($id);

    return to_json({param => 'null'});
}

sub perform_input_action {
    my $self   = shift;
    my $data   = shift;

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

    delete $self->universe->players->{ $data->{data}->{id} };
    return to_json({param => 'null'});
}

sub parse_json {
    my $self = shift;
    my $json = shift;
    my $data = eval { from_json($json) };

    if ($@) { warn $@; return }

    my %actions = (
        'connect'   => sub { $self->perform_connect_action($data)    },
        'input'     => sub { $self->perform_input_action($data)      },
        'disconect' => sub { $self->perform_disconnect_action($data) },
    );

    return $actions{ $data->{param} }->()
        if exists $actions{ $data->{param} };

    return to_json({param => 'null'});
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

event START => \&_mud_start;

sub run {
    my $self = shift;
    POE::Kernel->run();
}

=head1 NAME

MUD::Controller - controls the MUD

=head1 SYNOPSIS

  # see MUD::Input::State for information on input-states
  my $starting_state = My::Input::State::Subclass->new;
  MUD::Controller->new(starting_state => $starting_state);

=head1 DESCRIPTION

XXX THESE DOCS ARE OUTDATED

MUD::Controller is the class you run in order for your MUD to
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

  package MyMUD::Controller;
  use base 'MUD::Controller';

  sub spawn_player {
      my $self = shift;
      return MyMUD::Player->new(
          input_state => [$self->starting_state]
      );
  }

  ...

=back

=cut

__PACKAGE__->meta->make_immutable;

1;
