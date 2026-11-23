# Edit Storage Settings of a Guest
use strict;
use warnings;
our (%gui, %signal, %vmc);

sub init_edit_storage {
    set_pointer($gui{d}{Edit}{dialog}, 'watch');
    my $vhost = vhost();
    fill_list_edit_storage($vmc{IMachine});
    $gui{menuAttachAdd} = gui_new_menu();
    $gui{menuAttachHD} = gui_new_menu();
    $gui{menuAttachDVD} = gui_new_menu();
    $gui{menuAttachFloppy} = gui_new_menu();
    $gui{miAttachHD} = gui_new_menu_item_no_mnemonic('Hard Disks', 'hd_add_16px.png', $gui{menuAttachAdd});
    $gui{miAttachDVD} = gui_new_menu_item_no_mnemonic('Optical Discs', 'cd_add_16px.png', $gui{menuAttachAdd});
    $gui{miAttachFloppy} = gui_new_menu_item_no_mnemonic('Floppy Disks', 'fd_add_16px.png', $gui{menuAttachAdd});
    $gui{miAttachHD}->set_submenu($gui{menuAttachHD});
    $gui{miAttachDVD}->set_submenu($gui{menuAttachDVD});
    $gui{miAttachFloppy}->set_submenu($gui{menuAttachFloppy});
    my $newhditem = gui_new_menu_item_no_mnemonic('New Hard Disk', 'hd_create_16px.png', $gui{menuAttachHD});
    my ($vol, $dir, undef) = rsplitpath(IMachine_getSettingsFilePath($vmc{IMachine}));
    $newhditem->signal_connect('activate' => \&show_dialog_create_hd, {IMachine => $vmc{IMachine}, filename => rcatfile($vol . $dir, 'HardDisk-' . int(rand(999999))), callback => \&storage_attach_hd});
    $gui{menuAttachHD}->append(Gtk3::SeparatorMenuItem->new());
    my $adddvditem = gui_new_menu_item_no_mnemonic('Add Optical Disc Image', 'cd_add_16px.png', $gui{menuAttachDVD});
    $adddvditem->signal_connect('activate' => \&show_remote_filechooser, {title => 'Choose Disc Image', entrywidget => '', mode => 'file', filter => '^.*\.iso$', callback => \&storage_menu_add_optical_disc});
    my $emptydvditem = gui_new_menu_item_no_mnemonic('Empty Optical Drive', 'cd_clear_16px.png', $gui{menuAttachDVD});
    $emptydvditem->signal_connect('activate' => \&storage_attach_removable, {IMedium => '', type => 'DVD'});
    $gui{menuAttachDVD}->append(Gtk3::SeparatorMenuItem->new());
    my $floppyitem = gui_new_menu_item_no_mnemonic('Add Floppy Disk Image', 'fd_add_16px.png', $gui{menuAttachFloppy});
    $floppyitem->signal_connect('activate' => \&show_remote_filechooser, {title => 'Choose Floppy Disk Image', entrywidget => '', mode => 'file', filter => '^.*\.img$', callback => \&storage_menu_add_floppy_disk});
    my $newfloppyitem = gui_new_menu_item_no_mnemonic('New Floppy Disk', 'fd_create_16px.png', $gui{menuAttachFloppy});
    my $emptyfloppyitem = gui_new_menu_item_no_mnemonic('Empty Floppy Drive', 'fd_clear_16px.png', $gui{menuAttachFloppy});
    $emptyfloppyitem->signal_connect('activate' => \&storage_attach_removable, {IMedium => '', type => 'Floppy'});
    $newfloppyitem->signal_connect('activate' => \&show_dialog_create_floppy, {IMachine => $vmc{IMachine}, filename => rcatfile($$vhost{machinedir}, 'Floppy-' . int(rand(999999))), callback => \&storage_attach_removable});
    $gui{menuAttachFloppy}->append(Gtk3::SeparatorMenuItem->new());
    my $IMediumHDRef = get_all_media('HardDisk');
    my $IMediumDVDRef = get_all_media('DVD');
    my $IMediumFloppyRef = get_all_media('Floppy');

    foreach (sort { lc($$IMediumHDRef{$a}) cmp lc($$IMediumHDRef{$b}) } (keys %$IMediumHDRef)) {
        my $item = gui_new_menu_item_no_mnemonic($$IMediumHDRef{$_}, 'hd_16px.png', $gui{menuAttachHD});
        $item->signal_connect(activate => \&storage_attach_hd, {IMedium => $_, type => 'HardDisk'});
    }

    if ($$vhost{dvd}) {
        my $added;

        foreach my $pdvd (@{$$vhost{dvd}}) {
            $added = 1;
            my $item = gui_new_menu_item_no_mnemonic('<Server Drive> ' . IMedium_getLocation($pdvd), 'cd_16px.png', $gui{menuAttachDVD});
            $item->signal_connect('activate' => \&storage_attach_removable, {IMedium => $pdvd, type => 'DVD'});
        }

        $gui{menuAttachDVD}->append(Gtk3::SeparatorMenuItem->new()) if ($added);
    }

    foreach (sort { lc($$IMediumDVDRef{$a}) cmp lc($$IMediumDVDRef{$b}) } (keys %$IMediumDVDRef)) {
        my $item = gui_new_menu_item_no_mnemonic($$IMediumDVDRef{$_}, 'cd_16px.png', $gui{menuAttachDVD});
        $item->signal_connect('activate' => \&storage_attach_removable, {IMedium => $_, type => 'DVD'});
    }

    if ($$vhost{floppy}) {
        my $added;

        foreach my $pfloppy (@{$$vhost{floppy}}) {
            $added = 1;
            my $item = gui_new_menu_item_no_mnemonic('<Server Drive> ' . IMedium_getLocation($pfloppy), 'fd_16px.png', $gui{menuAttachFloppy});
            $item->signal_connect('activate' => \&storage_attach_removable, {IMedium => $pfloppy, type => 'Floppy'});
        }

        $gui{menuAttachFloppy}->append(Gtk3::SeparatorMenuItem->new()) if ($added);
    }

    foreach (sort { lc($$IMediumFloppyRef{$a}) cmp lc($$IMediumFloppyRef{$b}) } (keys %$IMediumFloppyRef)) {
        my $item = gui_new_menu_item_no_mnemonic($$IMediumFloppyRef{$_}, 'fd_16px.png', $gui{menuAttachFloppy});
        $item->signal_connect('activate' => \&storage_attach_removable, {IMedium => $_, type => 'Floppy'});
    }

    set_pointer($gui{d}{Edit}{dialog});
}


