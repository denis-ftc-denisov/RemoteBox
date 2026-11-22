# Virtual Media Management
use strict;
use warnings;
our (%gui);

# Registers a medium with the VMM
sub register_medium {
    my ($widget, $data) = @_;
    my $IMedium = IVirtualBox_openMedium($gui{websn}, &rcatfile($$data{basedir}, $$data{file}), $$data{type}, $$data{mode}, 0);
    &addrow_msg_log("Registered $$data{type}: $$data{file} with VMM");
    return $IMedium;
}

sub show_dialog_vmm {
    &addrow_msg_log('Retrieving global media information');
    &busy_window($gui{d}{Main}{win}, 0, 'watch');
    &fill_list_vmmhd();
    &fill_list_vmmdvd();
    &fill_list_vmmfloppy();
    &addrow_msg_log('Retrieved global media information');
    &busy_window($gui{d}{Main}{win}, 0);
    $gui{d}{VMM}{dialog}->show_all();
    $gui{d}{VMM}{dialog}->run();
    $gui{d}{VMM}{dialog}->hide();
}

# Handles GUI changes when user selects a different tab
sub vmm_tabchanged {
    my ($widget, $focus, $page) = @_;
    &vmm_sens_unselected(); # Reset widgets as they are evaluated later

    if ($page == 0) { # We need to re-evaluate selection on tab change
        $gui{d}{VMM}{buttonAdd}->set_icon_widget($gui{d}{VMM}{imgHDAdd});
        $gui{d}{VMM}{buttonCreate}->set_icon_widget($gui{d}{VMM}{imgHDCreate});
        $gui{d}{VMM}{buttonCreate}->set_sensitive(1);
        $gui{d}{VMM}{buttonCopy}->set_icon_widget($gui{d}{VMM}{imgHDCopy});
        $gui{d}{VMM}{buttonMove}->set_icon_widget($gui{d}{VMM}{imgHDMove});
        $gui{d}{VMM}{buttonModify}->set_icon_widget($gui{d}{VMM}{imgHDModify});
        $gui{d}{VMM}{buttonRemove}->set_icon_widget($gui{d}{VMM}{imgHDRemove});
        $gui{d}{VMM}{buttonRelease}->set_icon_widget($gui{d}{VMM}{imgHDRelease});
        &onsel_list_vmmhd() if ($gui{d}{VMM}{treeviewHD}->get_selection->get_selected());
    }
    elsif ($page == 1) {
        $gui{d}{VMM}{buttonAdd}->set_icon_widget($gui{d}{VMM}{imgDVDAdd});
        $gui{d}{VMM}{buttonCreate}->set_icon_widget($gui{d}{VMM}{imgDVDCreate});
        $gui{d}{VMM}{buttonCreate}->set_sensitive(0);
        $gui{d}{VMM}{buttonCopy}->set_icon_widget($gui{d}{VMM}{imgDVDCopy});
        $gui{d}{VMM}{buttonMove}->set_icon_widget($gui{d}{VMM}{imgDVDMove});
        $gui{d}{VMM}{buttonModify}->set_icon_widget($gui{d}{VMM}{imgDVDModify});
        $gui{d}{VMM}{buttonRemove}->set_icon_widget($gui{d}{VMM}{imgDVDRemove});
        $gui{d}{VMM}{buttonRelease}->set_icon_widget($gui{d}{VMM}{imgDVDRelease});
        &onsel_list_vmmdvd() if ($gui{d}{VMM}{treeviewDVD}->get_selection->get_selected());
    }
    else {
        $gui{d}{VMM}{buttonAdd}->set_icon_widget($gui{d}{VMM}{imgFDAdd});
        $gui{d}{VMM}{buttonCreate}->set_icon_widget($gui{d}{VMM}{imgFDCreate});
        $gui{d}{VMM}{buttonCreate}->set_sensitive(1);
        $gui{d}{VMM}{buttonCopy}->set_icon_widget($gui{d}{VMM}{imgFDCopy});
        $gui{d}{VMM}{buttonMove}->set_icon_widget($gui{d}{VMM}{imgFDMove});
        $gui{d}{VMM}{buttonModify}->set_icon_widget($gui{d}{VMM}{imgFDModify});
        $gui{d}{VMM}{buttonRemove}->set_icon_widget($gui{d}{VMM}{imgFDRemove});
        $gui{d}{VMM}{buttonRelease}->set_icon_widget($gui{d}{VMM}{imgFDRelease});
        &onsel_list_vmmfloppy() if ($gui{d}{VMM}{treeviewFD}->get_selection->get_selected());
    }
}

