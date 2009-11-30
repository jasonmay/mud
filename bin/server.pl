#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use MUD::Server;

my $mud = MUD::Server->new;

$mud->run;
