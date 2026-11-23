# The Motherboard page of the System Settings
use strict;
use warnings;
our (%gui, %vmc, %signal);

# Sets up the initial state of the system tab of the edit settings dialog
sub init_edit_sys_mother {
    set_pointer($gui{d}{Edit}{dialog}, 'watch');
    my $vhost = vhost();
    $gui{d}{Edit}{buttonSysBootup}->set_sensitive(0);
    $gui{d}{Edit}{buttonSysBootdown}->set_sensitive(0);
    clr_list_generic($gui{d}{Edit}{treeviewSysBoot}, $signal{Edit_treeviewSysBoot_cursorchanged});

    # Secureboot requires EFI so only enable it. It may also need to be initialised ultimately
    $gui{d}{Edit}{checkSysSecure}->signal_handler_block($signal{Edit_checkSysSecure_toggled});

    if (IFirmwareSettings_getFirmwareType($vmc{IFirmwareSettings}) =~ m/^EFI/) {
        $gui{d}{Edit}{checkSysEFI}->set_active(1);
        $gui{d}{Edit}{checkSysSecure}->set_sensitive(1);
        $gui{d}{Edit}{buttonSysSecure}->set_sensitive(1);
        my $IUefiVariableStore = INvramStore_getUefiVariableStore($vmc{INvramStore});
        if (!defined($IUefiVariableStore)) { $gui{d}{Edit}{checkSysSecure}->set_active(0); }
        else { $gui{d}{Edit}{checkSysSecure}->set_active(bl(IUefiVariableStore_getSecureBootEnabled($IUefiVariableStore)));}
    }
    else {
        $gui{d}{Edit}{checkSysEFI}->set_active(0);
        $gui{d}{Edit}{checkSysSecure}->set_active(0);
        $gui{d}{Edit}{checkSysSecure}->set_sensitive(0);
        $gui{d}{Edit}{buttonSysSecure}->set_sensitive(0);
    }

    $gui{d}{Edit}{checkSysSecure}->signal_handler_unblock($signal{Edit_checkSysSecure_toggled});
    $gui{d}{Edit}{sbSysMemory}->set_range($$vhost{minguestram}, $$vhost{memsize});
    $gui{d}{Edit}{sbSysMemory}->set_value(IMachine_getMemorySize($vmc{IMachine}));
    $gui{d}{Edit}{checkSysAPIC}->set_active(bl(IFirmwareSettings_getIOAPICEnabled($vmc{IFirmwareSettings})));
    $gui{d}{Edit}{checkSysUTC}->set_active(bl(IPlatform_getRTCUseUTC($vmc{IPlatform})));
    combobox_set_active_text($gui{d}{Edit}{cboxSysChipset}, IPlatform_getChipsetType($vmc{IPlatform}), 1);
    combobox_set_active_text($gui{d}{Edit}{cboxSysPoint}, IMachine_getPointingHIDType($vmc{IMachine}), 1);
    combobox_set_active_text($gui{d}{Edit}{cboxSysKeyboard}, IMachine_getKeyboardHIDType($vmc{IMachine}), 1);

    # Default to maxbootpos+1 to mean 'not set in boot order' but this number needs to be higher than
    # true boot order numbers so the disabled devices appear at the end of the list.
    my %bootorder = (Floppy   => $$vhost{maxbootpos} + 1,
                     DVD      => $$vhost{maxbootpos} + 1,
                     HardDisk => $$vhost{maxbootpos} + 1,
                     Network  => $$vhost{maxbootpos} + 1);

    my %devdesc = (Floppy   => 'Floppy Disk',
                   DVD      => 'Optical Disc',
                   HardDisk => 'Hard Disk',
                   Network  => 'Network');

    # Find boot order and set value in hash accordingly. Empty boot slots return 'Null' so skip them
    foreach (1..$$vhost{maxbootpos}) {
        my $bootdev = IMachine_getBootOrder($vmc{IMachine}, $_);
        next if ($bootdev eq 'Null');
        $bootorder{$bootdev} = $_;
    }

    # Returns hash keys sorted by value (ie boot order). Disabled devices appear at end
    foreach my $dev (sort {$bootorder{$a} cmp $bootorder{$b}} keys %bootorder) {
        if ($bootorder{$dev} == $$vhost{maxbootpos} + 1) {
            my $iter = $gui{d}{Edit}{lstoreSysBoot}->append();
            $gui{d}{Edit}{lstoreSysBoot}->set($iter, [0, 1, 2, 3], [0, $dev, $gui{pb}{$dev}, $devdesc{$dev}]);
       }
        else {
            my $iter = $gui{d}{Edit}{lstoreSysBoot}->append();
            $gui{d}{Edit}{lstoreSysBoot}->set($iter, [0, 1, 2, 3], [1, $dev, $gui{pb}{$dev}, $devdesc{$dev}]);
        }
    }

    # Set up the TPM Section
    $gui{d}{Edit}{cboxSysTPM}->signal_handler_block($signal{Edit_cboxSysTPM_changed});
    $gui{d}{Edit}{lstoreSysTPM}->clear();
    foreach (@{$$vhost{tpmtypes}}) {
        my $name = $_;
        $name =~s /_/./;
        my $tpmiter = $gui{d}{Edit}{lstoreSysTPM}->append();
        $gui{d}{Edit}{lstoreSysTPM}->set($tpmiter, [0, 1], [$name, $_]);
    }

    my $ITrustedPlatformModule = IMachine_getTrustedPlatformModule($vmc{IMachine});
    combobox_set_active_text($gui{d}{Edit}{cboxSysTPM}, ITrustedPlatformModule_getType($ITrustedPlatformModule), 1);
    $gui{d}{Edit}{cboxSysTPM}->signal_handler_unblock($signal{Edit_cboxSysTPM_changed});
    set_pointer($gui{d}{Edit}{dialog});
}

