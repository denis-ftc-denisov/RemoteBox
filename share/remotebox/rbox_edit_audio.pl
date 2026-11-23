# Edit Audio Settings of a Guest
use strict;
use warnings;
our (%gui, %signal, %vmc);

# Initialise the audio page
sub init_edit_audio {
    &set_pointer($gui{d}{Edit}{dialog}, 'watch');
    my $vhost = &vhost();
    $gui{d}{Edit}{cboxAudioDriver}->signal_handler_block($signal{Edit_cboxAudioDriver_changed});
    $gui{d}{Edit}{cboxAudioController}->signal_handler_block($signal{Edit_cboxAudioController_changed});
    $gui{d}{Edit}{cboxAudioCodec}->signal_handler_block($signal{Edit_cboxAudioCodec_changed});
    $gui{d}{Edit}{checkAudio}->set_active(&bl(IAudioAdapter_getEnabled($vmc{IAudioAdapter})));

    # Ghost / Unghost other widgets based on online editing and whether audio is enabled or not.
    if ($vmc{SessionType} eq 'WriteLock') {
        $gui{d}{Edit}{gridAudioTop}->set_sensitive($gui{d}{Edit}{checkAudio}->get_active());
        $gui{d}{Edit}{gridAudioBottom}->set_sensitive($gui{d}{Edit}{checkAudio}->get_active());
    } else {
        $gui{d}{Edit}{gridAudioTop}->set_sensitive(0); # Ghost/Unghost other widgets based on audio enabled
        $gui{d}{Edit}{gridAudioBottom}->set_sensitive($gui{d}{Edit}{checkAudio}->get_active());
    }

    $gui{d}{Edit}{checkAudioInput}->set_active(&bl(IAudioAdapter_getEnabledIn($vmc{IAudioAdapter})));
    $gui{d}{Edit}{checkAudioOutput}->set_active(&bl(IAudioAdapter_getEnabledOut($vmc{IAudioAdapter})));

    # Set WinMM, MMPM and SolAudio to Null as they no longer seem supported and cause problems if set.
    my $AudioDriver = IAudioAdapter_getAudioDriver($vmc{IAudioAdapter});
    IAudioAdapter_setAudioDriver($vmc{IAudioAdapter}, 'Null') if ($AudioDriver =~ /^(?:WinMM|MMPM|SolAudio)$/);

    if ($$vhost{os} =~ m/Linux/i) { $gui{d}{Edit}{cboxAudioDriver}->set_model($gui{liststoreEditAudioDriverLin}); }
    elsif ($$vhost{os} =~ m/Windows/i) { $gui{d}{Edit}{cboxAudioDriver}->set_model($gui{liststoreEditAudioDriverWin}); }
    elsif ($$vhost{os} =~ m/SunOS/i) { $gui{d}{Edit}{cboxAudioDriver}->set_model($gui{liststoreEditAudioDriverSol}); }
    elsif ($$vhost{os} =~ m/Darwin/i) { $gui{d}{Edit}{cboxAudioDriver}->set_model($gui{liststoreEditAudioDriverMac}); }
    elsif ($$vhost{os} =~ m/FreeBSD/i) { $gui{d}{Edit}{cboxAudioDriver}->set_model($gui{liststoreEditAudioDriverFreeBSD}); }
    else { $gui{d}{Edit}{cboxAudioDriver}->set_model($gui{liststoreEditAudioDriverOther}); }

    my $controller =  IAudioAdapter_getAudioController($vmc{IAudioAdapter});
    $gui{d}{Edit}{cboxAudioCodec}->set_model($gui{'liststoreEditAudioCodec' . $controller});
    &combobox_set_active_text($gui{d}{Edit}{cboxAudioCodec}, IAudioAdapter_getAudioCodec($vmc{IAudioAdapter}), 1);
    &combobox_set_active_text($gui{d}{Edit}{cboxAudioDriver}, IAudioAdapter_getAudioDriver($vmc{IAudioAdapter}), 1);
    &combobox_set_active_text($gui{d}{Edit}{cboxAudioController}, $controller, 1);
    $gui{d}{Edit}{cboxAudioDriver}->signal_handler_unblock($signal{Edit_cboxAudioDriver_changed});
    $gui{d}{Edit}{cboxAudioController}->signal_handler_unblock($signal{Edit_cboxAudioController_changed});
    $gui{d}{Edit}{cboxAudioCodec}->signal_handler_unblock($signal{Edit_cboxAudioCodec_changed});
    &set_pointer($gui{d}{Edit}{dialog});
}

# Toggle whether audio is enable or not for this guest
sub audio_toggle {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $state = $gui{d}{Edit}{checkAudio}->get_active();
        IAudioAdapter_setEnabled($vmc{IAudioAdapter}, $state);
        $gui{d}{Edit}{gridAudioTop}->set_sensitive($state);
        $gui{d}{Edit}{gridAudioBottom}->set_sensitive($state);
    }
}

# Toggle whether audio inputs are enabled
sub audio_input_toggle {
    IAudioAdapter_setEnabledIn($vmc{IAudioAdapter}, $gui{d}{Edit}{checkAudioInput}->get_active());
}

# Toggle whether audio outputs are enabled
sub audio_output_toggle {
    IAudioAdapter_setEnabledOut($vmc{IAudioAdapter}, $gui{d}{Edit}{checkAudioOutput}->get_active());
}

# Set the audio controller type
sub audio_ctr {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $controller = &getsel_combo($gui{d}{Edit}{cboxAudioController}, 1);
        IAudioAdapter_setAudioController($vmc{IAudioAdapter}, $controller);
        $gui{d}{Edit}{cboxAudioCodec}->set_model($gui{'liststoreEditAudioCodec' . $controller});
        &combobox_set_active_text($gui{d}{Edit}{cboxAudioCodec}, IAudioAdapter_getAudioCodec($vmc{IAudioAdapter}), 1);
    }
}

# Set the audio codec
sub audio_codec {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $codec = &getsel_combo($gui{d}{Edit}{cboxAudioCodec}, 1);
        IAudioAdapter_setAudioCodec($vmc{IAudioAdapter}, $codec);
    }
}

# Set the audio driver type
sub audio_driver {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $driver = &getsel_combo($gui{d}{Edit}{cboxAudioDriver}, 1);
        IAudioAdapter_setAudioDriver($vmc{IAudioAdapter}, $driver);
    }
}

1;
