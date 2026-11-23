# Creating a new guest
use strict;
use warnings;
our (%gui, %signal, %prefs);

sub show_dialog_new_guest {
    my $vhost = vhost();
    my ($osfam, $osver) = osfamver();
    $gui{d}{New}{checkStartupDisk}->set_active(1);
    $gui{d}{New}{cboxFormat}->set_active(0);
    $gui{d}{New}{radioDynamic}->set_sensitive(1);
    $gui{d}{New}{radioFixed}->set_sensitive(1);
    $gui{d}{New}{radioSplit}->set_sensitive(0);
    $gui{d}{New}{entryName}->set_text('Guest-' . int(rand(999999)));
    $gui{d}{New}{sbMemory}->set_range($$vhost{minguestram}, $$vhost{memsize});
    $gui{d}{New}{sbSize}->set_range($$vhost{minhdsizemb}, $$vhost{maxhdsizemb});
    $gui{d}{New}{scaleMemory}->clear_marks();
    $gui{d}{New}{scaleMemory}->add_mark(262144.00,'GTK_POS_BOTTOM') if (262144 <= $$vhost{memsize});
    $gui{d}{New}{scaleMemory}->add_mark(131072.00,'GTK_POS_TOP') if (131072 <= $$vhost{memsize});
    $gui{d}{New}{scaleMemory}->add_mark(65536.00,'GTK_POS_BOTTOM') if (65536 <= $$vhost{memsize});
    $gui{d}{New}{scaleMemory}->add_mark(32768.00,'GTK_POS_TOP') if (32768 <= $$vhost{memsize});
    $gui{d}{New}{scaleMemory}->add_mark(16384.00,'GTK_POS_BOTTOM') if (16384 <= $$vhost{memsize});
    $gui{d}{New}{scaleMemory}->add_mark(8192.00,'GTK_POS_TOP') if (8192 <= $$vhost{memsize});
    $gui{d}{New}{scaleMemory}->add_mark(4096.00,'GTK_POS_BOTTOM') if (4096 <= $$vhost{memsize});
    $gui{d}{New}{scaleMemory}->add_mark(2048.00,'GTK_POS_TOP') if (2048 <= $$vhost{memsize});
    $gui{d}{New}{scaleMemory}->add_mark(1024.00,'GTK_POS_BOTTOM') if (1024 <= $$vhost{memsize});
    $gui{d}{New}{cboxFamily}->signal_handler_block($signal{New_cboxFamily_changed}); # Block to avoid signal emission when changing
    $gui{d}{New}{cboxVersion}->signal_handler_block($signal{New_cboxVersion_changed});
    $gui{d}{New}{lstoreFamily}->clear();
    $gui{d}{New}{lstoreVersion}->clear();
    $gui{d}{New}{lstoreExistingDisk}->clear();

    foreach my $fam (sort { if    ($$osfam{$a}{description} =~ m/Other/) { return 1; }
                            elsif ($$osfam{$b}{description} =~ m/Other/) { return -1; }
                            else  { return lc($$osfam{$a}{description}) cmp lc($$osfam{$b}{description}) }
                          } keys %{$osfam}) {

        my $iter = $gui{d}{New}{lstoreFamily}->append();
        $gui{d}{New}{lstoreFamily}->set($iter, [0, 1, 2], ["$$osfam{$fam}{description}", $fam, $$osfam{$fam}{icon}]);
        $gui{d}{New}{cboxFamily}->set_active_iter($iter) if ($fam eq 'Windows');
    }

    my $IMediumRef = get_all_media('HardDisk');

    if (keys(%$IMediumRef) > 0) {
        foreach my $hd (sort { lc($$IMediumRef{$a}) cmp lc($$IMediumRef{$b}) } (keys(%$IMediumRef))) {
            my $iter = $gui{d}{New}{lstoreExistingDisk}->append();
            $gui{d}{New}{lstoreExistingDisk}->set($iter, [0, 1], [$$IMediumRef{$hd}, $hd]);
        }

        $gui{d}{New}{cboxExistingDisk}->set_active(0);
        $gui{d}{New}{radioExistingDisk}->set_sensitive(1);
    }
    else { $gui{d}{New}{radioExistingDisk}->set_sensitive(0); };

    $gui{d}{New}{cboxFamily}->signal_handler_unblock($signal{New_cboxFamily_changed});
    $gui{d}{New}{cboxVersion}->signal_handler_unblock($signal{New_cboxVersion_changed});
    $gui{d}{New}{cboxFamily}->signal_emit('changed'); # Force update of other fields based on OS
    $gui{d}{New}{cboxVersion}->signal_emit('changed'); # Force update of other fields based on OS
    fill_list_new_guest_dvd();

    do {
        my $response = $gui{d}{New}{dialog}->run();

        if ($response eq 'ok') {
            # Other entries do not require validation
            if (!$gui{d}{New}{entryName}->get_text()) { show_err_msg('invalidname', 0); }
            else {
                $gui{d}{New}{dialog}->hide();
                my $name = $gui{d}{New}{entryName}->get_text();
                my $IMachine = IVirtualBox_createMachine($gui{websn}, '', $name, getsel_combo($gui{d}{New}{cboxVersion}, 2), '', getsel_combo($gui{d}{New}{cboxVersion}, 1), 'UUID=' . generate_uuid(), '');

                if ($IMachine) {
                    IMachine_applyDefaults($IMachine);
                    IMachine_saveSettings($IMachine); # Seems to be needed here to work around a VB bug, where it doesn't enable the VRDE server.
                    IMachine_setMemorySize($IMachine, $gui{d}{New}{sbMemory}->get_value_as_int());
                    IAudioAdapter_setAudioDriver(IAudioSettings_getAdapter(IMachine_getAudioSettings($IMachine)), 'Null');
                    my $IVRDEServer = IMachine_getVRDEServer($IMachine);
                    IVRDEServer_setEnabled($IVRDEServer, 'true');
                    IVRDEServer_setAllowMultiConnection($IVRDEServer, 'true');
                    IMachine_setClipboardMode($IMachine, 'Bidirectional');

                    if ($$vhost{vrdeextpack} =~ m/vnc/i) { IVRDEServer_setVRDEProperty($IVRDEServer, 'TCP/Ports', $prefs{DEFVNCPORTS}) }
                    else {
                        IVRDEServer_setVRDEProperty($IVRDEServer, 'TCP/Ports', $prefs{DEFRDPPORTS});
                        IVRDEServer_setVRDEProperty($IVRDEServer, 'Security/Method', 'NEGOTIATE');
                        IVRDEServer_setVRDEProperty($IVRDEServer, 'Security/ServerCertificate', '');
                    }

                    IMachine_saveSettings($IMachine);
                    IVirtualBox_registerMachine($gui{websn}, $IMachine);
                    addrow_msg_log("Created a new guest: $name");
                    my $sref = get_session($IMachine);

                    if ($$sref{Type} eq 'WriteLock') {

                        if ($gui{d}{New}{checkStartupDisk}->get_active() == 1) {
                            my $IMediumHD;

                            if ($gui{d}{New}{radioNewDisk}->get_active()) {
                                my %newhd = (diskname   => $name, # Use guest name as basis for disk
                                             devicetype => 'HardDisk',
                                             mode       => 'ReadWrite',
                                             size       => $gui{d}{New}{sbSize}->get_value_as_int() * 1048576,
                                             allocation => ['Standard'], # Standard == Dynamic Allocation
                                             imgformat  => getsel_combo($gui{d}{New}{cboxFormat}, 1),
                                             location   => rcatdir($$vhost{machinedir}, $name));

                                if ($gui{d}{New}{radioFixed}->get_active()) { $newhd{allocation} = ['Fixed']; }
                                elsif ($gui{d}{New}{radioSplit}->get_active()) { $newhd{allocation} = ['VmdkSplit2G']; }
                                $IMediumHD = create_new_dskimg(\%newhd);
                            }
                            else { $IMediumHD = getsel_combo($gui{d}{New}{cboxExistingDisk}, 1); }

                            my %os = %{ $$osver{getsel_combo($gui{d}{New}{cboxVersion}, 1)} };
                            my $IStorCtrHD = IMachine_getStorageControllerByInstance($$sref{IMachine}, $os{recommendedHDStorageBus}, 0);
                            my %hdaddress = get_free_deviceport($$sref{IMachine}, $IStorCtrHD);
                            IMachine_attachDevice($$sref{IMachine}, $os{recommendedHDStorageBus}, $hdaddress{portnum}, $hdaddress{devnum}, 'HardDisk', $IMediumHD) if ($IMediumHD);
                            my $IStorCtrDVD = IMachine_getStorageControllerByInstance($$sref{IMachine}, $os{recommendedDVDStorageBus}, 0); # Attach Empty CD/DVD Device
                            my %dvdaddress = get_free_deviceport($$sref{IMachine}, $IStorCtrDVD);
                            IMachine_attachDevice($$sref{IMachine}, $os{recommendedDVDStorageBus}, $dvdaddress{portnum}, $dvdaddress{devnum}, 'DVD', '');

                            if ($os{recommendedFloppy} eq 'true') {
                                my $IStorCtrFloppy = IMachine_getStorageControllerByInstance($$sref{IMachine}, 'Floppy', 0);
                                my %floppyaddress = get_free_deviceport($$sref{IMachine}, $IStorCtrFloppy);
                                IMachine_attachDevice($$sref{IMachine}, 'Floppy', $floppyaddress{portnum}, $floppyaddress{devnum}, 'Floppy', '');
                            }
                        }

                        # ISO Section
                        my $IMediumDVD = getsel_combo($gui{d}{New}{cboxISO}, 1);
                        if (defined($IMediumDVD)) {
                            my @IMediumAttachment = IMachine_getMediumAttachments($$sref{IMachine});
                            foreach my $attach (@IMediumAttachment) {
                                next if ($$attach{type} ne 'DVD');
                                IMachine_mountMedium($$sref{IMachine}, $$attach{controller}, $$attach{port}, $$attach{device}, $IMediumDVD, 0);
                                last;
                            }
                        }

                        IMachine_saveSettings($$sref{IMachine});
                    }

                    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
                    fill_list_guest();
                }
                else { show_err_msg('createguest', 0, " ($name)"); }
            }
        }
        else { $gui{d}{New}{dialog}->hide(); }

    } until (!$gui{d}{New}{dialog}->get_visible());
}

