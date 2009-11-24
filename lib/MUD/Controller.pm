#!perl
package MUD::Controller;
use IO::Socket;
use POE qw(Component::Client::TCP);
use MooseX::POE;
use namespace::autoclean;
use MUD::Player;
use MUD::Input::State;
use MUD::Universe;
use JSON;

local $| = 1;

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

has welcome_message => (
    is      => 'rw',
    isa     => 'Str',
    default => 'Enter your name: '
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
        Connected       => sub { _mud_client_connect($self) },
        ServerInput     => sub { _mud_client_input($self) },
    )
}

# handle client input
sub _mud_client_connect {
    warn "Connected";
};

# handle client input
sub _mud_client_input {
    my ($self) = @_;
    my ($input) = $_[ARG0];
    $input =~ s/[\r\n]*$//;
    $_[HEAP]->{server}->put($self->parse_json($input));
};

sub parse_json {
    return to_json(
        {
            output => 'hai',
            updates => {
                foo => 1,
                bar => 2
            }
        }
    );
}

event START              => \&_mud_start;
#event mud_client_connect => \&_mud_client_connect;
#event mud_server_error   => \&_mud_server_error;
event mud_client_input   => \&_mud_client_input;
#event mud_client_error   => \&_mud_client_error;

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