# Releases a medium from a guest
sub vmm_release {
    my $mediumref;
    my $page = $gui{d}{VMM}{notebook}->get_current_page();
    my $warn = 0;

    if ($page == 0) { $mediumref = &getsel_list_vmmhd(); }
    elsif ($page == 1) { $mediumref = &getsel_list_vmmdvd(); }
    else { $mediumref = &getsel_list_vmmfloppy(); }

    my @guuids = IMedium_getMachineIds($$mediumref{IMedium}); # Dont use &get_imedium_attrs as only IMedium_get call in this sub

    foreach my $id (@guuids) {
        my $IMachine = IVirtualBox_findMachine($gui{websn}, $id);
        my @IMediumAttachment = IMachine_getMediumAttachments($IMachine);

        foreach my $attach (@IMediumAttachment) {
            if ($$attach{medium} eq $$mediumref{IMedium}) {
                my $sref = &get_session($IMachine);

                if ($page == 0) { # We have a HD
                    if ($$sref{Type} eq 'WriteLock') { # Cannot do it if it's a shared lock
                        IMachine_detachDevice($$sref{IMachine}, $$attach{controller}, $$attach{port}, $$attach{device});
                    }
                    else { $warn = 1; }
                }
                else { # We have a DVD or floppy instead
                    IMachine_mountMedium($$sref{IMachine}, $$attach{controller}, $$attach{port}, $$attach{device}, '', 1);
                }

                IMachine_saveSettings($$sref{IMachine});
                ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
            }
        }
    }

    if ($warn == 1) { &show_err_msg('mediuminuse', 0, "\nMedium: $$mediumref{Name}"); }
    else { &addrow_msg_log("Medium $$mediumref{Name} released."); }

    if ($page == 0) { &fill_list_vmmhd(); }
    elsif ($page == 1) { &fill_list_vmmdvd(); }
    else { &fill_list_vmmfloppy(); }
}

# Remove Hard Drive
sub vmm_rem {
    my $page = $gui{d}{VMM}{notebook}->get_current_page();

    if ($page == 0) {
        my $hdref = &getsel_list_vmmhd();
        $gui{d}{RemoveHD}{dialog}->show_all();
        my $response = $gui{d}{RemoveHD}{dialog}->run();
        $gui{d}{RemoveHD}{dialog}->hide();

        if ($response eq '1') { # Deletes Disk (not cancellable)
            my $MediumState = IMedium_refreshState($$hdref{IMedium});

            if ($MediumState eq 'Created' or $MediumState eq 'Inaccessible') {
                my $IProgress = IMedium_deleteStorage($$hdref{IMedium});
                &show_progress_window($IProgress, 'Deleting hard disk', $gui{pb}{ProgressMediaDelete});
                &addrow_msg_log("Deleted hard disk $$hdref{Name}.");
                &fill_list_vmmhd();
            }
            else { &show_err_msg('deletemedium', 0, "\nMedium: $$hdref{Name}"); }
        }
        elsif ($response eq '2') { # Removes Disk
            IMedium_close($$hdref{IMedium});
            &addrow_msg_log("Storage $$hdref{Name} removed");
            &fill_list_vmmhd();
        }
    }
    elsif ($page == 1) {
        my $dvdref = &getsel_list_vmmdvd();
        IMedium_close($$dvdref{IMedium});
        &addrow_msg_log("Storage $$dvdref{Name} removed");
        &fill_list_vmmdvd();
    }
    else {
        my $floppyref = &getsel_list_vmmfloppy();
        IMedium_close($$floppyref{IMedium});
        &addrow_msg_log("Storage $$floppyref{Name} removed");
        &fill_list_vmmfloppy();
    }
}

# Attempts to compact a hard disk image
sub vmm_compact {
    my $hdref = &getsel_list_vmmhd();
    my $MediumState = IMedium_refreshState($$hdref{IMedium});
    if ($MediumState eq 'Created') {
        my $IProgress = IMedium_compact($$hdref{IMedium});
        &show_progress_window($IProgress, 'Compacting hard disk', $gui{pb}{ProgressMediaResize}) if ($IProgress);
        &addrow_msg_log("Compacted disk image $$hdref{Name}");
        &fill_list_vmmhd();
    }
    else { &show_err_msg('compactmedium', 0, "\nMedium: $$hdref{Name}\nCurrent State: $MediumState"); }
}