# Shows the dialog for creating a new clone
sub show_dialogClone {
    my $gref = getsel_list_guest();
    $gui{d}{Clone}{entryName}->set_text($$gref{Name} . '-Clone-' . int(rand(999999)));

    do {
        $gui{d}{Clone}{dialog}->show_all;
        my $response = $gui{d}{Clone}{dialog}->run();

        if ($response eq 'ok') {
            # No validation needed for other entries
            if (!$gui{d}{Clone}{entryName}->get_text()) { show_err_msg('invalidname', 0); }
            else {
                $gui{d}{Clone}{dialog}->hide;

                my %newclone = (name    => $gui{d}{Clone}{entryName}->get_text(),
                                mode    => 'MachineState',
                                linked  => 0,
                                options => []);

                # All other clone types just use 'MachineState'
                $newclone{mode} = 'AllStates' if ($gui{d}{Clone}{cboxType}->get_active() == 0);

                # The Link type is not really a mode, but an option
                if ($gui{d}{Clone}{cboxType}->get_active() == 2) {
                    push(@{$newclone{options}}, 'Link');
                    $newclone{linked} = 1;
                }
                push(@{$newclone{options}}, 'KeepAllMACs') if ($gui{d}{Clone}{cboxMAC}->get_active() == 0); # New MACs are generated by default
                push(@{$newclone{options}}, 'KeepNATMACs') if ($gui{d}{Clone}{cboxMAC}->get_active() == 1); # New MACs are generated by default
                push(@{$newclone{options}}, 'KeepDiskNames') if ($gui{d}{Clone}{checkKeepDiskName}->get_active() == 1);
                push(@{$newclone{options}}, 'KeepHwUUIDs') if ($gui{d}{Clone}{checkKeepUUIDs}->get_active() == 1);
                create_new_clone($gref, \%newclone);
                fill_list_guest();
            }
        }
        else { $gui{d}{Clone}{dialog}->hide; }

    } until (!$gui{d}{Clone}{dialog}->get_visible());
}