# Handle the radio button sensitivity when selecting an image format when
# creating a hard disk
sub storage_sens_create_hd {
    my $format = getsel_combo($gui{d}{CreateHD}{cboxFormat}, 1);
    $gui{d}{CreateHD}{radioDynamic}->set_active(1);

    if ($format eq 'vmdk') {
        $gui{d}{CreateHD}{radioDynamic}->show();
        $gui{d}{CreateHD}{radioFixed}->show();
        $gui{d}{CreateHD}{radioSplit}->show();
    }
    elsif ($format eq 'vdi' or $format eq 'vhd') {
        $gui{d}{CreateHD}{radioDynamic}->show();
        $gui{d}{CreateHD}{radioFixed}->show();
        $gui{d}{CreateHD}{radioSplit}->hide();
    }
    else {
        $gui{d}{CreateHD}{radioDynamic}->show();
        $gui{d}{CreateHD}{radioFixed}->hide();
        $gui{d}{CreateHD}{radioSplit}->hide();
    }
}

# Adds a storage controller to the guest
sub storage_ctr_add {
    my ($widget, $bus) = @_;
    my $ctrname = $bus;
    $ctrname =~ s/PCIe/NVMe/; # Must things the bus is the same as the controller name
    my @ctrs = IMachine_getStorageControllers($vmc{IMachine});
    my $exists = 0;

    foreach my $ctr (@ctrs) { $exists = 1 if (IStorageController_getBus($ctr) eq $bus) }

    if ($exists) { show_err_msg('ctrallocated', 0); }
    else {
        my $IStorageController = IMachine_addStorageController($vmc{IMachine}, $ctrname, $bus);
        IStorageController_setPortCount($IStorageController, IStorageController_getMinPortCount($IStorageController)); # Controllers have all ports on by default. Set to the minimum
        fill_list_edit_storage($vmc{IMachine});
    }
}

# Attaches a hard disk to a controller
sub storage_attach_hd {
    my ($widget, $medium) = @_;
    my $storref = getsel_list_edit_storage();
    my $attached = 0;
    my %address = get_free_deviceport($vmc{IMachine}, $$storref{IStorageController});

    if ($address{portnum} > -1) {
        IMachine_attachDevice($vmc{IMachine}, $$storref{ControllerName}, $address{portnum}, $address{devnum}, $$medium{type}, $$medium{IMedium});
        $attached = 1
    }

    # If medium wasn't attached, controller must be full
    if (!$attached) { show_err_msg('ctrfull', 0); }

    IMachine_saveSettings($vmc{IMachine});
    addrow_msg_log("Settings explicitly saved for $vmc{Name} due to storage attachment.");
    fill_list_edit_storage($vmc{IMachine});
}

