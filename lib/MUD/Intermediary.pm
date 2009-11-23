#!/usr/bin/env perl
package MUD::Intermediary;
use MooseX::POE;
use namespace::autoclean;

use POE qw(Wheel::SocketFactory Wheel::ReadWrite);

has controller_socket => (
    is  => 'ro',
    isa => 'IO::Socket::INET',
    builder => '_build_controller_socket',
);

sub _build_controller_socket {
    my $self = shift;
    return IO::Socket::INET->new(
        Listen    => 5,
        Reuse     => 1,
        LocalPort => $self->controller_port,
    );
}

has player_sockets => (
    is  => 'rw',
    isa => 'POE::Wheel::SocketFactory',
);

has player_port => (
    is  => 'ro',
    isa => 'Int',
    default => 6715
);

has controller_port => (
    is  => 'ro',
    isa => 'Int',
    default => 9000
);

sub game_start {
    my ($self) = @_;
    $self->player_sockets(
        POE::Wheel::SocketFactory->new(
            BindPort     => $self->player_port,
            SuccessEvent => 'game_client_accept',
            FailureEvent => 'game_server_error',
        )
    );
}

sub game_client_accept {

}

sub game_server_error {

}

sub game_client_input {

}

sub game_client_error {

}

sub run {
    my $self = shift;
    POE::Kernel->run();
}

event START            => \&game_start;
event on_client_accept => \&game_client_accept;
event on_server_error  => \&game_server_error;
event on_client_input  => \&game_client_input;
event on_client_error  => \&game_client_error;

__PACKAGE__->meta->make_immutable;

1;