# Determines the next free port number and device number on a controller. If
# there isn't one, then a new one will be created, provided the controller is
# not at its maximum. If it is -1 is returned for the port and device numbers
sub get_free_deviceport {
    # !!Be careful about portnum versus portcount!! Eg ports 0 to 7 is a portcount of 8
    my ($IMachine, $IStorCtr) = @_;

    # A device address is made up of PortNumber then DeviceNumber
    my %address = (portnum => -1,
                   devnum  => -1);

    my @usedaddress;
    my @IMediumAttachment = IMachine_getMediumAttachmentsOfController($IMachine, IStorageController_getName($IStorCtr));
    my $portnum_hi = (IStorageController_getPortCount($IStorCtr)) - 1;
    my $devnum_hi = (IStorageController_getMaxDevicesPerPortCount($IStorCtr)) - 1;

    # Populate the used addresses.
    foreach my $attach (@IMediumAttachment) { $usedaddress[$$attach{device}][$$attach{port}] = $attach; }

    # Discover free ports/devices
    foreach my $devnum (0..$devnum_hi) {
        last if ($address{devnum} != -1); # Found a free address

        foreach my $portnum (0..$portnum_hi) {
            next if ($usedaddress[$devnum][$portnum]); # Its used. Try next one
            $address{devnum} = $devnum;
            $address{portnum} = $portnum;
            last;
        }
    }

    # If we haven't found a free address, try to create a new one
    if ($address{portnum} == -1) {
        my $portnum_max = IStorageController_getMaxPortCount($IStorCtr) - 1;

        if ($portnum_hi < $portnum_max) {
            $portnum_hi++; # Increase the max portnumber
            IStorageController_setPortCount($IStorCtr, $portnum_hi + 1); # Portcount is always +1 over the highest port number
            $address{portnum} = $portnum_hi;
            $address{devnum} = 0;
        }
    }

    return %address;
}

