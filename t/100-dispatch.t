#!perl
use Test::More tests => 2;
use MUD::Player;

{
    package MyInputState::Second;
    use Moose;
    extends 'MUD::Input::State';

    sub run {
        return "stuff happened";
    }
}

{
    package MyInputState::First;
    use Moose;
    extends 'MUD::Input::State';

    sub run {
        my $self = shift;
        my $player = shift;
        chomp(my $name = shift);

        push @{$player->input_state}, MyInputState::Second->new;

        return "your name is $name";
    }
}

my $player = MUD::Player->new;
push @{$player->input_state}, MyInputState::First->new;

my $input = 'jasonmay'; # user enters their name
is($player->input_state->[-1]->run($player, $input), "your name is $input");

$input = 'foo';
is($player->input_state->[-1]->run($player, $input), "stuff happened");
