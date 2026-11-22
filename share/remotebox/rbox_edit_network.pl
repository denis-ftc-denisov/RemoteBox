# Edit Network Settings of a Guest
use strict;
use warnings;
our (%gui, %signal, %vmc);

# NOTE: Despite what the SDK claims HostOnlyNetwork is not implemented

sub init_edit_network {
    &set_pointer($gui{d}{Edit}{dialog}, 'watch');
    $gui{d}{Edit}{cboxNetworkAdapter}->signal_handler_block($signal{Edit_cboxNetworkAdapter_changed});
    $gui{d}{Edit}{cboxNetworkAttached}->signal_handler_block($signal{Edit_cboxNetworkAttached_changed});
    $gui{d}{Edit}{cboxNetworkName}->signal_handler_block($signal{Edit_cboxNetworkName_changed});
    $gui{d}{Edit}{ecboxNetworkGeneric}->signal_handler_block($signal{Edit_ecboxNetworkGeneric_changed});
    $gui{d}{Edit}{ecboxNetworkInternal}->signal_handler_block($signal{Edit_ecboxNetworkInternal_changed});
    $gui{d}{Edit}{lstoreNetworkName}->clear();
    $gui{d}{Edit}{lstoreNetworkGeneric}->clear();
    $gui{d}{Edit}{lstoreNetworkInternal}->clear();
    $gui{d}{Edit}{tbNetworkGenericprop}->set_text('');
    my $INetworkAdapter = IMachine_getNetworkAdapter($vmc{IMachine}, &getsel_combo($gui{d}{Edit}{cboxNetwork}, 1));
    my $AttachType = INetworkAdapter_getAttachmentType($INetworkAdapter);
    my @IHostNetworkInterface = IHost_getNetworkInterfaces($vmc{IHost});
    $gui{d}{Edit}{checkNetwork}->set_active(&bl(INetworkAdapter_getEnabled($INetworkAdapter)));
    my $netenabled = $gui{d}{Edit}{checkNetwork}->get_active();
    $gui{d}{Edit}{gridNetwork}->set_sensitive($netenabled); # Ghost/Unghost other widgets based on net enabled
    $gui{d}{Edit}{gridNetworkAdv}->set_sensitive($netenabled);
    $gui{d}{Edit}{checkNetworkCable}->set_active(&bl(INetworkAdapter_getCableConnected($INetworkAdapter)));
    $gui{d}{Edit}{entryNetworkMAC}->set_text(INetworkAdapter_getMACAddress($INetworkAdapter));
    &combobox_set_active_text($gui{d}{Edit}{cboxNetworkAdapter}, INetworkAdapter_getAdapterType($INetworkAdapter), 1);
    &combobox_set_active_text($gui{d}{Edit}{cboxNetworkAttached}, $AttachType, 1);
    &combobox_set_active_text($gui{d}{Edit}{cboxNetworkPromisc}, INetworkAdapter_getPromiscModePolicy($INetworkAdapter), 1);

    if ($AttachType eq 'Bridged') { &net_gui_bridged($INetworkAdapter); }
    elsif ($AttachType eq 'HostOnlyNetwork') {
        # HostOnlyNetwork: Does not seem to be implemented even though SDK says it is - so make it HostOnly instead
        INetworkAdapter_setAttachmentType($INetworkAdapter, 'HostOnly');
        &net_gui_hon_named($INetworkAdapter);
    }
    elsif ($AttachType eq 'HostOnly') { &net_gui_hon_named($INetworkAdapter); }
    elsif ($AttachType eq 'Internal') { &net_gui_internal($INetworkAdapter); }
    elsif ($AttachType eq 'Generic') { &net_gui_generic($INetworkAdapter); }
    elsif ($AttachType eq 'NATNetwork') { &net_gui_nat_named($INetworkAdapter); }
    elsif ($AttachType eq 'NAT') { &net_gui_nat(); }
    else {&net_gui_notattached($INetworkAdapter); } # Cloud and Null

    $gui{d}{Edit}{cboxNetworkAdapter}->signal_handler_unblock($signal{Edit_cboxNetworkAdapter_changed});
    $gui{d}{Edit}{cboxNetworkAttached}->signal_handler_unblock($signal{Edit_cboxNetworkAttached_changed});
    $gui{d}{Edit}{cboxNetworkName}->signal_handler_unblock($signal{Edit_cboxNetworkName_changed});
    $gui{d}{Edit}{ecboxNetworkGeneric}->signal_handler_unblock($signal{Edit_ecboxNetworkGeneric_changed});
    $gui{d}{Edit}{ecboxNetworkInternal}->signal_handler_unblock($signal{Edit_ecboxNetworkInternal_changed});
    &set_pointer($gui{d}{Edit}{dialog});
}

