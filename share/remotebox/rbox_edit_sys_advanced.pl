# The Advanced page of the System Settings
use strict;
use warnings;
our (%gui, %vmc);

sub init_edit_sys_adv {
    set_pointer($gui{d}{Edit}{dialog}, 'watch');
    $gui{d}{Edit}{sbSysTime}->set_value(IFirmwareSettings_getTimeOffset($vmc{IFirmwareSettings}));
    $gui{d}{Edit}{checkSysLargepages}->set_active(bl(IPlatformX86_getHWVirtExProperty($vmc{IPlatformX86}, 'LargePages')));
    $gui{d}{Edit}{checkSysHPET}->set_active(bl(IPlatformX86_getHPETEnabled($vmc{IPlatformX86})));
    $gui{d}{Edit}{checkSysFusion}->set_active(bl(IMachine_getPageFusionEnabled($vmc{IMachine})));
    set_pointer($gui{d}{Edit}{dialog});
}

# Sets whether the guest will be involved in 'memory dedupe'
sub sys_adv_page_fusion { if ($vmc{SessionType} eq 'WriteLock') { IMachine_setPageFusionEnabled($vmc{IMachine}, $gui{d}{Edit}{checkSysFusion}->get_active()); } }

# Whether to use large pages instead of the normal page size
sub sys_adv_large_pages { if ($vmc{SessionType} eq 'WriteLock') { IPlatformX86_setHWVirtExProperty($vmc{IPlatformX86}, 'LargePages', $gui{d}{Edit}{checkSysLargepages}->get_active()); } }

# Sets whether the guest has a High Precision Event Timer
sub sys_adv_hpet { if ($vmc{SessionType} eq 'WriteLock') { IPlatformX86_setHPETEnabled($vmc{IPlatformX86}, $gui{d}{Edit}{checkSysHPET}->get_active()); } }

# Sets whether the guest clock runs at a time offset
sub sys_adv_time_offset {
    if ($vmc{SessionType} eq 'WriteLock') {
        IFirmwareSettings_setTimeOffset($vmc{IFirmwareSettings}, $gui{d}{Edit}{sbSysTime}->get_value_as_int());
        return 0; # Must return this value for the signal used.
    }
}

1;
