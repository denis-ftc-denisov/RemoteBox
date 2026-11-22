# The Screen page of the Display Settings
use strict;
use warnings;
our (%gui, %vmc);

# Initialise the display page
sub init_edit_disp_screen() {
    &set_pointer($gui{d}{Edit}{dialog}, 'watch');
    my $vhost = &vhost();

    if (IGraphicsAdapter_getGraphicsControllerType($vmc{IGraphicsAdapter}) eq 'Null') { $gui{d}{Edit}{cboxDispController}->set_active(0); }
    elsif (IGraphicsAdapter_getGraphicsControllerType($vmc{IGraphicsAdapter}) eq 'VBoxVGA') { $gui{d}{Edit}{cboxDispController}->set_active(1); }
    elsif (IGraphicsAdapter_getGraphicsControllerType($vmc{IGraphicsAdapter}) eq 'VMSVGA') { $gui{d}{Edit}{cboxDispController}->set_active(2); }
    else { $gui{d}{Edit}{cboxDispController}->set_active(3); }

    $gui{d}{Edit}{sbDispMemory}->set_range($$vhost{minguestvram}, $$vhost{maxguestvram});
    $gui{d}{Edit}{sbDispMemory}->set_value(IGraphicsAdapter_getVRAMSize($vmc{IGraphicsAdapter}));
    $gui{d}{Edit}{sbDispMonitor}->set_range($$vhost{minmonitors}, $$vhost{maxmonitors});
    $gui{d}{Edit}{sbDispMonitor}->set_value(IGraphicsAdapter_getMonitorCount($vmc{IGraphicsAdapter}));
    $gui{d}{Edit}{checkDisp3D}->set_active(&bl(IGraphicsAdapter_isFeatureEnabled($vmc{IGraphicsAdapter}, 'Acceleration3D')));
    &set_pointer($gui{d}{Edit}{dialog});
}

# Set whether 3D accelerator is enabled.
sub disp_scr_3D { IGraphicsAdapter_setFeature($vmc{IGraphicsAdapter}, 'Acceleration3D', $gui{d}{Edit}{checkDisp3D}->get_active()); }

# Set the virtual VGA card type
sub disp_scr_VGA { if ($vmc{SessionType} eq 'WriteLock') { IGraphicsAdapter_setGraphicsControllerType($vmc{IGraphicsAdapter}, &getsel_combo($gui{d}{Edit}{cboxDispController}, 1)); } }

# Set the amount of video memory
sub disp_scr_vid_mem {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $vmem = int($gui{d}{Edit}{sbDispMemory}->get_value_as_int());
        $vmem = 2 if ($vmem < 2);
        IGraphicsAdapter_setVRAMSize($vmc{IGraphicsAdapter}, $vmem);
        return 0; # Must return this value for the signal used.
    }
}

# Set the number of virtual monitors
sub disp_scr_monitors {
    if ($vmc{SessionType} eq 'WriteLock') {
        IGraphicsAdapter_setMonitorCount($vmc{IGraphicsAdapter}, int($gui{d}{Edit}{sbDispMonitor}->get_value_as_int()));
        return 0; # Must return this value for the signal used.
    }
}

1;
