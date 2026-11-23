# The Processor page of the System Settings
use strict;
use warnings;
our (%gui, %vmc);

sub init_edit_sys_proc {
    set_pointer($gui{d}{Edit}{dialog}, 'watch');
    my $vhost = vhost();
    $gui{d}{Edit}{scaleSysProcessor}->set_range($$vhost{minguestcpu}, $$vhost{maxhostcpuon} + 1); # +1 works around GTK bug
    $gui{d}{Edit}{scaleSysProcessor}->set_value(IMachine_getCPUCount($vmc{IMachine}));
    $gui{d}{Edit}{scaleSysCap}->set_value(IMachine_getCPUExecutionCap($vmc{IMachine}));
    $gui{d}{Edit}{checkSysPAE}->set_active(bl(IPlatformX86_getCPUProperty($vmc{IPlatformX86}, 'PAE')));
    $gui{d}{Edit}{checkSysVTX}->set_active(bl(IPlatformX86_getCPUProperty($vmc{IPlatformX86}, 'HWVirt')));
    $gui{d}{Edit}{checkSysHot}->set_active(bl(IMachine_getCPUHotPlugEnabled($vmc{IMachine})));
    set_pointer($gui{d}{Edit}{dialog});
}

# Toggle the processor hotplug flag
sub sys_proc_hotplug {
    if ($vmc{SessionType} eq 'WriteLock') {
        # if true we are about to enable hotplug otherwise disable
        if ($gui{d}{Edit}{checkSysHot}->get_active()) {
            IMachine_setCPUHotPlugEnabled($vmc{IMachine}, 1);
        }
        else {
            # If disabling hot plug we must offline the CPUs first
            my $cpucount = IMachine_getCPUCount($vmc{IMachine});

            foreach my $num (1..($cpucount-1)) {
                IMachine_hotUnplugCPU($vmc{IMachine}, $num) if (bl(IMachine_getCPUStatus($vmc{IMachine}, $num)));
            }
            IMachine_setCPUCount($vmc{IMachine}, 1);
            IMachine_setCPUHotPlugEnabled($vmc{IMachine}, 0);
            IMachine_setCPUCount($vmc{IMachine}, $cpucount);
        }
    }
}

# Set the number of processors. The exact mechanism varies depending on hot plug mode
sub sys_proc_count {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $newcpucount = int($gui{d}{Edit}{adjSysProcessor} ->get_value());

        # In hot-plug mode, if we reduce the number of CPUs, we must offline them first.
        if (bl(IMachine_getCPUHotPlugEnabled($vmc{IMachine}))) {
            my $curcpucount = IMachine_getCPUCount($vmc{IMachine});

            if ($newcpucount < $curcpucount) {
                foreach my $num ($newcpucount..($curcpucount-1)) {
                    IMachine_hotUnplugCPU($vmc{IMachine}, $num) if (bl(IMachine_getCPUStatus($vmc{IMachine}, $num)));
                }
            }
        }

        IMachine_setCPUCount($vmc{IMachine}, $newcpucount);
    }
}

# Sets the processor execution cap
sub sys_proc_cap {
    IMachine_setCPUExecutionCap($vmc{IMachine}, int($gui{d}{Edit}{adjSysCap}->get_value()));
}


# Whether the guest uses Physical Address Extensions and No Execution
sub sys_proc_pae { if ($vmc{SessionType} eq 'WriteLock') { IPlatformX86_setCPUProperty($vmc{IPlatformX86}, 'PAE', $gui{d}{Edit}{checkSysPAE}->get_active()); } }

# Whether Nested Hardware Virtualization is enabled on processors which support it
sub sys_proc_nested_vtx { if ($vmc{SessionType} eq 'WriteLock') { IPlatformX86_setCPUProperty($vmc{IPlatformX86}, 'HWVirt', $gui{d}{Edit}{checkSysVTX}->get_active()); } }

1;
