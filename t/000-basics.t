#!perl
use strict;
use warnings;
use Test::More tests => 17;

BEGIN {
    use_ok 'MUD::Server';
    use_ok 'MUD::Player';
    use_ok 'MUD::Input::State';
}

can_ok 'MUD::Server', 'new';
can_ok 'MUD::Server', 'run';
can_ok 'MUD::Server', 'port';
can_ok 'MUD::Server', 'welcome_message';
can_ok 'MUD::Server', 'mud_start';
can_ok 'MUD::Server', 'mud_client_accept';
can_ok 'MUD::Server', 'mud_server_error';
can_ok 'MUD::Server', 'mud_client_input';
can_ok 'MUD::Server', 'mud_client_error';

can_ok 'MUD::Player', 'new';
can_ok 'MUD::Player', 'input_state';
can_ok 'MUD::Player', 'name';

can_ok 'MUD::Input::State', 'new';
can_ok 'MUD::Input::State', 'run';
