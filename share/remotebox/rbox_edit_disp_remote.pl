# The Remote Display page of the Display Settings
use strict;
use warnings;
our (%gui, %vmc);

sub init_edit_disp_remote {
    set_pointer($gui{d}{Edit}{dialog}, 'watch');
    $gui{d}{Edit}{checkDispRemote}->set_active(bl(IVRDEServer_getEnabled($vmc{IVRDEServer})));
    $gui{d}{Edit}{gridDispRemote}->set_sensitive($gui{d}{Edit}{checkDispRemote}->get_active()); # Ghost/Unghost other widgets based on server enabled
    $gui{d}{Edit}{sbDispRDPtimeout}->set_value(IVRDEServer_getAuthTimeout($vmc{IVRDEServer}));
    $gui{d}{Edit}{entryDispPort}->set_text(IVRDEServer_getVRDEProperty($vmc{IVRDEServer}, 'TCP/Ports'));
    $gui{d}{Edit}{entryDispBind}->set_text(IVRDEServer_getVRDEProperty($vmc{IVRDEServer}, 'TCP/Address'));
    $gui{d}{Edit}{checkDispRDPmultiple}->set_active(bl(IVRDEServer_getAllowMultiConnection($vmc{IVRDEServer})));
    combobox_set_active_text($gui{d}{Edit}{cboxDispRDPauth}, IVRDEServer_getAuthType($vmc{IVRDEServer}), 1);
    # FIXME: Forced at the moment - should be configurable
    IVRDEServer_setVRDEProperty($vmc{IVRDEServer}, 'Security/Method', 'NEGOTIATE');
    IVRDEServer_setVRDEProperty($vmc{IVRDEServer}, 'Security/ServerCertificate', '');
    set_pointer($gui{d}{Edit}{dialog});
}

# Set the RDP authentication type
sub disp_rem_auth { IVRDEServer_setAuthType($vmc{IVRDEServer}, getsel_combo($gui{d}{Edit}{cboxDispRDPauth}, 1)); }

# Set whether multiple RDP logins are allowed
sub disp_rem_multi {
    # Avoid triggering if not in WriteLock mode. Cannot be changed when guest is running
    IVRDEServer_setAllowMultiConnection($vmc{IVRDEServer}, $gui{d}{Edit}{checkDispRDPmultiple}->get_active()) if ($vmc{SessionType} eq 'WriteLock');
}

# Set whether the RDP server is enabled or not
sub disp_toggleRemote {
    my $state = $gui{d}{Edit}{checkDispRemote}->get_active();
    IVRDEServer_setEnabled($vmc{IVRDEServer}, $state);
    $gui{d}{Edit}{gridDispRemote}->set_sensitive($state);
}

# Authentication timeout for the RDP server
sub disp_rem_timeout {
    IVRDEServer_setAuthTimeout($vmc{IVRDEServer}, $gui{d}{Edit}{sbDispRDPtimeout}->get_value_as_int());
    return 0;
}

# TCP Ports to use for the RDP / VNC server
sub disp_rem_ports {
    my $ports = $gui{d}{Edit}{entryDispPort}->get_text();
    IVRDEServer_setVRDEProperty($vmc{IVRDEServer}, 'TCP/Ports', $ports) if ($ports);
    return 0;
}

# Addresses to bind to explicitylu
sub disp_rem_bind {
    my $address = strim($gui{d}{Edit}{entryDispBind}->get_text());
    IVRDEServer_setVRDEProperty($vmc{IVRDEServer}, 'TCP/Address', $address); # Null means delete
    return 0;
}

1;
