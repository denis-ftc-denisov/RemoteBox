# The Basic page of the General Settings
use strict;
use warnings;
our (%gui, %signal, %vmc);

sub init_edit_gen_basic {
    &set_pointer($gui{d}{Edit}{dialog}, 'watch');
    my ($osfam, $osver) = &osfamver();
    my $Name = IMachine_getName($vmc{IMachine});
    my $Osid = IMachine_getOSTypeId($vmc{IMachine});
    $gui{d}{Edit}{cboxGenFamily}->signal_handler_block($signal{Edit_cboxGenFamily_changed});
    $gui{d}{Edit}{cboxGenVersion}->signal_handler_block($signal{Edit_cboxGenVersion_changed});
    $gui{d}{Edit}{lstoreGenFamily}->clear();
    $gui{d}{Edit}{lstoreGenVersion}->clear();
    my $IGuestOSType = IVirtualBox_getGuestOSType($gui{websn}, $Osid);
    $gui{d}{Edit}{entryGenName}->set_text($Name);

    foreach (sort {
                    if    ($$osfam{$a}{description} =~ m/Other/) { return 1; }
                    elsif ($$osfam{$b}{description} =~ m/Other/) { return -1; }
                    else  { return lc($$osfam{$a}{description}) cmp lc($$osfam{$b}{description}) }
                  } keys %{$osfam}) {
        my $iter = $gui{d}{Edit}{lstoreGenFamily}->append();
        $gui{d}{Edit}{lstoreGenFamily}->set($iter, [0, 1, 2], [$$osfam{$_}{description}, $_, $$osfam{$_}{icon}]);
        $gui{d}{Edit}{cboxGenFamily}->set_active_iter($iter) if ($_ eq $$IGuestOSType{familyId});
    }

    foreach (@{$$osfam{$$IGuestOSType{familyId}}{verids}}) {
        my $iter = $gui{d}{Edit}{lstoreGenVersion}->append();
        $gui{d}{Edit}{lstoreGenVersion}->set($iter, [0, 1, 2], [$$osver{$_}{description}, $_, $$osver{$_}{icon}]);
        $gui{d}{Edit}{cboxGenVersion}->set_active_iter($iter) if ($_ eq $$IGuestOSType{id});
    }

    $gui{d}{Edit}{cboxGenFamily}->signal_handler_unblock($signal{Edit_cboxGenFamily_changed});
    $gui{d}{Edit}{cboxGenVersion}->signal_handler_unblock($signal{Edit_cboxGenVersion_changed});
    &set_pointer($gui{d}{Edit}{dialog});
}

# Sets the name of the guest
sub gen_basic_name {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $name = $gui{d}{Edit}{entryGenName}->get_text();
        IMachine_setName($vmc{IMachine}, $name) if ($name);
        return 0;
    }
}

sub gen_basic_os_family {
    my ($combofam, $combover) = @_;
    my ($osfam, $osver) = &osfamver();
    my $fam = &getsel_combo($combofam, 1);
    $combofam->signal_handler_block($signal{Edit_cboxGenFamily_changed}); # Block to avoid signal emission when changing
    $combover->signal_handler_block($signal{Edit_cboxGenVersion_changed});
    $gui{d}{Edit}{lstoreGenVersion}->clear();

    foreach (sort {
                    if    ($$osver{$a}{description} =~ m/Other/) { return 1; }
                    elsif ($$osver{$b}{description} =~ m/Other/) { return -1; }
                    else  { return lc($$osver{$a}{description}) cmp lc($$osver{$b}{description}) }

                  } @{ $$osfam{$fam}{verids} }) {
        my $iter = $gui{d}{Edit}{lstoreGenVersion}->append();
        $gui{d}{Edit}{lstoreGenVersion}->set($iter, [0, 1, 2], [$$osver{$_}{description}, $_, $$osver{$_}{icon}]);
        $combover->set_active_iter($iter) if ($_ eq 'Windows10_64' | $_ eq 'Fedora_64' | $_ eq 'Solaris11_64'| $_ eq 'FreeBSD_64' | $_ eq 'DOS');
    }

    $combover->set_active(0) if ($combover->get_active() == -1);
    $combofam->signal_handler_unblock($signal{Edit_cboxGenFamily_changed});
    $combover->signal_handler_unblock($signal{Edit_cboxGenVersion_changed});
    $combover->signal_emit('changed'); # Force update of other fields based on OS
}

sub gen_basic_os_version {
    my ($combover) = @_;
    my $ver = &getsel_combo($combover, 1);
    IMachine_setOSTypeId($vmc{IMachine}, $ver);
}

1;