# Sets the amount of main system memory
sub sys_mother_mem {
    if ($vmc{SessionType} eq 'WriteLock') { IMachine_setMemorySize($vmc{IMachine}, $gui{d}{Edit}{sbSysMemory}->get_value_as_int()); }
}

# Sets with IO APIC should be enabled or not in the guest
sub sys_mother_ioapic {
    if ($vmc{SessionType} eq 'WriteLock') { IFirmwareSettings_setIOAPICEnabled($vmc{IFirmwareSettings}, $gui{d}{Edit}{checkSysAPIC}->get_active()); }
}

# Sets whether the machine should use EFI or the traditional BIOS
sub sys_mother_efi {
    if ($vmc{SessionType} eq 'WriteLock') {
        if ($gui{d}{Edit}{checkSysEFI}->get_active() == 1) {

            IFirmwareSettings_setFirmwareType($vmc{IFirmwareSettings}, 'EFI');
            # Annoyingly this method generates an error if there is no variable store and there's no other way to check.
            my $IUefiVariableStore = INvramStore_getUefiVariableStore($vmc{INvramStore});

            if (!$IUefiVariableStore) {
                # If there's no UEFI variable store, then make one
                show_err_msg('noefivariables', 0, '');
                INvramStore_initUefiVariableStore($vmc{INvramStore});
                $IUefiVariableStore = INvramStore_getUefiVariableStore($vmc{INvramStore});
                IUefiVariableStore_enrollDefaultMsSignatures($IUefiVariableStore);
                IUefiVariableStore_enrollOraclePlatformKey($IUefiVariableStore);
            }

            $gui{d}{Edit}{checkSysSecure}->set_active(bl(IUefiVariableStore_getSecureBootEnabled($IUefiVariableStore)));
            $gui{d}{Edit}{checkSysSecure}->set_sensitive(1);
            $gui{d}{Edit}{buttonSysSecure}->set_sensitive(1);
        }
        else {
            IFirmwareSettings_setFirmwareType($vmc{IFirmwareSettings}, 'BIOS');
            $gui{d}{Edit}{checkSysSecure}->set_sensitive(0);
            $gui{d}{Edit}{buttonSysSecure}->set_sensitive(0);
        }
    }
}

# Removes all secureboot keys and adds in the defaults
sub sys_mother_restore_secureboot {
    if ($vmc{SessionType} eq 'WriteLock') {

        if (my $IUefiVariableStore = INvramStore_getUefiVariableStore($vmc{INvramStore})) {
            $gui{d}{SecureBoot}{dialog}->show_all();
            my $response = $gui{d}{SecureBoot}{dialog}->run();
            $gui{d}{SecureBoot}{dialog}->hide();

            if ($response eq 'ok') {
                # Due to the weird way the variables are returned (in a single array) we need to split
                # it in half and create new arrays
                my (@vars) = IUefiVariableStore_queryVariables($IUefiVariableStore);
                my $midpoint = int(@vars / 2);
                my @names = @vars[0..$midpoint - 1];
                my @uuids = @vars[$midpoint..$#vars];

                # Delete any platform keys
                for my $i (0..$#names) {
                    IUefiVariableStore_deleteVariable($IUefiVariableStore, $names[$i], $uuids[$i]) if ($names[$i] eq 'PK' or $names[$i] eq 'KEK' or $names[$i] eq 'db');
                }

                # Enrol defaults again
                IUefiVariableStore_enrollDefaultMsSignatures($IUefiVariableStore);
                IUefiVariableStore_enrollOraclePlatformKey($IUefiVariableStore);
            }
        }
    }
}

# Sets the type of TPM connected
sub sys_mother_tpm {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $ITrustedPlatformModule = IMachine_getTrustedPlatformModule($vmc{IMachine});
        ITrustedPlatformModule_setType($ITrustedPlatformModule, getsel_combo($gui{d}{Edit}{cboxSysTPM}, 1));
    }
}

