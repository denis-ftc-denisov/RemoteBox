# The Serial page of the IO Settings
use strict;
use warnings;
our (%gui, %vmc);

sub init_edit_io_serial {
    set_pointer($gui{d}{Edit}{dialog}, 'watch');
    my $port = getsel_combo($gui{d}{Edit}{cboxIOSerial}, 1);
    my $ISerialPort = IMachine_getSerialPort($vmc{IMachine}, $port);
    my $irq = ISerialPort_getIRQ($ISerialPort);
    my $ioport = sprintf('%X', ISerialPort_getIOAddress($ISerialPort));
    my $mode = ISerialPort_getHostMode($ISerialPort);
    $gui{d}{Edit}{checkIOSerial}->set_active(bl(ISerialPort_getEnabled($ISerialPort)));
    $gui{d}{Edit}{gridIOSerial}->set_sensitive($gui{d}{Edit}{checkIOSerial}->get_active()); # Ghost/Unghost other widgets based on serial enabled
    $gui{d}{Edit}{checkIOSerialpipe}->set_active(!bl(ISerialPort_getServer($ISerialPort)));
    $gui{d}{Edit}{entryIOSerialpath}->set_text(ISerialPort_getPath($ISerialPort));
    $gui{d}{Edit}{entryIOSerialirq}->set_text($irq);
    $gui{d}{Edit}{entryIOSerialio}->set_text($ioport);
    $gui{d}{Edit}{entryIOSerialirq}->set_sensitive(0);
    $gui{d}{Edit}{entryIOSerialio}->set_sensitive(0);

    if ($irq == 4 and uc($ioport) eq '3F8') { $gui{d}{Edit}{cboxIOSerialnum}->set_active(0); }
    elsif ($irq == 3 and uc($ioport) eq '2F8') { $gui{d}{Edit}{cboxIOSerialnum}->set_active(1); }
    elsif ($irq == 4 and uc($ioport) eq '3E8') { $gui{d}{Edit}{cboxIOSerialnum}->set_active(2); }
    elsif ($irq == 3 and uc($ioport) eq '2E8') { $gui{d}{Edit}{cboxIOSerialnum}->set_active(3); }
    else {
        $gui{d}{Edit}{cboxIOSerialnum}->set_active(4);
        $gui{d}{Edit}{entryIOSerialirq}->set_sensitive(1);
        $gui{d}{Edit}{entryIOSerialio}->set_sensitive(1);
    }

    $gui{d}{Edit}{checkIOSerialpipe}->set_active(bl(ISerialPort_getServer($ISerialPort))); # Setting the pipe MUST come before setting the mode
    combobox_set_active_text($gui{d}{Edit}{cboxIOSerialmode}, $mode, 0);
    $gui{d}{Edit}{checkIOSerialpipe}->set_active(bl(ISerialPort_getServer($ISerialPort)));
    combobox_set_active_text($gui{d}{Edit}{cboxIOSerialuart}, ISerialPort_getUartType($ISerialPort), 1);
    set_pointer($gui{d}{Edit}{dialog});
}

# Whether the serial port is enabled
sub io_ser {
    my ($widget) = @_;

    if ($vmc{SessionType} eq 'WriteLock') {
        my $state = $widget->get_active();
        my ($ISerialPort, $port) = io_ser_callout();
        ISerialPort_setEnabled($ISerialPort, $state);
        $gui{d}{Edit}{gridIOSerial}->set_sensitive($state);
    }
}

# The IRQ to use for the serial port
sub io_ser_irq {
    my ($widget, $focus) = @_;

    if ($vmc{SessionType} eq 'WriteLock') {
        my $irq = int($widget->get_text());
        $irq = 255 if ($irq > 255);
        $irq = 15 if ($irq > 15 and !$gui{d}{Edit}{checkSysAPIC}->get_active());
        my ($ISerialPort, $port) = io_ser_callout();
        ISerialPort_setIRQ($ISerialPort, $irq);
    }

    return 0;
}

# The IO Port to use for the serial port
sub io_ser_port {
    my ($widget) = @_;

    if ($vmc{SessionType} eq 'WriteLock') {
        my $ioport = $widget->get_text();
        $ioport = 'FFFF' if (hex($ioport) > 65535);

        if ($ioport) {
            my ($ISerialPort, $port) = io_ser_callout();
            ISerialPort_setIOAddress($ISerialPort, hex($ioport));
        }
    }

    return 0;
}

