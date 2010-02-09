#!/usr/bin/env perl
package MUD::Input::State;
use Moose;

sub run { die "This method must be overwritten" }

has 'universe' => (
    is       => 'rw',
    isa      => 'MUD::Universe',
);

__PACKAGE__->meta->make_immutable;

=head1 NAME

MUD::Input::State - base class of where the player I/O fun happens

=head1 SYNOPSIS

  package MyInputState;
  use base 'MUD::Input::State';

  sub run {
      my $self     = shift;
      my $you      = shift; # MUD::Player doing the invoking
      my $input    = shift; # The input provided

      ...

      # whatever is returned gets sent to the player
      return "whatever was done with the input";
  }

=head1 DESCRIPTION

This class is a base class with a single method "run" that
needs to be overridden. The superclass is used throughout
the MUD distribution. For example, MUD::Player has an
B<input_states> accessor. The server uses the last element
in that list. MUD::Server also requires it for the 
B<starting_state> parameter so the player has a state to
start out with.

=head1 EXAMPLES

=over

=item *

B<entering a name, password, etc.>

If you want to do something along the lines of "Enter your name"
then "Enter your password", you'd write a MUD::Input::State super-
class for each one.

To traverse through input states, you simple push whatever new input
state you want the player to use next to the invoker's input_states
stack in the B<run> method, like so:

  push @{$you->input_states}, MyInputState::EnterPassword->new;

=item *

Game play

For playing in the game where you use commands in a common realm,
you would make one super-class for that. It is up to you to do your
own command dispatching.

=item *

Sub-menus

Sometimes mid-game, you may want to have the user go into a sub-menu,
whether it is for entering a shop and choosing what to buy or setting
spells and things of that nature, you'd push a new input state from
the game-play input state. It should then be popped from the player's
input_states stack when the users wishes to exit that sub-menu so the
player can cleanly return to playing the game normally.

=cut

1;