sub storage_menu_add_floppy_disk {
    my ($basedir, $file) = @_;
    my $IMedium = register_medium(undef, {type => 'Floppy', mode => 'ReadWrite', basedir => $basedir, file => $file});
    storage_attach_removable(undef, {IMedium => $IMedium, type => 'Floppy'}) if ($IMedium);
}

sub storage_menu_add_optical_disc {
    my ($basedir, $file) = @_;
    my $IMedium = register_medium(undef, {type => 'DVD', mode => 'ReadOnly', basedir => $basedir, file => $file});
    storage_attach_removable(undef, {IMedium => $IMedium, type => 'DVD'}) if ($IMedium);
}

# Attaches removeable media to a controller
sub storage_attach_removable {
    my ($widget, $data) = @_;
    my $storref = getsel_list_edit_storage();
    my $attached = 0;

    if (!$$storref{IsController}) { IMachine_mountMedium($vmc{IMachine}, $$storref{ControllerName}, $$storref{Port}, $$storref{Device}, $$data{IMedium}); }
    else {
        my %address = get_free_deviceport($vmc{IMachine}, $$storref{IStorageController});

        if ($address{portnum} > -1) {
            IMachine_attachDevice($vmc{IMachine}, $$storref{ControllerName}, $address{portnum}, $address{devnum}, $$data{type}, $$data{IMedium});
            $attached = 1
        }

        # If medium wasn't attached, controller must be full
        if (!$attached) { show_err_msg('ctrfull', 0); }
    }

    IMachine_saveSettings($vmc{IMachine});
    addrow_msg_log("Settings explicitly saved for $vmc{Name} due to storage attachment.");
    fill_list_edit_storage($vmc{IMachine});
}

# Detaches a storage unit or ejects removable media
sub storage_attach_rem {
    my $storref = getsel_list_edit_storage();

    if ((($$storref{MediumType} eq 'Floppy') or ($$storref{MediumType} eq 'DVD')) and $$storref{IMedium}) {
        IMachine_mountMedium($vmc{IMachine}, $$storref{ControllerName}, $$storref{Port}, $$storref{Device}, '');
    }
    else {
        # We must reset the extradata for a floppy drive if the drive is deleted otherwise the VM won't start
        IMachine_setExtraData($vmc{IMachine}, 'VBoxInternal/Devices/i82078/0/LUN#' . $$storref{Device} . '/Config/Type', '') if ($$storref{MediumType} eq 'Floppy');
        IMachine_detachDevice($vmc{IMachine}, $$storref{ControllerName}, $$storref{Port}, $$storref{Device});
    }

    fill_list_edit_storage($vmc{IMachine});
}

# Removes a controller from the guest
sub storage_ctr_rem {
    my $storref = getsel_list_edit_storage();
    my @IMediumAttachments = IMachine_getMediumAttachmentsOfController($vmc{IMachine}, $$storref{ControllerName});

    if (@IMediumAttachments) { show_err_msg('ctrinuse', 0); }
    else { IMachine_removeStorageController($vmc{IMachine}, $$storref{ControllerName}); }

    fill_list_edit_storage($vmc{IMachine});
}

# Sets the controller variant type
sub storage_ctr_type {
    my $storref = getsel_list_edit_storage();
    IStorageController_setControllerType($$storref{IStorageController}, getsel_combo($gui{d}{Edit}{cboxStorageCtrtype}, 1));
}

# Sets the floppy drive type
sub storage_floppy_type {
    my $storref = getsel_list_edit_storage();
    IMachine_setExtraData($vmc{IMachine}, 'VBoxInternal/Devices/i82078/0/LUN#' . $$storref{Device} . '/Config/Type', getsel_combo($gui{d}{Edit}{cboxStorageFloppytype}, 1));
}

# Set / Clear the host I/O cache for the controller
sub storage_ctr_cache {
    my $storref = getsel_list_edit_storage();
    IStorageController_setUseHostIOCache($$storref{IStorageController}, $gui{d}{Edit}{checkStorageIOcache}->get_active());
}

sub show_attach_menu {
    my ($widget, $event) = @_;
    $gui{menuAttachAdd}->popup(undef, undef, undef, undef, 0, $event->time) if ($event->button == 1);
    return 0;
}

sub show_ctr_menu {
    my ($widget, $event) = @_; #$event->time
    $gui{menu}{CtrAdd}->popup(undef, undef, undef, undef, 0, $event->time) if ($event->button == 1);
    return 0;
}

# Sets a specific port count if manually set by the user
sub storage_port_count {
    my $storref = getsel_list_edit_storage();
    my $pc = int($gui{d}{Edit}{adjStoragePortcount}->get_value());
    IStorageController_setPortCount($$storref{IStorageController}, $pc);
}

