# The Advanced page of the General Settings
use strict;
use warnings;
our (%gui, %signal, %vmc);

sub init_edit_gen_advanced {
    set_pointer($gui{d}{Edit}{dialog});
    my $vhost = vhost();
    combobox_set_active_text($gui{d}{Edit}{cboxGenClip}, IMachine_getClipboardMode($vmc{IMachine}), 1);

    if ($$vhost{autostartdb}) {
        $gui{d}{Edit}{cboxGenAutostop}->set_sensitive(1);
        $gui{d}{Edit}{checkGenAutostart}->set_sensitive(1);
        $gui{d}{Edit}{sbGenAutostart}->set_sensitive(1);
        combobox_set_active_text($gui{d}{Edit}{cboxGenAutostop}, IMachine_getAutostopType($vmc{IMachine}), 1);
        $gui{d}{Edit}{checkGenAutostart}->set_active(bl(IMachine_getAutostartEnabled($vmc{IMachine})));
        $gui{d}{Edit}{sbGenAutostart}->set_value(IMachine_getAutostartDelay($vmc{IMachine}));
    }
    else {
        $gui{d}{Edit}{cboxGenAutostop}->set_sensitive(0);
        $gui{d}{Edit}{checkGenAutostart}->set_sensitive(0);
        $gui{d}{Edit}{sbGenAutostart}->set_sensitive(0);
    }

    $gui{d}{Edit}{entryGenSnapfolder}->signal_handler_block($signal{Edit_entryGenSnapfolder_activate});
    $gui{d}{Edit}{entryGenSnapfolder}->signal_handler_block($signal{Edit_entryGenSnapfolder_focus});
    $gui{d}{Edit}{entryGenSnapfolder}->set_text(IMachine_getSnapshotFolder($vmc{IMachine}));
    $gui{d}{Edit}{entryGenSnapfolder}->signal_handler_unblock($signal{Edit_entryGenSnapfolder_activate});
    $gui{d}{Edit}{entryGenSnapfolder}->signal_handler_block($signal{Edit_entryGenSnapfolder_focus});
    set_pointer($gui{d}{Edit}{dialog});
}

# Sets the name of the snapshot folder
sub gen_snapfolder {
    if ($vmc{SessionType} eq 'WriteLock') {
        IMachine_setSnapshotFolder($vmc{IMachine}, $gui{d}{Edit}{entryGenSnapfolder}->get_text());
        return 0;
    }
}

# Sets the clipboard sharing mode
sub gen_adv_clipboard {
    IMachine_setClipboardMode($vmc{IMachine}, getsel_combo($gui{d}{Edit}{cboxGenClip}, 1));
    return 0;
}

# Set the guest to autostart on host boot
sub gen_adv_autostart { IMachine_setAutostartEnabled($vmc{IMachine}, $gui{d}{Edit}{checkGenAutostart}->get_active()); }

# Set the guest's autostop type
sub gen_adv_autostop_mode {
    IMachine_setAutostopType($vmc{IMachine}, getsel_combo($gui{d}{Edit}{cboxGenAutostop}, 1));
    return 0;
}

# Set the autostart delay in seconds
sub gen_adv_autostart_delay {
    IMachine_setAutostartDelay($vmc{IMachine}, $gui{d}{Edit}{sbGenAutostart}->get_value_as_int());
    return 0; # Must return this value for the signal used.
}

1;
