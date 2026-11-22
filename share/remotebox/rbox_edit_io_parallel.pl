# The Parallel page of the IO Settings
use strict;
use warnings;
our (%gui, %vmc);

sub init_edit_io_parallel {
    &set_pointer($gui{d}{Edit}{dialog}, 'watch');
    $gui{d}{Edit}{checkIOParallel}->set_active(&bl(IParallelPort_getEnabled($vmc{IParallelPort})));
    $gui{d}{Edit}{gridIOParallel}->set_sensitive($gui{d}{Edit}{checkIOParallel}->get_active()); # Ghost/Unghost other widgets based on parallel enabled
    $gui{d}{Edit}{entryIOParallelpath}->set_text(IParallelPort_getPath($vmc{IParallelPort}));
    my $pirq = IParallelPort_getIRQ($vmc{IParallelPort});
    my $pioport = sprintf('%X', IParallelPort_getIOBase($vmc{IParallelPort}));
    $gui{d}{Edit}{entryIOParallelirq}->set_text($pirq);
    $gui{d}{Edit}{entryIOParallelio}->set_text($pioport);
    $gui{d}{Edit}{entryIOParallelirq}->set_sensitive(0);
    $gui{d}{Edit}{entryIOParallelio}->set_sensitive(0);

    if ($pirq == 2 and uc($pioport) eq '3BC') { $gui{d}{Edit}{cboxIOParallelnum}->set_active(0); }
    elsif ($pirq == 7 and uc($pioport) eq '378') { $gui{d}{Edit}{cboxIOParallelnum}->set_active(1); }
    elsif ($pirq == 5 and uc($pioport) eq '278') { $gui{d}{Edit}{cboxIOParallelnum}->set_active(2); }
    else {
        $gui{d}{Edit}{cboxIOParallelnum}->set_active(3);
        $gui{d}{Edit}{entryIOParallelirq}->set_sensitive(1);
        $gui{d}{Edit}{entryIOParallelio}->set_sensitive(1);
    }

    &set_pointer($gui{d}{Edit}{dialog});
}

# Whether a parallel port is enabled
sub io_par {
    my ($widget) = @_;

    if ($vmc{SessionType} eq 'WriteLock') {
        my $state = $widget->get_active();
        # Set path when first enabled, avoids VB chucking a no path specified warning
        if ($state and !$gui{d}{Edit}{entryIOParallelpath}->get_text()) {
            $gui{d}{Edit}{entryIOParallelpath}->set_text('/dev/parport0');
            &io_par_path($gui{d}{Edit}{entryIOParallelpath});
        }

        IParallelPort_setEnabled($vmc{IParallelPort}, $state);
        $gui{d}{Edit}{gridIOParallel}->set_sensitive($state);
    }
}

# The parallel port IRQ number
sub io_par_irq {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $irq = int($gui{d}{Edit}{entryIOParallelirq}->get_text());
        $irq = 255 if ($irq > 255);
        $irq = 15 if ($irq > 15 and !$gui{d}{Edit}{checkSysAPIC}->get_active());
        IParallelPort_setIRQ($vmc{IParallelPort}, $irq);
    }

    return 0;
}

# The parallel port IO PORT
sub io_par_port {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $ioport = $gui{d}{Edit}{entryIOParallelio}->get_text();
        $ioport = 'FFFF' if (hex($ioport) > 65535);
        if ($ioport) { IParallelPort_setIOBase($vmc{IParallelPort}, hex($ioport)); }
    }

    return 0;
}

# The parallel port path
sub io_par_path {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $path = $gui{d}{Edit}{entryIOParallelpath}->get_text();
        if ($path) { IParallelPort_setPath($vmc{IParallelPort}, $path); }
    }

    return 0;
}

# The LPT port number to use
sub io_par_num {
    my ($widget) = @_;

    if ($vmc{SessionType} eq 'WriteLock') {
        my $portnum = &getsel_combo($widget, 0);

        if ($portnum eq 'LPT1') {
            $gui{d}{Edit}{entryIOParallelirq}->set_text('2');
            $gui{d}{Edit}{entryIOParallelio}->set_text('3BC');
        }
        elsif ($portnum eq 'LPT2') {
            $gui{d}{Edit}{entryIOParallelirq}->set_text('7');
            $gui{d}{Edit}{entryIOParallelio}->set_text('378');
        }
        elsif ($portnum eq 'LPT3') {
            $gui{d}{Edit}{entryIOParallelirq}->set_text('5');
            $gui{d}{Edit}{entryIOParallelio}->set_text('278');
        }

        if ($portnum ne 'Custom') {
            &io_par_irq($gui{d}{Edit}{entryIOParallelirq}, 0);
            &io_par_port($gui{d}{Edit}{entryIOParallelio}, 0);
            $gui{d}{Edit}{entryIOParallelirq}->set_sensitive(0);
            $gui{d}{Edit}{entryIOParallelio}->set_sensitive(0);
        }
        else {
            $gui{d}{Edit}{entryIOParallelirq}->set_sensitive(1);
            $gui{d}{Edit}{entryIOParallelio}->set_sensitive(1);
        }
    }
}

1;