# Attempt to generate an appropriate port path automatically.
sub io_ser_path_generate {
    my ($widget) = @_;
    my $vhost = vhost();

    # For all serial modes except disconnected, it needs a path set
    # before it can be activated, otherwise it errors.
    if ($vmc{SessionType} eq 'WriteLock') {
        my ($ISerialPort, $port) = io_ser_callout();
        my $mode = getsel_combo($gui{d}{Edit}{cboxIOSerialmode}, 0);

        if ($mode eq 'RawFile') {
            $$vhost{os} =~ m/^WINDOWS/i ? $gui{d}{Edit}{entryIOSerialpath}->set_text("\%temp\%\\raw-$vmc{Name}-ser" . ($port + 1))
                                        : $gui{d}{Edit}{entryIOSerialpath}->set_text("/tmp/raw-$vmc{Name}-ser" . ($port + 1));
        }
        elsif ($mode eq 'HostPipe') {
            $$vhost{os} =~ m/^WINDOWS/i ? $gui{d}{Edit}{entryIOSerialpath}->set_text("\\\\.\\pipe\\pipe-$vmc{Name}-ser" . ($port + 1))
                                        : $gui{d}{Edit}{entryIOSerialpath}->set_text("/tmp/pipe-$vmc{Name}-ser" . ($port + 1));
        }
        elsif ($mode eq 'HostDevice') {
            my $device = '/dev/null';
            if ($$vhost{os} =~ m/Linux/i) { $device = '/dev/ttyS' . $port; }
            elsif ($$vhost{os} =~ m/WINDOWS/i) { $device = 'COM' . ($port + 1) . ':'; }
            elsif ($$vhost{os} =~ m/Darwin/i) { $device = '/dev/null'; }
            elsif ($$vhost{os} =~ m/Solaris/i) { $device = '/dev/cua'; }
            elsif ($$vhost{os} =~ m/FreeBSD/i) { $device = '/dev/cuad' . $port; }
            $gui{d}{Edit}{entryIOSerialpath}->set_text($device);
        }
        elsif ($mode eq 'TCP') { $gui{d}{Edit}{entryIOSerialpath}->set_text('65000'); }
        else { $gui{d}{Edit}{entryIOSerialpath}->set_text(''); } # Disconnected mode (it won't actually get saved by VB tho

        $gui{d}{Edit}{entryIOSerialpath}->signal_emit('activate');
    }
}

# The serial port mode
sub io_ser_mode {
    my ($widget) = @_;
    my $vhost = vhost();

    # For all serial modes except disconnected, it needs a path set before it can be activated, otherwise it errors.
    if ($vmc{SessionType} eq 'WriteLock') {
        my ($ISerialPort, $port) = io_ser_callout();
        my $mode = getsel_combo($widget, 0);

        # If the path is empty, try to generate one to avoid errors as every mode except disconnected
        # cannot be empty.
        if (ISerialPort_getPath($ISerialPort) eq '') { io_ser_path_generate(); }
        ISerialPort_setHostMode($ISerialPort, getsel_combo($widget, 0));
    }
}

# Whether to automatically create a PIPE when opening the serial port
sub io_ser_make_pipe {
    my ($widget) = @_;

    if ($vmc{SessionType} eq 'WriteLock') {
        my ($ISerialPort, $port) = io_ser_callout();
        ISerialPort_setServer($ISerialPort, !$widget->get_active());
    }
}

# The serial port path
sub io_ser_path {
    my ($widget) = @_;

    if ($vmc{SessionType} eq 'WriteLock') {

        my $path = $widget->get_text();
        if ($path) {
            my ($ISerialPort, $port) = io_ser_callout();
            ISerialPort_setPath($ISerialPort, $path);
        }
    }

    return 0;
}

# The COM port number to use for the serial port
sub io_ser_num {
    my ($widget) = @_;

    if ($vmc{SessionType} eq 'WriteLock') {
        my $portnum = getsel_combo($widget, 0);
        my ($ISerialPort, $port) = io_ser_callout();

        if ($portnum eq 'COM1') {
            $gui{d}{Edit}{entryIOSerialirq}->set_text('4');
            $gui{d}{Edit}{entryIOSerialio}->set_text('3F8');
        }
        elsif ($portnum eq 'COM2') {
            $gui{d}{Edit}{entryIOSerialirq}->set_text('3');
            $gui{d}{Edit}{entryIOSerialio}->set_text('2F8');
        }
        elsif ($portnum eq 'COM3') {
            $gui{d}{Edit}{entryIOSerialirq}->set_text('4');
            $gui{d}{Edit}{entryIOSerialio}->set_text('3E8');
        }
        elsif ($portnum eq 'COM4') {
            $gui{d}{Edit}{entryIOSerialirq}->set_text('3');
            $gui{d}{Edit}{entryIOSerialio}->set_text('2E8');
        }

        if ($portnum ne 'Custom') {
            io_ser_irq($gui{d}{Edit}{entryIOSerialirq});
            io_ser_port($gui{d}{Edit}{entryIOSerialio});
            $gui{d}{Edit}{entryIOSerialirq}->set_sensitive(0);
            $gui{d}{Edit}{entryIOSerialio}->set_sensitive(0);
        }
        else {
            $gui{d}{Edit}{entryIOSerialirq}->set_sensitive(1);
            $gui{d}{Edit}{entryIOSerialio}->set_sensitive(1);
        }
    }
}

# Set the type of UART
sub io_ser_uart {
    my ($widget) = @_;

    if ($vmc{SessionType} eq 'WriteLock') {
        my ($ISerialPort, $port) = io_ser_callout();
        ISerialPort_setUartType($ISerialPort, getsel_combo($widget, 1));
    }
}

# Gets the current working serial port number
sub io_ser_callout {
    my $port = getsel_combo($gui{d}{Edit}{cboxIOSerial}, 1);

    if ($vmc{SessionType} eq 'WriteLock') {
        my $ISerialPort = IMachine_getSerialPort($vmc{IMachine}, $port);
        return $ISerialPort, $port;
    }
}

1;
