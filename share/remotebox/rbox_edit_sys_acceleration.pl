# The Acceleration page of the System Settings
use strict;
use warnings;
our (%gui, %vmc);

sub init_edit_sys_accel {
    &set_pointer($gui{d}{Edit}{dialog}, 'watch');
    $gui{d}{Edit}{checkSysNested}->set_active(&bl(IPlatformX86_getHWVirtExProperty($vmc{IPlatformX86}, 'NestedPaging')));
    $gui{d}{Edit}{checkSysVPID}->set_active(&bl(IPlatformX86_getHWVirtExProperty($vmc{IPlatformX86}, 'VPID')));
    &combobox_set_active_text($gui{d}{Edit}{cboxSysPara}, IMachine_getParavirtProvider($vmc{IMachine}), 1);
    &set_pointer($gui{d}{Edit}{dialog});
}

# Sets the paravirtualization interface
sub sys_accel_paravirt { if ($vmc{SessionType} eq 'WriteLock') { IMachine_setParavirtProvider($vmc{IMachine}, &getsel_combo($gui{d}{Edit}{cboxSysPara}, 1)); } }

# Whether the guest uses Nested Paging
sub sys_accel_nested_paging { if ($vmc{SessionType} eq 'WriteLock') { IPlatformX86_setHWVirtExProperty($vmc{IPlatformX86}, 'NestedPaging', $gui{d}{Edit}{checkSysNested}->get_active()); } }

# Whether the guest uses VPID
sub sys_accel_vpid { if ($vmc{SessionType} eq 'WriteLock') { IPlatformX86_setHWVirtExProperty($vmc{IPlatformX86}, 'VPID', $gui{d}{Edit}{checkSysVPID}->get_active()); } }

1;