# Move a medium to a new location
sub vmm_move_broker {
    my $page = $gui{d}{VMM}{notebook}->get_current_page();
    my $mediumref;

    if ($page == 0) {
        my $mediumref = &getsel_list_vmmhd();
        &show_dialog_vmm_move($mediumref, 'HardDisk');
    }
    elsif ($page == 1) {
        my $mediumref = &getsel_list_vmmdvd();
        &show_dialog_vmm_move($mediumref, 'DVD');
    }
    else {
        my $mediumref = &getsel_list_vmmfloppy();
        &show_dialog_vmm_move($mediumref, 'Floppy');
    }
}

# Adds a harddisk/dvd/floppy image to the VMM
sub vmm_add {
    my ($basedir, $filearrayref) = @_;
    my $page = $gui{d}{VMM}{notebook}->get_current_page();
    return if (!$basedir);

    if ($page == 0) {
            foreach my $hd (@{$filearrayref}) {
                next if (!$hd->{FileName});
                next if ($hd->{FileName} eq '..' or $hd->{Type} eq '(Dir)');
                &register_medium(undef, {type => 'HardDisk', mode => 'ReadWrite', basedir => $basedir, file => $hd->{FileName}});
            }

            &fill_list_vmmhd();
        }
        elsif ($page == 1) {
            foreach my $dvd (@{$filearrayref}) {
                next if (!$dvd->{FileName});
                next if ($dvd->{FileName} eq '..' or $dvd->{Type} eq '(Dir)');
                &register_medium(undef, {type => 'DVD', mode => 'ReadOnly', basedir => $basedir, file => $dvd->{FileName}});
            }

            &fill_list_vmmdvd();
        }
        else {
            foreach my $floppy (@{$filearrayref}) {
                next if (!$floppy->{FileName});
                next if ($floppy->{FileName} eq '..' or $floppy->{Type} eq '(Dir)');
                &register_medium(undef, {type => 'Floppy', mode => 'ReadWrite', basedir => $basedir, file => $floppy->{FileName}});
            }

            &fill_list_vmmfloppy();
        }
}

# Refreshes the media on the currently selected page
sub vmm_refresh_broker {
    my $page = $gui{d}{VMM}{notebook}->get_current_page();

    if ($page == 0) { &fill_list_vmmhd(); }
    elsif ($page == 1) { &fill_list_vmmdvd(); }
    else { &fill_list_vmmfloppy(); }
}

# Selects the type of media to create
sub vmm_create_broker {
    my $page = $gui{d}{VMM}{notebook}->get_current_page();
    my $vhost = &vhost();

    if ($page == 0) { &show_dialog_create_hd(undef, {IMachine => '', filename => &rcatfile($$vhost{machinedir}, 'HardDisk-' . int(rand(999999))), callback => \&vmm_refresh_broker}); }
    elsif ($page == 1) { } # Not implemented yet }
    else { &show_dialog_create_floppy(undef, {IMachine => '', filename => &rcatfile($$vhost{machinedir}, 'Floppy-' . int(rand(999999))), callback => \&vmm_refresh_broker}); }
}

# Selects the type of media to copy and convert
sub vmm_copy_broker {
    my $page = $gui{d}{VMM}{notebook}->get_current_page();

    if ($page == 0) { &show_dialog_vmm_copy_hd(); }
    elsif ($page == 1) { } # Not implemented yet
    else { &show_dialog_vmm_copy_floppy(); }
}

# Displays the move medium dialog
sub show_dialog_vmm_move {
    my ($mediumref, $devicetype) = @_;
    my $vhost = &vhost();
    $gui{d}{MoveMedium}{entrySrc}->set_text($$mediumref{Location});
    $gui{d}{MoveMedium}{entryDst}->set_text(&rcatfile($$vhost{machinedir}, $$mediumref{Name}));
    $gui{d}{MoveMedium}{dialog}->show_all();
    my $response = $gui{d}{MoveMedium}{dialog}->run();
    $gui{d}{MoveMedium}{dialog}->hide();

    if ($response eq 'ok') {
        my $IProgress = IMedium_moveTo($$mediumref{IMedium}, $gui{d}{MoveMedium}{entryDst}->get_text());
        &show_progress_window($IProgress, 'Moving medium', $gui{pb}{ProgressMediaMove}) if ($IProgress); # Note: An $IProgress is not always returned for move operations are some are very quick
        &addrow_msg_log('Moved medium ' . $$mediumref{Location} . ' to ' . $gui{d}{MoveMedium}{entryDst}->get_text());

        if ($devicetype eq 'HardDisk') { &fill_list_vmmhd(); }
        elsif ($devicetype eq 'DVD') { &fill_list_vmmdvd(); }
        else { &fill_list_vmmfloppy(); }
    }
}

