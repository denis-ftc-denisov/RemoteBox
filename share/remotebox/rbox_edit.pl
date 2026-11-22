# Editing Settings of a Guest
use strict;
use warnings;
our (%gui, %vmc);

# Show the Edit dialog for a Guest
sub show_dialog_edit {
    undef(%vmc);
    my $gref = &getsel_list_guest();
    return if (!$$gref{IMachine}); # Do nothing if it was a group double clicked
    &busy_window($gui{d}{Main}{win}, 0, 'watch');
    my $sref = &get_session($$gref{IMachine});

    if ($$sref{Lock} eq 'VM' or $$sref{Lock} eq 'Shared') {
        &addrow_msg_log("Retrieving guest settings for $$gref{Name}...");
        $vmc{IMachine} = $$sref{IMachine};
        $vmc{USBFilters} = IMachine_getUSBDeviceFilters($vmc{IMachine});
        $vmc{IFirmwareSettings} = IMachine_getFirmwareSettings($vmc{IMachine});
        $vmc{INvramStore} = IMachine_getNonVolatileStore($vmc{IMachine});
        $vmc{IGraphicsAdapter} = IMachine_getGraphicsAdapter($vmc{IMachine});
        $vmc{IAudioSettings} = IMachine_getAudioSettings($vmc{IMachine});
        $vmc{IAudioAdapter} = IAudioSettings_getAdapter($vmc{IAudioSettings});
        $vmc{IVRDEServer} = IMachine_getVRDEServer($vmc{IMachine});
        $vmc{IParallelPort} = IMachine_getParallelPort($vmc{IMachine}, 0);
        $vmc{IRecordingSettings} = IMachine_getRecordingSettings($vmc{IMachine});
        $vmc{IRecordingScreenSettings} = IRecordingSettings_getScreenSettings($vmc{IRecordingSettings}, 0); # We only support 1 screen.
        $vmc{IPlatform} = IMachine_getPlatform($vmc{IMachine});
        $vmc{IPlatformX86} = IPlatform_getX86($vmc{IPlatform});
        $vmc{IHost} = IVirtualBox_getHost($gui{websn});
        $vmc{Name} = $$gref{Name};
        $vmc{SessionType} = $$sref{Type};
        edit_tabchanged($gui{d}{Edit}{notebook}, 0, $gui{d}{Edit}{notebook}->get_current_page()); # Setup initial tab
        &addrow_msg_log('Guest settings retrieved');
        &busy_window($gui{d}{Main}{win}, 0);

        # Here we need to change some widgets depending on the lock type
        # because some settings cannot be changed while the guest is locked
        my $storagepage = $gui{d}{Edit}{notebook}->get_nth_page(3);
        my $iopage = $gui{d}{Edit}{notebook}->get_nth_page(6);
        my $genbasicpage = $gui{d}{Edit}{notebookGen}->get_nth_page(0);
        my $sysmotherboard = $gui{d}{Edit}{notebookSys}->get_nth_page(0);
        my $sysadvanced = $gui{d}{Edit}{notebookSys}->get_nth_page(2);
        my $sysaccel = $gui{d}{Edit}{notebookSys}->get_nth_page(3);
        my $sysbootpage = $gui{d}{Edit}{notebookSys}->get_nth_page(4);
        my $dispvideopage = $gui{d}{Edit}{notebookDisp}->get_nth_page(0);
        my $encryptionpage = $gui{d}{Edit}{notebookGen}->get_nth_page(3);

        if ($vmc{SessionType} eq 'WriteLock') {
            $gui{d}{Edit}{dialog}->set_title("Edit Settings - $$gref{Name}");
            $storagepage->set_sensitive(1);
            $iopage->set_sensitive(1);
            $genbasicpage->set_sensitive(1);
            # This can only be changed if there are no snapshots
            my $snapcount = IMachine_getSnapshotCount($vmc{IMachine});
            if ($snapcount) {
                $gui{d}{Edit}{entryGenSnapfolder}->set_sensitive(0);
                $gui{d}{Edit}{entryGenSnapfolder}->set_sensitive(0);
            }
            else {
                $gui{d}{Edit}{entryGenSnapfolder}->set_sensitive(1);
                $gui{d}{Edit}{buttonGenSnapfolder}->set_sensitive(1);
            }
            $sysmotherboard->set_sensitive(1);
            $sysadvanced->set_sensitive(1);
            $sysaccel->set_sensitive(1);
            $sysbootpage->set_sensitive(1);
            $encryptionpage->set_sensitive(1);
            $gui{d}{Edit}{scaleSysProcessor}->set_sensitive(1);
            $gui{d}{Edit}{checkSysPAE}->set_sensitive(1);
            $gui{d}{Edit}{checkSysVTX}->set_sensitive(1);
            $gui{d}{Edit}{checkSysHot}->set_sensitive(1);
            $dispvideopage->set_sensitive(1);
            $gui{d}{Edit}{checkDispRDPmultiple}->set_sensitive(1);
            $gui{d}{Edit}{checkAudio}->set_sensitive(1);
            $gui{d}{Edit}{checkNetwork}->set_sensitive(1);
            $gui{d}{Edit}{entryNetworkMAC}->set_sensitive(1);
            $gui{d}{Edit}{buttonNetworkMACgen}->set_sensitive(1);
            $gui{d}{Edit}{cboxNetworkAdapter}->set_sensitive(1);
            $gui{d}{Edit}{radioUSB1}->set_sensitive(1);
            $gui{d}{Edit}{radioUSB2}->set_sensitive(1);
            $gui{d}{Edit}{radioUSB3}->set_sensitive(1);
            $gui{d}{Edit}{checkUSB}->set_sensitive(1);
        }
        else {
            $gui{d}{Edit}{dialog}->set_title("Online Edit Settings - $$gref{Name}");
            $storagepage->set_sensitive(0);
            $iopage->set_sensitive(0);
            $genbasicpage->set_sensitive(0);
            $gui{d}{Edit}{entryGenSnapfolder}->set_sensitive(0);
            $gui{d}{Edit}{buttonGenSnapfolder}->set_sensitive(0);
            $sysmotherboard->set_sensitive(0);
            $sysadvanced->set_sensitive(0);
            $sysaccel->set_sensitive(0);
            $sysbootpage->set_sensitive(0);
            $encryptionpage->set_sensitive(0);
            $gui{d}{Edit}{scaleSysProcessor}->set_sensitive(0);
            $gui{d}{Edit}{checkSysPAE}->set_sensitive(0);
            $gui{d}{Edit}{checkSysVTX}->set_sensitive(0);
            $gui{d}{Edit}{checkSysHot}->set_sensitive(0);
            $dispvideopage->set_sensitive(0);
            $gui{d}{Edit}{checkDispRDPmultiple}->set_sensitive(0);
            $gui{d}{Edit}{checkAudio}->set_sensitive(0);
            $gui{d}{Edit}{checkNetwork}->set_sensitive(0);
            $gui{d}{Edit}{entryNetworkMAC}->set_sensitive(0);
            $gui{d}{Edit}{buttonNetworkMACgen}->set_sensitive(0);
            $gui{d}{Edit}{cboxNetworkAdapter}->set_sensitive(0);
            $gui{d}{Edit}{gridDispRecording}->set_sensitive(0);
            $gui{d}{Edit}{checkUSB}->set_sensitive(0);
            $gui{d}{Edit}{radioUSB1}->set_sensitive(0);
            $gui{d}{Edit}{radioUSB2}->set_sensitive(0);
            $gui{d}{Edit}{radioUSB3}->set_sensitive(0);
        }

        # Extradata doesn't get discarded on a cancel so we backup here and manually restore.
        my $floppya = IMachine_getExtraData($vmc{IMachine}, 'VBoxInternal/Devices/i82078/0/LUN#0/Config/Type');
        my $floppyb = IMachine_getExtraData($vmc{IMachine}, 'VBoxInternal/Devices/i82078/0/LUN#1/Config/Type');

        $gui{d}{Edit}{dialog}->show();
        my $response = $gui{d}{Edit}{dialog}->run;
        $gui{d}{Edit}{dialog}->hide;

        if ($response eq 'ok') {
            # We will apply encryption settings here as it's not possible to
            # do it in real time
            if ($gui{d}{Edit}{checkGenEncryption}->get_state()) {
                my $cipher = &getsel_combo($gui{d}{Edit}{cboxGenCiper}, 1);
                if ($cipher ne 'Unchanged') {

                    my $passwd1 = $gui{d}{Edit}{entryGenPass}->get_text();
                    my $passwd2 = $gui{d}{Edit}{entryGenConfirm}->get_text();

                    if ($passwd1) {
                        if ($passwd1 ne $passwd2) { &show_err_msg('encdiskpasswd', 0); }
                        else {
                            my @IMediumAttachment = IMachine_getMediumAttachments($vmc{IMachine});
                            my %used_key_ids; # So we only ask for a Key ID once

                            foreach my $attach (@IMediumAttachment) {
                                next if ($$attach{type} ne 'HardDisk');

                                if (&imedium_has_property($$attach{medium}, 'CRYPT/KeyStore')) {
                                    # Disk is already encryped, so see if we can re-encrypt it
                                    my $keyid = IMedium_getProperty($$attach{medium}, 'CRYPT/KeyId');

                                    if (!$used_key_ids{$keyid}) {
                                        my $npasswd = &show_dialog_decpasswd($$attach{medium}, $keyid);
                                        &encrypt_disk($$attach{medium}, $npasswd, $cipher, $passwd1, $vmc{Name}) if ($npasswd);
                                        $used_key_ids{$keyid} = $npasswd;
                                    }
                                }
                                else {
                                    &encrypt_disk($$attach{medium}, '', $cipher, $passwd1, $vmc{Name});
                                }
                            }
                        }
                    }
                }
            }
            IMachine_saveSettings($vmc{IMachine});
            &fill_list_guest();
            &addrow_msg_log("Saved all settings for $$gref{Name}");
        }
        else {
            IMachine_discardSettings($vmc{IMachine});
            # Restore the floppy drive types as discardSettings does not do this. But only IF there's a setting as the floppy drive may have been deleted already and explicitly saved
            IMachine_setExtraData($vmc{IMachine}, 'VBoxInternal/Devices/i82078/0/LUN#0/Config/Type', $floppya) if (IMachine_getExtraData($vmc{IMachine}, 'VBoxInternal/Devices/i82078/0/LUN#0/Config/Type'));
            IMachine_setExtraData($vmc{IMachine}, 'VBoxInternal/Devices/i82078/0/LUN#1/Config/Type', $floppyb) if (IMachine_getExtraData($vmc{IMachine}, 'VBoxInternal/Devices/i82078/0/LUN#1/Config/Type'));
            &addrow_msg_log("Discarded changed settings for $$gref{Name}");
        }

        undef(%vmc);
        &flush_pagecache();
        $gui{miAttachFloppy} = $gui{miAttachDVD} = $gui{miAttachHD} = $gui{menuAttachFloppy} =
        $gui{menuAttachDVD} = $gui{menuAttachHD} = $gui{menuAttachAdd} = $gui{menu}{USB} = undef; # These must be freed
    }
    else { &show_err_msg('settings', 0); }

    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
}

