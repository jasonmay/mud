package MUD::Player;
use Moose;

# mark & sweep style actions,
# like saving, types of output,
# disconnecting, etc.
has markings => (
    is      => 'ro',
    isa     => 'HashRef',
    traits  => ['Hash'],
    handles => {
        mark => 'set',
    },
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;