# Flags a hard disk image as being SSD and also enables discard (maybe)
sub storage_ssd {
    my $storref = getsel_list_edit_storage();
    IMachine_nonRotationalDevice($vmc{IMachine}, $$storref{ControllerName}, $$storref{Port}, $$storref{Device}, $gui{d}{Edit}{checkStorageSolidstate}->get_active());
    # Seems VERY buggy. Do not enable for now. (VB 6.0.0)
    #IMachine_setAutoDiscardForDevice($vmc{IMachine}, $$storref{ControllerName}, $$storref{Port}, $$storref{Device}, $gui{d}{Edit}{checkStorageSolidstate}->get_active());
}

# Flags whether a CD/DVD is allowed to be temporary ejected (ie Live CD)
sub storage_livecd {
    my $storref = getsel_list_edit_storage();
    IMachine_temporaryEjectDevice($vmc{IMachine}, $$storref{ControllerName}, $$storref{Port}, $$storref{Device}, $gui{d}{Edit}{checkStorageLivedisc}->get_active());
}

# Flags whether a HD or Optical Device is hot pluggable
sub storage_hot_pluggable {
    my $storref = getsel_list_edit_storage();
    IMachine_setHotPluggableForDevice($vmc{IMachine}, $$storref{ControllerName}, $$storref{Port}, $$storref{Device}, $gui{d}{Edit}{checkStorageHotplug}->get_active());
}

# Flags whether the selected controller is bootable or not
sub storage_ctr_bootable {
    my $storref = getsel_list_edit_storage();
    IMachine_setStorageControllerBootable($vmc{IMachine}, $$storref{ControllerName}, $gui{d}{Edit}{checkStorageBootable}->get_active());
}

# Moves an attachment to a new port
sub storage_connected_port {
    my $newdevice = getsel_combo($gui{d}{Edit}{cboxStorageConnectedport}, 1);
    my $newport = getsel_combo($gui{d}{Edit}{cboxStorageConnectedport}, 2);
    my $storref = getsel_list_edit_storage();

    unless ($newport == $$storref{Port} and $newdevice == $$storref{Device}) {
        my @IMediumAttachment = IMachine_getMediumAttachmentsOfController($vmc{IMachine}, $$storref{ControllerName});
        my $free = 1;
        foreach my $attach (@IMediumAttachment) {
            if ($$attach{port} == $newport and $$attach{device} == $newdevice) {
                $free = 0;
                show_err_msg('existattach', 0);
                last;
            }
        }

        if ($free) {
            # SATA, SAS, NVMe, VirtioSCSI support changing the port counts
            if ($$storref{Bus} eq 'SATA' or $$storref{Bus} eq 'SAS' or $$storref{Bus} eq 'PCIe' or $$storref{Bus} eq 'VirtioSCSI') {
                if (IStorageController_getPortCount($$storref{IStorageController}) < ($newport + 1)) {
                    IStorageController_setPortCount($$storref{IStorageController}, $newport + 1) ;
                }
            }

            # We must ensure the extradata is cleared and set again when the drive port changes or the VM may not start
            if ($$storref{Bus} eq 'Floppy') {
                IMachine_setExtraData($vmc{IMachine}, 'VBoxInternal/Devices/i82078/0/LUN#' . $$storref{Device} . '/Config/Type', ''); # Clear the old one
                IMachine_setExtraData($vmc{IMachine}, 'VBoxInternal/Devices/i82078/0/LUN#' . $newdevice . '/Config/Type', getsel_combo($gui{d}{Edit}{cboxStorageFloppytype}, 0)); # set the new one
            }

            IMachine_detachDevice($vmc{IMachine}, $$storref{ControllerName}, $$storref{Port}, $$storref{Device});
            IMachine_attachDevice($vmc{IMachine}, $$storref{ControllerName}, $newport, $newdevice, $$storref{MediumType}, $$storref{IMedium});
            IMachine_saveSettings($vmc{IMachine});
            addrow_msg_log("Settings explicitly saved for $vmc{Name} due to storage attachment");
            fill_list_edit_storage($vmc{IMachine});
        }
    }
}

# Sets the sensitive of widgets if no storage item is selected
sub storage_sens_nosel {
    $gui{d}{Edit}{gridStorageattr}->hide(); # Hides all the attributed widgets in one go
    $gui{d}{Edit}{buttonStorageAddattach}->set_sensitive(0);
    $gui{d}{Edit}{buttonStorageRemoveattach}->set_sensitive(0);
    $gui{d}{Edit}{buttonStorageRemovectr}->set_sensitive(0);
}

1;
