# The Boot Logo page of the System Settings
use strict;
use warnings;
our (%gui, %vmc);

sub init_edit_sys_logo {
    set_pointer($gui{d}{Edit}{dialog}, 'watch');
    $gui{d}{Edit}{entrySysLogo}->set_text(IFirmwareSettings_getLogoImagePath($vmc{IFirmwareSettings}));
    $gui{d}{Edit}{sbSysLogotime}->set_value(IFirmwareSettings_getLogoDisplayTime($vmc{IFirmwareSettings}));
    $gui{d}{Edit}{checkSysFadein}->set_active(bl(IFirmwareSettings_getLogoFadeIn($vmc{IFirmwareSettings})));
    $gui{d}{Edit}{checkSysFadeout}->set_active(bl(IFirmwareSettings_getLogoFadeOut($vmc{IFirmwareSettings})));
    set_pointer($gui{d}{Edit}{dialog});
}

# Sets an alternative BIOS boot screen (BMP)
sub sys_logo_path {
    if ($vmc{SessionType} eq 'WriteLock') {
        IFirmwareSettings_setLogoImagePath($vmc{IFirmwareSettings}, $gui{d}{Edit}{entrySysLogo}->get_text());
        return 0;
    }
}

# The amount of time to display the BIOS boot logo
sub sys_logo_disp_time {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $time = $gui{d}{Edit}{sbSysLogotime}->get_value_as_int();
        $time = 65535 if ($time > 65535);
        $time = 0 if ($time < 0);
        IFirmwareSettings_setLogoDisplayTime($vmc{IFirmwareSettings}, $time);
        return 0; # Must return this value for the signal used.
    }
}

# Whether to fade the BIOS boot logo in
sub sys_logo_fade_in { if ($vmc{SessionType} eq 'WriteLock') { IFirmwareSettings_setLogoFadeIn($vmc{IFirmwareSettings}, $gui{d}{Edit}{checkSysFadein}->get_active()); } }

# Whether to fade the BIOS boot logo out
sub sys_logo_fade_out { if ($vmc{SessionType} eq 'WriteLock') { IFirmwareSettings_setLogoFadeOut($vmc{IFirmwareSettings}, $gui{d}{Edit}{checkSysFadeout}->get_active()); } }

1;