# Creates a clone of a guest
sub create_new_clone {
    my $vhost = vhost();
    my ($srcgref, $cloneref) = @_;
    # We create a new 'empty' guest
    my $cloneIMachine = IVirtualBox_createMachine($gui{websn}, '', $$cloneref{name}, 'x86', '', $$srcgref{Osid}, generate_uuid(), '');
    my $IProgress;

    if ($$cloneref{linked}) { # Is cancellable
        # Linked clones require a snapshot of the source to be taken first. The IMachine must be of that snapshot
        take_snapshot("Base for $$srcgref{Name} and $$cloneref{name}", "Snapshot automatically taken when cloning $$srcgref{Name} to $$cloneref{name}");
        my $snapIMachine = ISnapshot_getMachine(IMachine_getCurrentSnapshot($$srcgref{IMachine}));
        $IProgress = IMachine_cloneTo($snapIMachine, $cloneIMachine, $$cloneref{mode}, @{$$cloneref{options}})
    }
    else {
        $IProgress = IMachine_cloneTo($$srcgref{IMachine}, $cloneIMachine, $$cloneref{mode}, @{$$cloneref{options}});
    }

    show_progress_window($IProgress, 'Cloning Guest', $gui{pb}{ProgressClone}) if ($IProgress); # MUST NOT USE $cloneIMachine until progress is complete, otherwise it waits

    if (IProgress_getCanceled($IProgress) eq 'true') {
        addrow_msg_log("Cancelled creation of the clone $$cloneref{name}");
        IManagedObjectRef_release($cloneIMachine);
        $cloneIMachine = undef;
    }
    else {
        IMachine_saveSettings($cloneIMachine);
        IVirtualBox_registerMachine($gui{websn}, $cloneIMachine);
        addrow_msg_log("Cloned $$srcgref{Name} to $$cloneref{name}");
    }
}