# Routine only retrieves the settings for a tab when the user clicks on it.
# Reduces latency when opening window. Cache is cleared when window is closed
{
    my %pagecache;

    sub edit_tabchanged {
        my ($widget, $focus, $page) = @_;

        if ($page == 0) { &edit_gen_tabchanged($gui{d}{Edit}{notebookGen}, 0, $gui{d}{Edit}{notebookGen}->get_current_page()); } # Setup initial tab as it'll aleady be open
        elsif ($page == 1) { &edit_sys_tabchanged($gui{d}{Edit}{notebookSys}, 0, $gui{d}{Edit}{notebookSys}->get_current_page()); } # Setup initial tab as it'll aleady be open
        elsif ($page == 2) { &edit_disp_tabchanged($gui{d}{Edit}{notebookDisp}, 0, $gui{d}{Edit}{notebookDisp}->get_current_page()); } # Setup initial tab as it'll aleady be open
        elsif ($page == 3) {
            # There's no notebook on the page to cache, cache it here
            if (!$pagecache{stor}{0}) {
                &init_edit_storage();
                $pagecache{stor}{0} = 1;
            }
        }
        elsif ($page == 4) {
            # There's no notebook on the page to cache, cache it here
            if (!$pagecache{audio}{0}) {
                &init_edit_audio();
                $pagecache{audio}{0} = 1;
            }
        }
        elsif ($page == 5) {
            # There's no notebook on the page to cache, cache it here
            if (!$pagecache{net}{0}) {
                &init_edit_network();
                $pagecache{net}{0} = 1;
            }
        }
        elsif ($page == 6) { &edit_io_tabchanged($gui{d}{Edit}{notebookIOPorts}, 0, $gui{d}{Edit}{notebookIOPorts}->get_current_page()); } # Setup initial tab as it'll aleady be open
        elsif ($page == 7) {
            # There's no notebook on the page to cache, cache it here
            if (!$pagecache{net}{0}) {
                &init_edit_usb();
                $pagecache{net}{0} = 1;
            }
        }
        elsif ($page == 8) {
            # There's no notebook on the page to cache, cache it here
            if (!$pagecache{net}{0}) {
                &init_edit_shared();
                $pagecache{net}{0} = 1;
            }
        }
    }

    sub edit_gen_tabchanged {
        my ($widget, $focus, $page) = @_;

        if ($pagecache{gen}{$page}) { } # Do Nothing, Page is Cached
        elsif ($page == 0) { &init_edit_gen_basic(); }
        elsif ($page == 1) { &init_edit_gen_advanced(); }
        elsif ($page == 2) { &init_edit_gen_description(); }
        elsif ($page == 3) { &init_edit_gen_encryption(); }
        $pagecache{gen}{$page} = 1;
    }

    sub edit_sys_tabchanged {
        my ($widget, $focus, $page) = @_;

        if ($pagecache{sys}{$page}) { } # Do Nothing, Page is Cached
        elsif ($page == 0) { &init_edit_sys_mother(); }
        elsif ($page == 1) { &init_edit_sys_proc(); }
        elsif ($page == 2) { &init_edit_sys_adv(); }
        elsif ($page == 3) { &init_edit_sys_accel(); }
        elsif ($page == 4) { &init_edit_sys_logo(); }
        $pagecache{sys}{$page} = 1;
    }

    sub edit_disp_tabchanged {
        my ($widget, $focus, $page) = @_;

        if ($pagecache{disp}{$page}) { } # Do Nothing, Page is Cached
        elsif ($page == 0) { &init_edit_disp_screen(); }
        elsif ($page == 1) { &init_edit_disp_remote(); }
        elsif ($page == 2) { &init_edit_disp_capture(); }
        $pagecache{disp}{$page} = 1;
    }

    sub edit_io_tabchanged {
        my ($widget, $focus, $page) = @_;

        if ($pagecache{io}{$page}) { } # Do Nothing, Page is Cached
        elsif ($page == 0) { &init_edit_io_serial(); }
        elsif ($page == 1) { &init_edit_io_parallel(); }
        $pagecache{io}{$page} = 1;
    }

    sub flush_pagecache { undef %pagecache; }
};

1;