# Whether the adapter is enabled
sub net_toggle {
    my ($widget) = @_;
        if ($vmc{SessionType} eq 'WriteLock') {
        my $state = $widget->get_active();
        my $INetworkAdapter = &net_callout();
        INetworkAdapter_setEnabled($INetworkAdapter, $state);
        $gui{d}{Edit}{gridNetwork}->set_sensitive($state);
        $gui{d}{Edit}{gridNetworkAdv}->set_sensitive($state);
    }
}

# Sets whether the virtual network cable is plugged in or not
sub net_cable {
    my ($widget) = @_;
    my $INetworkAdapter = &net_callout();
    INetworkAdapter_setCableConnected($INetworkAdapter, $widget->get_active());
}

# Sets whether the network adapter in the VM is allowed to enter promiscuous mode
sub net_promiscuous {
    my $INetworkAdapter = &net_callout();
    INetworkAdapter_setPromiscModePolicy($INetworkAdapter, &getsel_combo($gui{d}{Edit}{cboxNetworkPromisc}, 1));
}

# Sets the MAC address for the virtual NIC
sub net_mac {
    my ($widget) = @_;

    if ($vmc{SessionType} eq 'WriteLock') {
        my $INetworkAdapter = &net_callout();
        my $mac = $widget->get_text();
        INetworkAdapter_setMACAddress($INetworkAdapter, $mac) if (length($mac) == 12);
    }
}

# Generates a new MAC address for the virtual NIC
sub net_mac_regenerate {
    my $INetworkAdapter = &net_callout();
    INetworkAdapter_setMACAddress($INetworkAdapter, ''); # Forces a new mac to be generated
    my $mac = INetworkAdapter_getMACAddress($INetworkAdapter);
    $gui{d}{Edit}{entryNetworkMAC}->set_text($mac);
}

sub net_generic_driver {
    my ($widget) = @_;
    my $INetworkAdapter = &net_callout();
    my $genericdriver = &getsel_combo($widget, 1);
    INetworkAdapter_setGenericDriver($INetworkAdapter, $genericdriver) if ($genericdriver);
}

# Sets the generic drivers properties from the textview
sub net_generic_properties {
    my $INetworkAdapter = &net_callout();
    my @cprops = INetworkAdapter_getProperties($INetworkAdapter, 0); #It Returns a single array. First half is keys, second is values

    # Clear out all properties before adding the new ones
    if (scalar(@cprops) > 0) {
        foreach (0 .. int(@cprops / 2) - 1) { INetworkAdapter_setProperty($INetworkAdapter, $cprops[$_], ''); }
    }

    my $textbuffer = $gui{d}{Edit}{tbNetworkGenericprop};
    my $count = $textbuffer->get_line_count();

    foreach my $linenum (0 .. ($count - 1)) {
        my $iter_s = $textbuffer->get_iter_at_line($linenum);
        my $iter_e;
        $iter_e = ($linenum == ($count - 1)) ? $textbuffer->get_end_iter() : $textbuffer->get_iter_at_line($linenum + 1);
        my $line = $textbuffer->get_text($iter_s, $iter_e, 0);
        chomp($line);
        $line =~ m/^(.*)=(.*)$/; # match against equals
        my $key = $1;
        my $value = $2;
        $line = &strim($line);
        INetworkAdapter_setProperty($INetworkAdapter, $key, $value) if ($key and $value);
    }
}

sub net_adapter_type {
    my ($widget) = @_;
    my $INetworkAdapter = &net_callout();
    my $type = &getsel_combo($widget, 1);
    INetworkAdapter_setAdapterType($INetworkAdapter, $type);
}

