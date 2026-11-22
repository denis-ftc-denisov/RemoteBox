# The Description page of the General Settings
use strict;
use warnings;
our (%gui, %vmc);

sub init_edit_gen_description {
    &set_pointer($gui{d}{Edit}{dialog}, 'watch');
    $gui{d}{Edit}{tbGenDescription}->set_text(IMachine_getDescription($vmc{IMachine}));
    &set_pointer($gui{d}{Edit}{dialog});
}

# Sets the guest's description
sub gen_description {
    my $iter_s = $gui{d}{Edit}{tbGenDescription}->get_start_iter();
    my $iter_e = $gui{d}{Edit}{tbGenDescription}->get_end_iter();
    IMachine_setDescription($vmc{IMachine}, $gui{d}{Edit}{tbGenDescription}->get_text($iter_s, $iter_e, 0));
    return 0;
}

1;