# Displays the modify medium window
sub show_dialog_vmm_modify {
    my $vhost = &vhost();
    my $hdref = &getsel_list_vmmhd();
    my $hdsizemb = ceil($$hdref{LsizeInt} / 1048576);
    $gui{d}{ModifyHD}{sbSize}->set_range($hdsizemb, $$vhost{maxhdsizemb}); # Images cannot be shrunk, so pin the lowest value to the current disks size
    $gui{d}{ModifyHD}{sbSize}->set_value($hdsizemb);
    $gui{d}{ModifyHD}{entryHD}->set_text($$hdref{Name});
    &combobox_set_active_text($gui{d}{ModifyHD}{cboxType}, $$hdref{Type}, 0);
    $gui{d}{ModifyHD}{dialog}->show_all();
    my $response = $gui{d}{ModifyHD}{dialog}->run();
    $gui{d}{ModifyHD}{dialog}->hide();

    if ($response eq 'ok') {
        my $newhdsizemb = $gui{d}{ModifyHD}{sbSize}->get_value_as_int(); # Do any resize first because it may not be possible once the type has changed

        if ($newhdsizemb > $hdsizemb and $gui{d}{ModifyHD}{checkResize}->get_active()) {
            &addrow_msg_log("Resizing $$hdref{Name} ($hdsizemb MB -> $newhdsizemb MB)");
            my $IProgress = IMedium_resize($$hdref{IMedium}, ($newhdsizemb * 1048576));
            &show_progress_window($IProgress, 'Resizing Virtual Hard Disk Image', $gui{pb}{ProgressMediaResize}) if ($IProgress);
            my $MediumState = IMedium_refreshState($$hdref{IMedium}); # Make sure VB sees any size changes
            my $refreshsize = IMedium_getLogicalSize($$hdref{IMedium});
            &show_err_msg('nohdresize', 0, "\nMedium: $$hdref{Name}\nCurrent State: $MediumState") if (($refreshsize / 1048576) < $newhdsizemb); # See if actually got resized, not all types support resizing
        }

        my $newtype = &getsel_combo($gui{d}{ModifyHD}{cboxType}, 0);

        if ($$hdref{Type} ne $newtype) {
            &addrow_msg_log("Modifying image type of $$hdref{Name} ($$hdref{Type} -> $newtype)");
            IMedium_setType($$hdref{IMedium}, $newtype) if ($$hdref{Type} ne $newtype);
        }

        &fill_list_vmmhd();
    }
}

# Displays the copy and convert hard disk window
sub show_dialog_vmm_copy_hd {
    my $hdref = &getsel_list_vmmhd();
    $gui{d}{CopyHD}{entrySource}->set_text($$hdref{Location});
    my $newdisk = $$hdref{Location};
    $newdisk =~ m/(.*)\.[^.]+$/; # Strip any extension
    $gui{d}{CopyHD}{entryDest}->set_text($1 . '-copy-' . int(rand(999999)));
    $gui{d}{CopyHD}{cboxFormat}->set_active(0);
    $gui{d}{CopyHD}{radioDynamic}->set_sensitive(1);
    $gui{d}{CopyHD}{radioDynamic}->set_active(1);
    $gui{d}{CopyHD}{radioFixed}->set_sensitive(1);
    $gui{d}{CopyHD}{radioSplit}->set_sensitive(0);
    $gui{d}{CopyHD}{dialog}->show_all();
    my $response = $gui{d}{CopyHD}{dialog}->run;
    $gui{d}{CopyHD}{dialog}->hide();

    if ($response eq 'ok') {
        my ($vol, $dir, $file) = &rsplitpath($gui{d}{CopyHD}{entryDest}->get_text());
        my $variant = 'Standard'; # Standard is Dynamic

        if ($gui{d}{CopyHD}{radioFixed}->get_active()) { $variant = 'Fixed'; }
        elsif ($gui{d}{CopyHD}{radioSplit}->get_active()) { $variant = 'VmdkSplit2G'; }

        my %clonehd =   (diskname   => $file,
                         devicetype => 'HardDisk',
                         mode       => 'ReadWrite',
                         allocation => $variant,
                         imgformat  =>  &getsel_combo($gui{d}{CopyHD}{cboxFormat}, 1),
                         location   => $vol . $dir);
        my $srchdref = &getsel_list_vmmhd();
        &create_new_dskimg_clone(\%clonehd, $$srchdref{IMedium});
        &fill_list_vmmhd();
    }
}