sub net_attach {
    my ($widget) = @_;
    my $INetworkAdapter = &net_callout();
    $gui{d}{Edit}{cboxNetworkName}->signal_handler_block($signal{Edit_cboxNetworkName_changed});
    $gui{d}{Edit}{ecboxNetworkGeneric}->signal_handler_block($signal{Edit_ecboxNetworkGeneric_changed});
    $gui{d}{Edit}{ecboxNetworkInternal}->signal_handler_block($signal{Edit_ecboxNetworkInternal_changed});
    my $AttachType = &getsel_combo($widget, 1);
    $gui{d}{Edit}{lstoreNetworkName}->clear();
    INetworkAdapter_setAttachmentType($INetworkAdapter, $AttachType);
    if ($AttachType eq 'Bridged') { &net_gui_bridged($INetworkAdapter); }
    elsif ($AttachType eq 'HostOnly') { &net_gui_hon_named($INetworkAdapter); }
    elsif ($AttachType eq 'Internal') { &net_gui_internal($INetworkAdapter); }
    elsif ($AttachType eq 'Generic') { &net_gui_generic($INetworkAdapter); }
    elsif ($AttachType eq 'NATNetwork') { &net_gui_nat_named($INetworkAdapter); }
    elsif ($AttachType eq 'NAT') { &net_gui_nat(); }
    else {&net_gui_notattached($INetworkAdapter); } # Cloud and Null

    $gui{d}{Edit}{ecboxNetworkGeneric}->signal_handler_unblock($signal{Edit_ecboxNetworkGeneric_changed});
    $gui{d}{Edit}{ecboxNetworkInternal}->signal_handler_unblock($signal{Edit_ecboxNetworkInternal_changed});
    $gui{d}{Edit}{cboxNetworkName}->signal_handler_unblock($signal{Edit_cboxNetworkName_changed});
    $gui{d}{Edit}{cboxNetworkName}->set_active(0); # This will call net_name()
}

sub net_name {
    my $INetworkAdapter = &net_callout();
    my $AttachType = &getsel_combo($gui{d}{Edit}{cboxNetworkAttached}, 1);
    my $netname = &getsel_combo($gui{d}{Edit}{cboxNetworkName}, 0);

    if ($netname) { # If there's no netname then we cannot attach (eg there may be not HON or NATNets defined)
        if ($AttachType eq 'Bridged') { INetworkAdapter_setBridgedInterface($INetworkAdapter, $netname) if defined($netname); }
        elsif ($AttachType eq 'NATNetwork') { INetworkAdapter_setNATNetwork($INetworkAdapter, $netname) if defined($netname); }
        elsif ($AttachType eq 'HostOnly') { INetworkAdapter_setHostOnlyInterface($INetworkAdapter, $netname) if defined($netname); }
    }
}

sub net_name_internal {
    my ($widget) = @_;
    my $INetworkAdapter = &net_callout();
    my $name = $widget->get_child->get_text();
    INetworkAdapter_setInternalNetwork($INetworkAdapter, $name) if ($name);
}

sub net_callout {
    my $slot = &getsel_combo($gui{d}{Edit}{cboxNetwork}, 1);
    my $INetworkAdapter = IMachine_getNetworkAdapter($vmc{IMachine}, $slot);
    return $INetworkAdapter;
}

# Handle hiding and unhiding gui components based on attachment type
sub net_gui_bridged {
    my ($INetworkAdapter) = @_;
    my @IHostNetworkInterface = IHost_getNetworkInterfaces($vmc{IHost});
    my $bridgeface = INetworkAdapter_getBridgedInterface($INetworkAdapter);

    foreach my $interface (@IHostNetworkInterface) {
        if (IHostNetworkInterface_getInterfaceType($interface) eq 'Bridged') {
            my $name = IHostNetworkInterface_getName($interface);
            my $iter = $gui{d}{Edit}{lstoreNetworkName}->append();
            $gui{d}{Edit}{lstoreNetworkName}->set($iter, 0, $name);
            $gui{d}{Edit}{cboxNetworkName}->set_active_iter($iter) if ($name eq $bridgeface);
        }
    }

    $gui{d}{Edit}{labelNetworkName}->show();
    $gui{d}{Edit}{cboxNetworkName}->show();
    $gui{d}{Edit}{labelNetworkPromisc}->show();
    $gui{d}{Edit}{cboxNetworkPromisc}->show();
    $gui{d}{Edit}{labelNetworkInternal}->hide();
    $gui{d}{Edit}{ecboxNetworkInternal}->hide();
    $gui{d}{Edit}{labelNetworkGeneric}->hide();
    $gui{d}{Edit}{ecboxNetworkGeneric}->hide();
    $gui{d}{Edit}{labelNetworkGenericprop}->hide();
    $gui{d}{Edit}{frameNetworkGenericprop}->hide();
    $gui{d}{Edit}{tvNetworkGenericprop}->hide();
    &combobox_set_active_text($gui{d}{Edit}{cboxNetworkPromisc}, INetworkAdapter_getPromiscModePolicy($INetworkAdapter), 1);
}