# Creates a clone of a disk image
sub create_new_dskimg_clone {
    my ($newref, $srcIMedium) = @_;
    my $imgfile = rcatfile($$newref{location}, $$newref{diskname});
    $imgfile = add_ext_if_needed($imgfile, $$newref{imgformat});
    my $IMedium = IVirtualBox_createMedium($gui{websn}, $$newref{imgformat}, $imgfile, $$newref{mode}, $$newref{devicetype});
    my $IProgress = IMedium_cloneTo($srcIMedium, $IMedium, $$newref{allocation}, undef);
    show_progress_window($IProgress, 'Copying or Cloning Disk Image', $gui{pb}{ProgressMediaCreate});

    if (IProgress_getCanceled($IProgress) eq 'true') {
        addrow_msg_log("Cancelled disk copy or cloning: $imgfile");
        IManagedObjectRef_release($IMedium);
        $IMedium = undef;
    }
    elsif (IMedium_refreshState($IMedium) eq 'NotCreated') {
        show_err_msg('diskimgcreation', 0, "Disk Image: $imgfile");
        IManagedObjectRef_release($IMedium);
        $IMedium = undef;
    }
    else {
        addrow_msg_log("Copied or cloned disk image to new file: $imgfile");
    }

    Gtk3::main_iteration while Gtk3::events_pending;
    return $IMedium;
}

# Creates a new hard disk or floppy image and shows a progress window
sub create_new_dskimg {
    my ($newref) = @_;
    my $imgfile = rcatfile($$newref{location}, $$newref{diskname});
    $imgfile = add_ext_if_needed($imgfile, $$newref{imgformat});
    my $IMedium = IVirtualBox_createMedium($gui{websn}, $$newref{imgformat}, $imgfile, $$newref{mode}, $$newref{devicetype});
    # Note: Modified in the vboxService.pm. We expect an array reference in $$newref{allocation}
    my $IProgress = IMedium_createBaseStorage($IMedium, $$newref{size}, @{$$newref{allocation}});
    show_progress_window($IProgress, 'Creating Disk Image', $gui{pb}{ProgressMediaCreate});

    if (IProgress_getCanceled($IProgress) eq 'true') {
        addrow_msg_log("Cancelled disk image creation: $imgfile");
        IManagedObjectRef_release($IMedium);
        $IMedium = undef;
    }
    elsif (IMedium_refreshState($IMedium) eq 'NotCreated') {
        show_err_msg('diskimgcreation', 0, "Disk Image: $imgfile");
        IManagedObjectRef_release($IMedium);
        $IMedium = undef;
    }
    else {
        addrow_msg_log("Created new disk image: $imgfile");
    }

    Gtk3::main_iteration while Gtk3::events_pending;
    return $IMedium;
}