# Displays the copy and convert floppy disk window
sub show_dialog_vmm_copy_floppy {
    my $fdref = &getsel_list_vmmfloppy();
    my $newfloppy = $$fdref{Location};
    $newfloppy =~ m/(.*)\.[^.]+$/; # Strip any extension
    $gui{d}{CopyFloppy}{entryDst}->set_text($1 . '-copy-' . int(rand(999999)));
    $gui{d}{CopyFloppy}{entrySrc}->set_text($$fdref{Location});
    $gui{d}{CopyFloppy}{dialog}->show_all();
    my $response = $gui{d}{CopyFloppy}{dialog}->run();
    $gui{d}{CopyFloppy}{dialog}->hide();

    if ($response eq 'ok') {
        my ($vol, $dir, $file) = &rsplitpath($gui{d}{CopyFloppy}{entryDst}->get_text());

            my %clonefd = (diskname   => $file,
                           devicetype => 'Floppy',
                           mode       => 'ReadWrite',
                           allocation => 'Standard',
                           imgformat  => 'raw',
                           location   => $vol . $dir);
            my $srcfdref = &getsel_list_vmmfloppy();
            &create_new_dskimg_clone(\%clonefd, $$srcfdref{IMedium});
            &fill_list_vmmfloppy();
    }
}

# Handle the radio button sensitivity when selecting an image format for copying
sub sens_copyhdformat {
    my $format = &getsel_combo($gui{d}{CopyHD}{cboxFormat}, 1);
    $gui{d}{CopyHD}{radioDynamic}->set_active(1);

    if ($format eq 'vmdk') {
        $gui{d}{CopyHD}{radioDynamic}->set_sensitive(1);
        $gui{d}{CopyHD}{radioFixed}->set_sensitive(1);
        $gui{d}{CopyHD}{radioSplit}->set_sensitive(1);
    }
    elsif ($format eq 'vdi' or $format eq 'vhd') {
        $gui{d}{CopyHD}{radioDynamic}->set_sensitive(1);
        $gui{d}{CopyHD}{radioFixed}->set_sensitive(1);
        $gui{d}{CopyHD}{radioSplit}->set_sensitive(0);
    }
    else {
        $gui{d}{CopyHD}{radioDynamic}->set_sensitive(1);
        $gui{d}{CopyHD}{radioFixed}->set_sensitive(0);
        $gui{d}{CopyHD}{radioSplit}->set_sensitive(0);
    }
}

# Run when there are no devices selected in the VMM and between tab changes
sub vmm_sens_unselected {
    $gui{d}{VMM}{labelType}->set_text('');
    $gui{d}{VMM}{labelAttachedTo}->set_text('');
    $gui{d}{VMM}{labelLocation}->set_text('');
    $gui{d}{VMM}{labelEncrypted}->set_text('');
    $gui{d}{VMM}{labelUUID}->set_text('');
    $gui{d}{VMM}{buttonRemove}->set_sensitive(0);
    $gui{d}{VMM}{buttonCopy}->set_sensitive(0);
    $gui{d}{VMM}{buttonMove}->set_sensitive(0);
    $gui{d}{VMM}{buttonModify}->set_sensitive(0);
    $gui{d}{VMM}{buttonRelease}->set_sensitive(0);
    $gui{d}{VMM}{buttonCompact}->set_sensitive(0);
}

# Changes the sensitivity of resize widgets depending if the user selects that option
sub vmm_modify_sens_resize {
    my ($widget) = @_;
    my $state = $widget->get_active();
    $gui{labelVMMModifyResizeHD}->set_sensitive($state);
    $gui{d}{ModifyHD}{sbSize}->set_sensitive($state);
}

