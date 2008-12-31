#!perl
package MUD;

=head1 NAME

MUD - "multi-user dungeon" framework

=head1 SYNOPSIS

  package MyInputState;
  use base 'MUD::Input::State';

  sub run { "You are in a MUD!" }

  package main;
  use MUD::Server;

  MUD::Server->new(starting_state => MyInputState->new)->run;

Basically, you have your L<MUD::Player>, L<MUD::Input::State>,
L<MUD::Universe>, and, most importantly, your L<MUD::Server>.

=head1 THE SERVER

The server that runs the MUD (L<MUD::Server>) uses POE for its socket system and
Moose for its object system. 

=head1 THE UNIVERSE

Your MUD will contain a universe (L<MUD::Universe>). This is mainly for
things that are pertinent to the game's environment.

=head1 INPUT STATES

Your MUD will require input from your users for things other than game
commands such as entering a name and passowrd. See L<MUD::Input::States>
for more details.

=head1 AUTHOR

Jason May <jason dot a dot may at gmail dot com>

=cut

1;