sub net_gui_notattached {
    $gui{d}{Edit}{labelNetworkName}->hide();
    $gui{d}{Edit}{cboxNetworkName}->hide();
    $gui{d}{Edit}{labelNetworkInternal}->hide();
    $gui{d}{Edit}{ecboxNetworkInternal}->hide();
    $gui{d}{Edit}{labelNetworkGeneric}->hide();
    $gui{d}{Edit}{ecboxNetworkGeneric}->hide();
    $gui{d}{Edit}{labelNetworkPromisc}->hide();
    $gui{d}{Edit}{cboxNetworkPromisc}->hide();
    $gui{d}{Edit}{labelNetworkGenericprop}->hide();
    $gui{d}{Edit}{frameNetworkGenericprop}->hide();
    $gui{d}{Edit}{tvNetworkGenericprop}->hide();
}

sub net_gui_hon_named {
    my ($INetworkAdapter) = @_;
    my @IHostNetworkInterface = IHost_getNetworkInterfaces($vmc{IHost});
    my $hostonlyface = INetworkAdapter_getHostOnlyInterface($INetworkAdapter);

    foreach my $interface (@IHostNetworkInterface) {

        if (IHostNetworkInterface_getInterfaceType($interface) eq 'HostOnly') {
            my $name = IHostNetworkInterface_getName($interface);
            my $iter = $gui{d}{Edit}{lstoreNetworkName}->append();
            $gui{d}{Edit}{lstoreNetworkName}->set($iter, 0, $name);
            if (defined($hostonlyface)) {
                $gui{d}{Edit}{cboxNetworkName}->set_active_iter($iter) if ($name eq $hostonlyface);
            }
        }
    }

    $gui{d}{Edit}{labelNetworkName}->show();
    $gui{d}{Edit}{cboxNetworkName}->show();
    $gui{d}{Edit}{labelNetworkPromisc}->show();
    $gui{d}{Edit}{cboxNetworkPromisc}->show();
    $gui{d}{Edit}{labelNetworkInternal}->hide();
    $gui{d}{Edit}{ecboxNetworkInternal}->hide();
    $gui{d}{Edit}{labelNetworkGeneric}->hide();
    $gui{d}{Edit}{ecboxNetworkGeneric}->hide();
    $gui{d}{Edit}{labelNetworkGenericprop}->hide();
    $gui{d}{Edit}{frameNetworkGenericprop}->hide();
    $gui{d}{Edit}{tvNetworkGenericprop}->hide();
}

sub net_gui_nat_named {
    my ($INetworkAdapter) = @_;
    my @INATNetwork = IVirtualBox_getNATNetworks($gui{websn});
    my $natnetface = INetworkAdapter_getNATNetwork($INetworkAdapter);

    foreach my $nat (@INATNetwork) {
            my $name = INATNetwork_getNetworkName($nat);
            my $iter = $gui{d}{Edit}{lstoreNetworkName}->append();
            $gui{d}{Edit}{lstoreNetworkName}->set($iter, 0, $name);
            $gui{d}{Edit}{cboxNetworkName}->set_active_iter($iter) if ($name eq $natnetface);
    }

    $gui{d}{Edit}{labelNetworkName}->show();
    $gui{d}{Edit}{cboxNetworkName}->show();
    $gui{d}{Edit}{labelNetworkPromisc}->show();
    $gui{d}{Edit}{cboxNetworkPromisc}->show();
    $gui{d}{Edit}{labelNetworkInternal}->hide();
    $gui{d}{Edit}{ecboxNetworkInternal}->hide();
    $gui{d}{Edit}{labelNetworkGeneric}->hide();
    $gui{d}{Edit}{ecboxNetworkGeneric}->hide();
    $gui{d}{Edit}{labelNetworkGenericprop}->hide();
    $gui{d}{Edit}{frameNetworkGenericprop}->hide();
    $gui{d}{Edit}{tvNetworkGenericprop}->hide();
}