# Sets whether the guest clock is UTC or local time
sub sys_mother_utc {
    if ($vmc{SessionType} eq 'WriteLock') { IPlatform_setRTCUseUTC($vmc{IPlatform}, $gui{d}{Edit}{checkSysUTC}->get_active()); }
}

# Sets whether secure boot is enabled
sub sys_mother_secureboot {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $IUefiVariableStore = INvramStore_getUefiVariableStore($vmc{INvramStore});

        if (!defined($IUefiVariableStore)) {
            show_err_msg('nouefivarfile', 0);
            INvramStore_initUefiVariableStore($vmc{INvramStore}, 0);
            $IUefiVariableStore = INvramStore_getUefiVariableStore($vmc{INvramStore});
        };

        IUefiVariableStore_setSecureBootEnabled($IUefiVariableStore, $gui{d}{Edit}{checkSysSecure}->get_active());
    }
}

# Sets the emulated pointing (eg mouse) device
sub sys_mother_pointer {
    if ($vmc{SessionType} eq 'WriteLock') { IMachine_setPointingHIDType($vmc{IMachine}, getsel_combo($gui{d}{Edit}{cboxSysPoint}, 1)); }
}

# Sets the emulatyed keyboard type
sub sys_mother_keyboard {
    if ($vmc{SessionType} eq 'WriteLock') { IMachine_setKeyboardHIDType($vmc{IMachine}, getsel_combo($gui{d}{Edit}{cboxSysKeyboard}, 1)); }
}

# Sets the emulated motherboard chipset
sub sys_mother_chipset {
    if ($vmc{SessionType} eq 'WriteLock') { IPlatform_setChipsetType($vmc{IPlatform}, getsel_combo($gui{d}{Edit}{cboxSysChipset}, 1)); }
}

# Moves the boot device to a higher priority
sub sys_mother_boot_dev_up {
    if ($vmc{SessionType} eq 'WriteLock') {
        my ($liststore, $iter) = $gui{d}{Edit}{treeviewSysBoot}->get_selection->get_selected();
        my $path = $liststore->get_path($iter);
        $path->prev; # Modifies path directly
        my $iter_prev = $liststore->get_iter($path);
        $liststore->move_before($iter, $iter_prev) if (defined($iter_prev) and $liststore->iter_is_valid($iter_prev));
    }
}

# Moves the boot device to a lower priority
sub sys_mother_boot_dev_down {
    if ($vmc{SessionType} eq 'WriteLock') {
        my ($liststore, $iter) = $gui{d}{Edit}{treeviewSysBoot}->get_selection->get_selected();
        my (undef, $iter_next) = $gui{d}{Edit}{treeviewSysBoot}->get_selection->get_selected();
        $liststore->iter_next($iter_next); # Modifies the iter directly - hence the above call twice
        $liststore->move_after($iter, $iter_next) if (defined($iter_next) and $liststore->iter_is_valid($iter_next));
    }
}

sub sys_mother_boot_order {
    my $liststore = $gui{d}{Edit}{treeviewSysBoot}->get_model();
    my $iter = $liststore->get_iter_first();
    my $i = 1;

    while (defined($iter) and $liststore->iter_is_valid($iter)) {
        my $dev = $liststore->get($iter, 1);
        $dev = 'Null' if ($liststore->get($iter, 0) == 0);
        IMachine_setBootOrder($vmc{IMachine}, $i, $dev);
        $liststore->iter_next($iter); # Modifies the iter directly
        $i++;
    }
}

# Sets the sensitivity when a boot item is selected
sub sys_mother_sens_boot_sel {
    $gui{d}{Edit}{buttonSysBootup}->set_sensitive(1);
    $gui{d}{Edit}{buttonSysBootdown}->set_sensitive(1);
}

sub sys_mother_boot_dev_toggle {
    my ($widget, $path_str) = @_;
    my $iter = $gui{d}{Edit}{lstoreSysBoot}->get_iter(Gtk3::TreePath->new_from_string($path_str));
    my $val = $gui{d}{Edit}{lstoreSysBoot}->get($iter, 0);
    $gui{d}{Edit}{lstoreSysBoot}->set ($iter, 0, !$val); # Always set the opposite of val to act as a toggle
}

1;