sub newgen_osfam {
    my ($combofam, $combover) = @_;
    my ($osfam, $osver) = osfamver();
    my $fam = getsel_combo($combofam, 1);
    $combofam->signal_handler_block($signal{New_cboxFamily_changed}); # Block to avoid signal emission when changing
    $combover->signal_handler_block($signal{New_cboxVersion_changed});
    $gui{d}{New}{lstoreVersion}->clear();

    foreach my $ver (@{ $$osfam{$fam}{verids} })
    {
        my $iter = $gui{d}{New}{lstoreVersion}->append();
        $gui{d}{New}{lstoreVersion}->set($iter, [0, 1, 2, 3], [$$osver{$ver}{description}, $ver, $$osver{$ver}{platformArchitecture}, $$osver{$ver}{icon}]);
        $combover->set_active_iter($iter) if ($ver eq 'Windows10_64' | $ver eq 'Fedora_64' | $ver eq 'Solaris11_64' | $ver eq 'FreeBSD_64' | $ver eq 'DOS');
    }

    $combover->set_active(0) if ($combover->get_active() == -1);
    $combofam->signal_handler_unblock($signal{New_cboxFamily_changed});
    $combover->signal_handler_unblock($signal{New_cboxVersion_changed});
    $combover->signal_emit('changed'); # Force update of other fields based on OS
}

sub newgen_osver {
    my ($combover, $combofam) = @_;
    my $osver = osver();
    my $ver = getsel_combo($combover, 1);
    $combofam->signal_handler_block($signal{New_cboxFamily_changed}); # Avoid signal emission when changing
    $combover->signal_handler_block($signal{New_cboxVersion_changed});
    $gui{d}{New}{sbMemory}->set_value($$osver{$ver}{recommendedRAM});
    $gui{d}{New}{sbSize}->set_value($$osver{$ver}{recommendedHDD} / 1048576);
    $combofam->signal_handler_unblock($signal{New_cboxFamily_changed});
    $combover->signal_handler_unblock($signal{New_cboxVersion_changed});
}

sub newstor_new_exist {
    my ($widget) = @_;
    my $buttongrp = $widget->get_group();

    if ($$buttongrp[0]->get_active() == 1) {
        $gui{d}{New}{cboxExistingDisk}->set_sensitive(1); # This is use an existing HD
        $gui{d}{New}{HD}->set_sensitive(0);
    }
    else {
        $gui{d}{New}{cboxExistingDisk}->set_sensitive(0); # This is creating a new HD
        $gui{d}{New}{HD}->set_sensitive(1);
    }
}

# Handle the toggle startup disk selection
sub toggle_newstartupdisk {
    if ($gui{d}{New}{checkStartupDisk}->get_active() == 1) {
        $gui{d}{New}{radioNewDisk}->show();
        $gui{d}{New}{radioExistingDisk}->show();
        $gui{d}{New}{HD}->show();
        $gui{d}{New}{cboxExistingDisk}->show();
    }
    else {
        $gui{d}{New}{radioNewDisk}->hide();
        $gui{d}{New}{radioExistingDisk}->hide();
        $gui{d}{New}{HD}->hide();
        $gui{d}{New}{cboxExistingDisk}->hide();
    }
}

# Handle the generate new MACs depending on clone type
sub clone_type {
    if ($gui{d}{Clone}{cboxType}->get_active() == 2) { $gui{checkbuttonCloneNewMACs}->hide(); }
    else { $gui{checkbuttonCloneNewMACs}->show(); }
}

# Handle the radio button sensitivity when selecting an image format when
# creating a new hd for a new guest
sub sens_hdformatchanged {
    my $format = getsel_combo($gui{d}{New}{cboxFormat}, 1);
    $gui{d}{New}{radioDynamic}->set_active(1);

    if ($format eq 'vmdk') {
        $gui{d}{New}{radioDynamic}->set_sensitive(1);
        $gui{d}{New}{radioFixed}->set_sensitive(1);
        $gui{d}{New}{radioSplit}->set_sensitive(1);
    }
    elsif ($format eq 'vdi' or $format eq 'vhd') {
        $gui{d}{New}{radioDynamic}->set_sensitive(1);
        $gui{d}{New}{radioFixed}->set_sensitive(1);
        $gui{d}{New}{radioSplit}->set_sensitive(0);
    }
    else {
        $gui{d}{New}{radioDynamic}->set_sensitive(1);
        $gui{d}{New}{radioFixed}->set_sensitive(0);
        $gui{d}{New}{radioSplit}->set_sensitive(0);
    }
}

1;