sub net_gui_internal {
    my ($INetworkAdapter) = @_;
    $gui{d}{Edit}{lstoreNetworkInternal}->clear();
    my $name = INetworkAdapter_getInternalNetwork($INetworkAdapter);
    my @intlist = IVirtualBox_getInternalNetworks($gui{websn});

    foreach my $net (@intlist) {
        my $iter = $gui{d}{Edit}{lstoreNetworkInternal}->append();
        $gui{d}{Edit}{lstoreNetworkInternal}->set($iter, 0, $net);
        $gui{d}{Edit}{ecboxNetworkInternal}->set_active_iter($iter) if ($net eq $name);
    }

    $gui{d}{Edit}{labelNetworkInternal}->show();
    $gui{d}{Edit}{ecboxNetworkInternal}->show();
    $gui{d}{Edit}{labelNetworkPromisc}->show();
    $gui{d}{Edit}{cboxNetworkPromisc}->show();
    $gui{d}{Edit}{labelNetworkName}->hide();
    $gui{d}{Edit}{cboxNetworkName}->hide();
    $gui{d}{Edit}{labelNetworkGeneric}->hide();
    $gui{d}{Edit}{ecboxNetworkGeneric}->hide();
    $gui{d}{Edit}{labelNetworkGenericprop}->hide();
    $gui{d}{Edit}{frameNetworkGenericprop}->hide();
    $gui{d}{Edit}{tvNetworkGenericprop}->hide();
}

sub net_gui_nat {
    $gui{d}{Edit}{labelNetworkName}->hide();
    $gui{d}{Edit}{cboxNetworkName}->hide();
    $gui{d}{Edit}{labelNetworkInternal}->hide();
    $gui{d}{Edit}{ecboxNetworkInternal}->hide();
    $gui{d}{Edit}{labelNetworkGeneric}->hide();
    $gui{d}{Edit}{ecboxNetworkGeneric}->hide();
    $gui{d}{Edit}{labelNetworkPromisc}->hide();
    $gui{d}{Edit}{cboxNetworkPromisc}->hide();
    $gui{d}{Edit}{labelNetworkGenericprop}->hide();
    $gui{d}{Edit}{frameNetworkGenericprop}->hide();
    $gui{d}{Edit}{tvNetworkGenericprop}->hide();
}

sub net_gui_generic {
    my ($INetworkAdapter) = @_;
    $gui{d}{Edit}{lstoreNetworkGeneric}->clear();
    my $genericdriver = INetworkAdapter_getGenericDriver($INetworkAdapter);
    my @genericlist = IVirtualBox_getGenericNetworkDrivers($gui{websn});
    my @props = INetworkAdapter_getProperties($INetworkAdapter, 0); #It Returns a single array. First half is keys, second is values
    my $proptext;

    # Messy thanks to the way INetworkAdapter_getProperties works
    if (scalar(@props) > 0) {
        my $propnum = scalar(@props);
        my @props_vals = splice(@props, int($propnum / 2), $propnum); #grab the last half of array.
        my @props_keys = splice(@props, 0, int($propnum / 2)); #grab the first half of array.
        foreach (0 .. scalar(@props_keys) - 1) { $proptext .= "$props_keys[$_]" . '=' . "$props_vals[$_]\n"; }
    }

    $gui{d}{Edit}{tbNetworkGenericprop}->set_text($proptext) if ($proptext);

    foreach my $driver (@genericlist) {
            my $iter = $gui{d}{Edit}{lstoreNetworkGeneric}->append();
            $gui{d}{Edit}{lstoreNetworkGeneric}->set($iter, 0, $driver);
            $gui{d}{Edit}{ecboxNetworkGeneric}->set_active_iter($iter) if ($driver eq $genericdriver);
    }

    $gui{d}{Edit}{labelNetworkGeneric}->show();
    $gui{d}{Edit}{ecboxNetworkGeneric}->show();
    $gui{d}{Edit}{labelNetworkGenericprop}->show();
    $gui{d}{Edit}{frameNetworkGenericprop}->show();
    $gui{d}{Edit}{tvNetworkGenericprop}->show();
    $gui{d}{Edit}{labelNetworkName}->hide();
    $gui{d}{Edit}{cboxNetworkName}->hide();
    $gui{d}{Edit}{labelNetworkInternal}->hide();
    $gui{d}{Edit}{ecboxNetworkInternal}->hide();
    $gui{d}{Edit}{labelNetworkPromisc}->hide();
    $gui{d}{Edit}{cboxNetworkPromisc}->hide();
}

1;
