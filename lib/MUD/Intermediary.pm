#!/usr/bin/env perl
package MUD::Intermediary;
use MooseX::POE;
use namespace::autoclean;

use JSON;

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

has controller_connected => (
    is  => 'rw',
    isa => 'Bool',
    default => 0
);

has socket_info => (
    is  => 'rw',
    isa => 'HashRef[Int]',
    default => sub { +{} },
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
        Port               => $self->controller_port,
        ClientConnected    => sub { _controller_client_accept($self) },
        ClientDisconnected => sub { _controller_server_error($self)  },
        ClientInput        => sub { _controller_client_input($self)  },
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
    $rw->put("Hey.\n");
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
    $self->rw_set->{$wheel_id}->put(
        to_json({param => 'disconnect', data => $wheel_id})
        );
}

#TODO send backup info
sub _controller_client_accept {
    my $self = shift;
    warn "[controller] connect";

    if ( scalar(%{$self->rw_set}) ) {
        $_[HEAP]->{server}->put( to_json({param => 'restore', data => }) );
    }
}

sub _controller_server_error {
    my $self = shift;
    warn "[controller] disconnect";
    $_->put("The MUD will be back up shortly.") for @{$self->rw_set};
}

sub _controller_client_input {
    my $self = shift;
    my $input = $_[ARG0];
    chomp($input);
    warn "[controller] got input: $input";
    my $json = eval { from_json($input) };

    if ($@) {
        warn "JSON error: $@";
    }
    elsif ( any { !exists($json->{$_}) } qw(output socket) ) {
        warn "Invalid JSON structure!";
    }
    else {
        $self->rw_set->{ $json->{id} }->put( $json->{output} );
        if ($json->{updates}) {
            foreach my $key  (%{ $json->{updates} }) {
                my $value = $json->{updates}->{$key};
                $self->socket_info->{ $json->{id} }->{ $key } = $value
            }
        }
    }
}

sub run {
    my $self = shift;
    POE::Kernel->run();
}

event START                => \&_player_start;

event player_client_accept => \&_player_client_accept;
event player_server_error  => \&_player_server_error;
event player_client_input  => \&_player_client_input;
event player_client_error  => \&_player_client_error;

event controller_client_input   => \&_controller_client_input;
event controller_client_accept  => \&_controller_client_accept;
event controller_client_error   => \&_controller_client_error;

__PACKAGE__->meta->make_immutable;

1;