# Displays the create a new floppy disk dialog. Creates & attaches based on options
# $data should be {IMachine => $IMachine, filename, callback => \&callbacksub}
sub show_dialog_create_floppy {
    my ($widget, $data) = @_;
    my $callback = $$data{callback};
    $gui{d}{CreateFloppy}{cboxSize}->set_active(1);
    $gui{d}{CreateFloppy}{entryImage}->set_text($$data{filename});

    do {
        $gui{d}{CreateFloppy}{dialog}->show_all;
        my $response = $gui{d}{CreateFloppy}{dialog}->run();

        if ($response eq 'ok') {
            # No validation needed on other entries
            if (!$gui{d}{CreateFloppy}{entryImage}->get_text()) { &show_err_msg('invalidname', 0); }
            else {
                $gui{d}{CreateFloppy}{dialog}->hide;
                my ($vol, $dir, $file) = &rsplitpath($gui{d}{CreateFloppy}{entryImage}->get_text());
                my $alloc = ['Fixed'];
                $alloc = ['Fixed', 'Formatted'] if ($gui{d}{CreateFloppy}{checkFAT12}->get_active());

                my %newfloppy = (diskname   => $file,
                                 devicetype => 'Floppy',
                                 mode       => 'ReadWrite',
                                 size       => &getsel_combo($gui{d}{CreateFloppy}{cboxSize}, 1),
                                 allocation => $alloc,
                                 imgformat  => 'raw',
                                 location   => $vol . $dir);

                my $IMedium = &create_new_dskimg(\%newfloppy);
                # Execute the callback. First paramater is calling widget
                &$callback($gui{d}{CreateFloppy}, {IMedium => $IMedium, type => 'Floppy'}) if ($callback);
            }
        }
        else { $gui{d}{CreateFloppy}{dialog}->hide; }

    } until (!$gui{d}{CreateFloppy}{dialog}->get_visible());
}

# Displays the create a new hard disk dialog. Creates & attaches based on options
sub show_dialog_create_hd {
    my ($widget, $data) = @_;
    my $vhost = &vhost();
    $gui{d}{CreateHD}{entryImage}->set_text($$data{filename});
    $gui{d}{CreateHD}{cboxFormat}->set_active(0);
    $gui{d}{CreateHD}{radioDynamic}->show();
    $gui{d}{CreateHD}{radioFixed}->show();
    $gui{d}{CreateHD}{radioSplit}->hide();
    $gui{d}{CreateHD}{sbSize}->set_range($$vhost{minhdsizemb}, $$vhost{maxhdsizemb});
    $gui{d}{CreateHD}{sbSize}->set_value(8192.00);

    do {
        $gui{d}{CreateHD}{dialog}->show_all();
        my $response = $gui{d}{CreateHD}{dialog}->run();

        if ($response eq 'ok') {
            # No validation needed on other entries
            if (!$gui{d}{CreateHD}{entryImage}->get_text()) { &show_err_msg('invalidname', 0); }
            else {
                $gui{d}{CreateHD}{dialog}->hide;
                my ($vol, $dir, $file) = &rsplitpath($gui{d}{CreateHD}{entryImage}->get_text());

                my %newhd = (diskname   => $file,
                             devicetype => 'HardDisk',
                             mode       => 'ReadWrite',
                             size       => $gui{d}{CreateHD}{sbSize}->get_value_as_int() * 1048576,
                             allocation => ['Standard'], # Standard == Dynamic Allocation
                             imgformat  => &getsel_combo($gui{d}{CreateHD}{cboxFormat}, 1),
                             location   => $vol . $dir);

                if ($gui{d}{CreateHD}{radioFixed}->get_active()) { $newhd{allocation} = ['Fixed']; }
                elsif ($gui{d}{CreateHD}{radioSplit}->get_active()) { $newhd{allocation} = ['VmdkSplit2G']; }
                my $IMedium = &create_new_dskimg(\%newhd);

                # Execute the callback. First paramater is calling widget
                &{$$data{callback}}($gui{d}{CreateHD}, {IMedium => $IMedium, type => 'HardDisk'}) if ($$data{callback});
            }
        }
        else { $gui{d}{CreateHD}{dialog}->hide; }

    } until (!$gui{d}{CreateHD}{dialog}->get_visible());
}

1;
