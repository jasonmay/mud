#!/usr/bin/env perl
package MUD::Universe;
use Moose;

has players => (
    is  => 'rw',
    isa => 'HashRef[MUD::Player]',
    default => sub { +{} },
);

1;

