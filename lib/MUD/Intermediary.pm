#!/usr/bin/env perl
package MUD::Intermediary;
use MooseX::POE;
use namespace::autoclean;

use POE qw(
    Wheel::SocketFactory
    Component::Server::TCP
    Wheel::ReadWrite
    Filter::Stream
);

has player_sockets => (
    is  => 'rw',
    isa => 'POE::Wheel::SocketFactory',
);

has rw_set => (
    is => 'rw',
    isa => 'HashRef[Int]',
    default => sub { +{} },
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

sub _player_start {
    my ($self) = @_;
    $self->player_sockets(
        POE::Wheel::SocketFactory->new(
            BindPort     => $self->player_port,
            SuccessEvent => 'player_client_accept',
            FailureEvent => 'player_server_error',
            Reuse        => 'yes',
        )
    );

    POE::Component::Server::TCP->new(
        Port            => $self->controller_port,
        ClientConnected => \&_controller_client_accept,
        ClientDisconnected => \&_controller_server_error,
        ClientInput     => \&_controller_client_input,
    )
}

sub _player_client_accept {
    my ($self) = @_;
    my $socket = $_[ARG0];
    my $rw = POE::Wheel::ReadWrite->new(
        Handle     => $socket,
        Driver     => POE::Driver::SysRW->new,
        Filter     => POE::Filter::Stream->new,
        InputEvent => 'player_client_input',
        ErrorEvent => 'player_client_error',
    );

    my $wheel_id = $rw->ID;
    $self->rw_set->{$wheel_id} = $rw;
    warn "[player] ($wheel_id) connect";
}

#TODO clean shutdown etc
sub _player_server_error {
    my ($self) = @_;
    my ($operation, $errnum, $errstr) = @_[ARG0, ARG1, ARG2];
    warn "[SERVER] $operation error $errnum: $errstr";
}

sub _player_client_input {
    my ($self)             = @_;
    my ($input, $wheel_id) = @_[ARG0, ARG1];
    $input =~ s/[\r\n]*$//;

    $self->rw_set->{$wheel_id}->put(join('', sort split '', $input) . "\n");
    warn "[player] ($wheel_id) got input: $input";
}

#TODO let abermud know
sub _player_client_error {
    my ($self)   = @_;
    my $wheel_id = $_[ARG3];
    delete $self->rw_set->{$wheel_id};
    warn "[player] ($wheel_id) disconnect";
}

sub _controller_client_accept {
    my ($self)   = @_;
    warn "[controller] connect";
}

sub _controller_server_error {
    my ($self)   = @_;
    warn "[controller] disconnect";
}

sub _controller_client_input {
    my ($self)  = @_;
    my $input = $_[ARG0];
    chomp($input);
    $_[HEAP]->{client}->put("wheee\n");
    warn "[controller] got input: $input";
}

sub run {
    my $self = shift;
    POE::Kernel->run();
}

event START            => \&_player_start;
event player_client_accept => \&_player_client_accept;
event player_server_error  => \&_player_server_error;
event player_client_input  => \&_player_client_input;
event player_client_error  => \&_player_client_error;

event controller_client_input  => \&_controller_client_input;
event controller_client_accept  => \&_controller_client_accept;
event controller_client_error  => \&_controller_client_error;

__PACKAGE__->meta->make_immutable;

1;
