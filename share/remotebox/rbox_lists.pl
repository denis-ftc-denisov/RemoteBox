# List Handling
use strict;
use warnings;
use utf8;

our (%gui, %vmc, %signal, %prefs, $endpoint);

# Block for filling in guest details
{
    sub expand_details_row {
        my ($treeview, $treeiter, $treepath) = @_;
        my @row = $gui{d}{Main}{tstoreDetails}->get($treeiter);
        $prefs{$row[5]} = 1;
    }

    sub collapse_details_row {
        my ($treeview, $treeiter, $treepath) = @_;
        my @row = $gui{d}{Main}{tstoreDetails}->get($treeiter);
        $prefs{$row[5]} = 0;
    }

    # Fill a brief version of the guest details
    sub fill_list_details_brief {
        my $gref = getsel_list_guest();
        addrow_msg_log("Retrieving guest details for $$gref{Name}");
        $gui{d}{Main}{tstoreDetails}->clear();
        my $IGraphicsAdapter = IMachine_getGraphicsAdapter($$gref{IMachine});
        my $iter = addrow_details(undef, [0, 1, 3, 4, 5], [$gui{pb}{CatGen}, 'Guest Summary', 800, 0.0, 'EXPANDDETGEN']);
        addrow_details($iter, [1, 2], [' Name:', $$gref{Name}]);
        addrow_details($iter, [1, 2], [' Operating System:', IMachine_getOSTypeId($$gref{IMachine})]);
        my $mem = IMachine_getMemorySize($$gref{IMachine});
        $mem = ($mem > 1023) ? sprintf("%.2f GB", $mem / 1024) : "$mem MB";
        addrow_details($iter, [1, 2], [' Base Memory:', $mem]);
        addrow_details($iter, [1, 2], [' Video Memory:', IGraphicsAdapter_getVRAMSize($IGraphicsAdapter) . ' MB']);
        $gui{d}{Main}{treeviewDetails}->expand_row($gui{d}{Main}{tstoreDetails}->get_path($iter), 1) if ($prefs{EXPANDDETGEN});
        my $desciter = addrow_details(undef, [0, 1, 3, 4, 5], [$gui{pb}{CatDesc}, 'Description', 800, 0.0, 'EXPANDDETDESC']);
        my $desc = IMachine_getDescription($$gref{IMachine});
        $desc ? addrow_details($desciter, [1, 2], [' Description:', $desc]) : addrow_details($desciter, [1], [' <None>']);
        $gui{d}{Main}{treeviewDetails}->expand_row($gui{d}{Main}{tstoreDetails}->get_path($desciter), 1) if ($prefs{EXPANDDETDESC});
        addrow_msg_log("Guest details retrieved for $$gref{Name}");
    }

    # Fill the guest details
    sub fill_list_details {
        my $gref = getsel_list_guest();
        addrow_msg_log("Retrieving extended guest details for $$gref{Name}");
        my $vhost = vhost();
        $gui{d}{Main}{tstoreDetails}->clear();
        my $IVRDEServer = IMachine_getVRDEServer($$gref{IMachine});
        my @IStorageController = IMachine_getStorageControllers($$gref{IMachine});
        my $IAudioSettings = IMachine_getAudioSettings($$gref{IMachine});
        my $IAudioAdapter = IAudioSettings_getAdapter($IAudioSettings);
        my @IUSBController = IMachine_getUSBControllers($$gref{IMachine});
        my $IGraphicsAdapter = IMachine_getGraphicsAdapter($$gref{IMachine});
        my $IFirmwareSettings = IMachine_getFirmwareSettings($$gref{IMachine});
        my $IPlatform = IMachine_getPlatform($$gref{IMachine});
        my $IPlatformX86 = IPlatform_getX86($IPlatform);
        my $geniter = addrow_details(undef, [0, 1, 3, 4, 5], [$gui{pb}{CatGen}, 'General', 800, 0.0, 'EXPANDDETGEN']);
        addrow_details($geniter, [1, 2], [' Name:', $$gref{Name}]);
        addrow_details($geniter, [1, 2], [' Operating System:', IMachine_getOSTypeId($$gref{IMachine})]);
        $gui{d}{Main}{treeviewDetails}->expand_row($gui{d}{Main}{tstoreDetails}->get_path($geniter), 1) if ($prefs{EXPANDDETGEN});
        my $sysiter = addrow_details(undef, [0, 1, 3, 4, 5], [$gui{pb}{CatSys}, 'System', 800, 0.0, 'EXPANDDETSYS']);
        my $mem = IMachine_getMemorySize($$gref{IMachine});
        $mem = ($mem > 1023) ? sprintf("%.2f GB", $mem / 1024) : "$mem MB";
        addrow_details($sysiter, [1, 2], [' Base Memory:', $mem]);
        addrow_details($sysiter, [1, 2], [' Firmware:', IFirmwareSettings_getFirmwareType($IFirmwareSettings)]);
        addrow_details($sysiter, [1, 2], [' Processors:', IMachine_getCPUCount($$gref{IMachine})]);
        my $bootorder = '';

        foreach (1..4) {
            my $bdev = IMachine_getBootOrder($$gref{IMachine}, $_);
            $bootorder .= "$bdev  " if ($bdev ne 'Null');
        }

        $bootorder ? addrow_details($sysiter, [1, 2], [' Boot Order:', $bootorder]) : addrow_details($sysiter, [1, 2], [' Boot Order:', '<None Enabled>']);
        my $vtx = '';
        $vtx .= 'VT-x/AMD-V  ' if (IPlatformX86_getHWVirtExProperty($IPlatformX86, 'Enabled') eq 'true');
        $vtx .= 'VPID  ' if (IPlatformX86_getHWVirtExProperty($IPlatformX86, 'VPID') eq 'true');
        $vtx .= 'PAE/NX  ' if (IPlatformX86_getCPUProperty($IPlatformX86, 'PAE') eq 'true');
        $vtx .= 'Nested Paging  ' if (IPlatformX86_getHWVirtExProperty($IPlatformX86, 'NestedPaging') eq 'true');
        $vtx .= 'Nested VT-x/AMD-V  ' if (IPlatformX86_getCPUProperty($IPlatformX86, 'HWVirt') eq 'true');
        $vtx ? addrow_details($sysiter, [1, 2], [' Acceleration:', $vtx]) : addrow_details($sysiter, [1, 2], [' Acceleration:', '<None Enabled>']);
        my $paravirt = 'Configured: ' . IMachine_getParavirtProvider($$gref{IMachine}) . ', Effective: ' . IMachine_getEffectiveParavirtProvider($$gref{IMachine});
        addrow_details($sysiter, [1, 2], [' Paravirtualization:', $paravirt]);
        $gui{d}{Main}{treeviewDetails}->expand_row($gui{d}{Main}{tstoreDetails}->get_path($sysiter), 1) if ($prefs{EXPANDDETSYS});
        my $dispiter = addrow_details(undef, [0, 1, 3, 4, 5], [$gui{pb}{CatDisp}, 'Display', 800, 0.0, 'EXPANDDETDISP']);
        addrow_details($dispiter, [1, 2], [' Video Memory:', IGraphicsAdapter_getVRAMSize($IGraphicsAdapter) . ' MB']);
        addrow_details($dispiter, [1, 2], [' Screens: ', IGraphicsAdapter_getMonitorCount($IGraphicsAdapter)]);
        my $vidaccel = '';
        $vidaccel .= '3D  ' if (IGraphicsAdapter_isFeatureEnabled($IGraphicsAdapter, 'Acceleration3D') eq 'true');
        $vidaccel ? addrow_details($dispiter, [1, 2], [' Acceleration:', $vidaccel]) : addrow_details($dispiter, [1, 2], [' Acceleration:', '<None Enabled>']);
        IVRDEServer_getEnabled($IVRDEServer) eq 'true' ? addrow_details($dispiter, [1, 2], [' Remote Display Ports:', IVRDEServer_getVRDEProperty($IVRDEServer, 'TCP/Ports')])
                                                    : addrow_details($dispiter, [1, 2], [' Remote Display Ports:', '<Remote Display Disabled>']);
        $gui{d}{Main}{treeviewDetails}->expand_row($gui{d}{Main}{tstoreDetails}->get_path($dispiter), 1) if ($prefs{EXPANDDETDISP});

        my $storiter = addrow_details(undef, [0, 1, 3, 4, 5], [$gui{pb}{CatStor}, 'Storage', 800, 0.0, 'EXPANDDETSTOR']);
        foreach my $controller (@IStorageController) {
            my $controllername = IStorageController_getName($controller);
            addrow_details($storiter, [1, 2], [' Controller:', $controllername]);
            my @IMediumAttachment = IMachine_getMediumAttachmentsOfController($$gref{IMachine}, $controllername);
            foreach my $attachment (@IMediumAttachment) {
                if ($$attachment{medium}) {
                    IMedium_refreshState($$attachment{medium}); # Needed to bring in current sizes
                    # Use the base medium for information purposes
                    my $size = bytesToX(IMedium_getLogicalSize($$attachment{medium}));
                    my $encrypted = imedium_has_property($$attachment{medium}, 'CRYPT/KeyStore') ? 'Encrypted ' : '';
                    addrow_details($storiter, [1, 2], ["   Port $$attachment{port}:", IMedium_getName(IMedium_getBase($$attachment{medium})) . " ( $$attachment{type} $size $encrypted)"]);
                }
            }
        }

        $gui{d}{Main}{treeviewDetails}->expand_row($gui{d}{Main}{tstoreDetails}->get_path($storiter), 1) if ($prefs{EXPANDDETSTOR});

        my $audioiter = addrow_details(undef, [0, 1, 3, 4, 5], [$gui{pb}{CatAudio}, 'Audio', 800, 0.0, 'EXPANDDETAUDIO']);
        IAudioAdapter_getEnabled($IAudioAdapter) eq 'true' ? (addrow_details($audioiter, [1, 2], [' Host Driver:', IAudioAdapter_getAudioDriver($IAudioAdapter)])
                                                        and addrow_details($audioiter, [1, 2], [' Controller:', IAudioAdapter_getAudioController($IAudioAdapter)]))
                                                        : addrow_details($audioiter, 1, ' <Audio Disabled>');
        $gui{d}{Main}{treeviewDetails}->expand_row($gui{d}{Main}{tstoreDetails}->get_path($audioiter), 1) if ($prefs{EXPANDDETAUDIO});

        my $netiter = addrow_details(undef, [0, 1, 3, 4, 5], [$gui{pb}{CatNet}, 'Network', 800, 0.0, 'EXPANDDETNET']);
        foreach (0..($$vhost{maxnet}-1)) {
            my $INetworkAdapter = IMachine_getNetworkAdapter($$gref{IMachine}, $_);

            if (INetworkAdapter_getEnabled($INetworkAdapter) eq 'true') {
                my $attachtype = INetworkAdapter_getAttachmentType($INetworkAdapter);
                my $adapter = INetworkAdapter_getAdapterType($INetworkAdapter) . ' (' . $attachtype;

                if ($attachtype eq 'Bridged') { $adapter .= ', ' . INetworkAdapter_getBridgedInterface($INetworkAdapter); }
                elsif ($attachtype eq 'HostOnly') { $adapter .= ', ' . INetworkAdapter_getHostOnlyInterface($INetworkAdapter); }
                elsif ($attachtype eq 'Internal') { $adapter .= ', ' . INetworkAdapter_getInternalNetwork($INetworkAdapter); }

                $adapter .= ')';
                addrow_details($netiter, [1, 2], [" Adapter $_:", $adapter]);
            }
        }

        $gui{d}{Main}{treeviewDetails}->expand_row($gui{d}{Main}{tstoreDetails}->get_path($netiter), 1) if ($prefs{EXPANDDETNET});

        my $ioiter = addrow_details(undef, [0, 1, 3, 4, 5], [$gui{pb}{CatIO}, 'I/O Ports', 800, 0.0, 'EXPANDDETIO']);
        foreach (0..($$vhost{maxser}-1)) {
            my $ISerialPort = IMachine_getSerialPort($$gref{IMachine}, $_);
            ISerialPort_getEnabled($ISerialPort) eq 'true' ? addrow_details($ioiter, [1, 2], [" Serial Port #:" . ($_ + 1), 'Enabled  ' .
                                                                                            ISerialPort_getHostMode($ISerialPort) . '  ' .
                                                                                            ISerialPort_getPath($ISerialPort)])
                                                        : addrow_details($ioiter, [1, 2], [" Serial Port #:" . ($_ + 1), 'Disabled']);
        }

        my $IParallelPort = IMachine_getParallelPort($$gref{IMachine}, 0);
        IParallelPort_getEnabled($IParallelPort) eq 'true' ? addrow_details($ioiter, [1, 2], [' LPT Port:', 'Enabled  ' . IParallelPort_getPath($IParallelPort)])
                                                        : addrow_details($ioiter, [1, 2], [' LPT Port:', 'Disabled']);
        $gui{d}{Main}{treeviewDetails}->expand_row($gui{d}{Main}{tstoreDetails}->get_path($ioiter), 1) if ($prefs{EXPANDDETIO});

        my $usbiter = addrow_details(undef, [0, 1, 3, 4, 5], [$gui{pb}{CatUSB}, 'USB', 800, 0.0, 'EXPANDDETUSB']);
        if (@IUSBController) {
            foreach my $usbcontroller (@IUSBController) {
                my $usbver = IUSBController_getUSBStandard($usbcontroller);
                addrow_details($usbiter, [1, 2], [' Controller:', IUSBController_getName($usbcontroller) . ' (' . IUSBController_getType($usbcontroller) . ')']);
            }

            my $IUSBDeviceFilters = IMachine_getUSBDeviceFilters($$gref{IMachine});
            my @filters = IUSBDeviceFilters_getDeviceFilters($IUSBDeviceFilters);
            my $active = 0;
            foreach (@filters) { $active++ if (IUSBDeviceFilter_getActive($_) eq 'true'); }
            addrow_details($usbiter, [1, 2], ['  Device Filters:', scalar(@filters) . " ($active active)"]);
        }
        else { addrow_details($usbiter, 1, ' <None Enabled>'); }
        $gui{d}{Main}{treeviewDetails}->expand_row($gui{d}{Main}{tstoreDetails}->get_path($usbiter), 1) if ($prefs{EXPANDDETUSB});

        my $shareiter = addrow_details(undef, [0, 1, 3, 4, 5], [$gui{pb}{CatShare}, 'Shared Folders', 800, 0.0, 'EXPANDDETSHARE']);
        my @sf = IMachine_getSharedFolders($$gref{IMachine});
        addrow_details($shareiter, [1, 2], [' Shared Folders:', scalar(@sf)]);
        $gui{d}{Main}{treeviewDetails}->expand_row($gui{d}{Main}{tstoreDetails}->get_path($shareiter), 1) if ($prefs{EXPANDDETSHARE});

        my $sref = get_session($$gref{IMachine});

        if ($$sref{Lock} eq 'Shared') {
            my $runiter = addrow_details(undef, [0, 1, 3, 4, 5], [$gui{pb}{CatGen}, 'Runtime Details', 800, 0.0, 'EXPANDDETRUN']);
            my $IGuest = IConsole_getGuest(ISession_getConsole($$sref{ISession}));
            addrow_details($runiter, [1, 2], [' OS:', IGuest_getOSTypeId($IGuest)]);
            my $additionsversion = IGuest_getAdditionsVersion($IGuest);
            if ($additionsversion) { addrow_details($runiter, [1, 2], [' Guest Additions:', $additionsversion]); }
            else { addrow_details($runiter, [1, 2], [' Guest Additions:', 'Not Installed (or not running)']); }
            $gui{d}{Main}{treeviewDetails}->expand_row($gui{d}{Main}{tstoreDetails}->get_path($runiter), 1) if ($prefs{EXPANDDETRUN});
        }

        ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');

        my $desciter = addrow_details(undef, [0, 1, 3, 4, 5], [$gui{pb}{CatDesc}, 'Description', 800, 0.0, 'EXPANDDETDESC']);
        my $desc = IMachine_getDescription($$gref{IMachine});
        $desc ? addrow_details($desciter, [1, 2], [' Description:', $desc]) : addrow_details($desciter, 1, ' <None>');
        $gui{d}{Main}{treeviewDetails}->expand_row($gui{d}{Main}{tstoreDetails}->get_path($desciter), 1) if ($prefs{EXPANDDETDESC});
        addrow_msg_log("Extended guest details retrieved for $$gref{Name}");
    }
}

# Adds a row to the details view
sub addrow_details {
    my ($iter, $cols, $vals) = @_;
    my $citer = $gui{d}{Main}{tstoreDetails}->append($iter);
    $gui{d}{Main}{tstoreDetails}->set($citer, $cols, $vals);
    return $citer;
}

# Generic routine for clearing lists that need the signal disabled
sub clr_list_generic {
    my ($treeview, $signal) = @_;
    my $liststore = $treeview->get_model();
    $treeview->signal_handler_block($signal) if ($treeview);
    $liststore->clear();
    $treeview->signal_handler_unblock($signal) if ($treeview);
}

# Fills the remote file chooser with a list of files. Involves a lot of splicing because
# of the bizarre way VirtualBox returns a file list
sub fill_list_remotefiles {
    set_pointer($gui{d}{RemoteFileChooser}{dialog}, 'watch');
    my ($location, $filter) = @_;
    my $vhost = vhost();
    $location = rcanonpath($location);
    my $IProgress = IVFSExplorer_cd($gui{IVFSExplorer}, $location);
    IProgress_waitForCompletion($IProgress);

    if (bl(IProgress_getCompleted($IProgress)) and (IProgress_getResultCode($IProgress) == 0)) { # Only update the view if the CD is successful.
        clr_list_generic($gui{d}{RemoteFileChooser}{treeviewFile}, $signal{RemoteFileChooser_treeviewRemoteFileChooser_cursorChanged});
        IVFSExplorer_update($gui{IVFSExplorer});
        my @entries = IVFSExplorer_entryList($gui{IVFSExplorer});
        my $chop = (@entries / 4);
        my @filenames = splice @entries, 0, $chop;
        my @types = splice @entries, 0, $chop;
        my @sizes = splice @entries, 0, $chop;
        my @modes = splice @entries, 0, $chop;
        my %files;

        foreach my $ent (0..$#filenames) {
            $files{$filenames[$ent]}{type} = $types[$ent];
            $files{$filenames[$ent]}{size} = $sizes[$ent];
            $files{$filenames[$ent]}{mode} = sprintf "%o", $modes[$ent];
        }

        my $iter = $gui{d}{RemoteFileChooser}{lstoreFile}->append();
        $gui{d}{RemoteFileChooser}{lstoreFile}->set($iter, [0, 1, 2, 3, 4], ['(Parent)', '..', '', '', $gui{pb}{ParentIcon}]);

        foreach my $fname (sort { lc($a) cmp lc($b) } (keys %files)) {
            if ($files{$fname}{type} == 4) { # Always add in directories
                my $iter = $gui{d}{RemoteFileChooser}{lstoreFile}->append();
                $gui{d}{RemoteFileChooser}{lstoreFile}->set($iter, [0, 1, 2, 3, 4], ['(Dir)', $fname, $files{$fname}{size}, $files{$fname}{mode}, $gui{pb}{DirIcon}]);
            }
            elsif ($fname =~ m/$filter/i) { # Only add in if it matches the filter
                my $iter = $gui{d}{RemoteFileChooser}{lstoreFile}->append();
                $fname =~ m/^.*\.(.*)$/;
                my $ext = $1 ? lc(".$1") : ' ';
                $gui{d}{RemoteFileChooser}{lstoreFile}->set($iter, [0, 1, 2, 3, 4], [$ext, $fname, $files{$fname}{size}, $files{$fname}{mode}, $gui{pb}{FileIcon}]);
            }
        }

        $gui{d}{RemoteFileChooser}{entryLocation}->set_text(IVFSExplorer_getPath($gui{IVFSExplorer}));
    }
    else {
        IVFSExplorer_cdUp($gui{IVFSExplorer}); # Failed to CD, so the path needs to be set back to the previous one
        $gui{d}{RemoteFileChooser}{entryLocation}->set_text(IVFSExplorer_getPath($gui{IVFSExplorer}));
        show_err_msg('nodiraccess', 0, '');
    }

    set_pointer($gui{d}{RemoteFileChooser}{dialog});
}

# Fills a list as returned from reading the remote log file
sub fill_list_log {
    my ($IMachine) = @_;
    $gui{d}{GuestLog}{lstoreLog0}->clear();
    $gui{d}{GuestLog}{lstoreLog1}->clear();
    $gui{d}{GuestLog}{lstoreLog2}->clear();
    $gui{d}{GuestLog}{lstoreLog3}->clear();

    for my $lognum (0..3) {
        my ($offset, $log) = 0;

        if (IMachine_queryLogFilename($IMachine, $lognum)) {
            # Reading logs is limited to a maximum chunk size - normally 32K. The chunks are base64 encoded so we
            # need to read a chunk, decode, calculate next offset. Limit loop to 80 runs (max 2MB retrieval)
            for (1..80) {
                my $rawlog = IMachine_readLog($IMachine, $lognum, $offset, 32768); # Request 32K max. Limit is usually 32K anyway
                last if (!$rawlog); # Terminate loop if we've reached the end or log is empty
                $log .= decode_base64($rawlog); # Rawlog is base64 encoded. Append to log
                $offset = length($log); # Set next offset into log to get the next chunk
            }

            if ($log) {
                my @logarr = split "\n", $log;

                foreach (0..$#logarr) {
                    $logarr[$_] =~ s/\r//g; # Strip any carriage returns
                    my $iter = $gui{d}{GuestLog}{'lstoreLog' . $lognum}->append;
                    $gui{d}{GuestLog}{'lstoreLog' . $lognum}->set($iter, [0, 1], ["$_: ", $logarr[$_]]);
                }
            }
            else {
                my $iter = $gui{d}{GuestLog}{'lstoreLog' . $lognum}->append;
                $gui{d}{GuestLog}{'lstoreLog' . $lognum}->set($iter, [0, 1], ['', 'This log file is currently empty']);
            }

        }
        else {
            my $iter = $gui{d}{GuestLog}{'lstoreLog' . $lognum}->append;
            $gui{d}{GuestLog}{'lstoreLog' . $lognum}->set($iter, [0, 1], ['', 'This log file does not exist yet']);
        }
    }
}

# Fills a list of basic information about the remote server
sub fill_list_serverinfo {
    $gui{d}{ServerInfo}{lstoreInfo}->clear();
    my $vhost = vhost();
    addrow_info([0, 1], ['URL:', $endpoint]);
    addrow_info([0, 1], ['VirtualBox Version:', IVirtualBox_getVersion($gui{websn})]);
    $$vhost{vrdeextpack} ? addrow_info([0, 1], ['Extension Pack:', $$vhost{vrdeextpack}]) : addrow_info([0, 1], ['Extension Pack:', '<None>']);
    addrow_info([0, 1], ['Build Revision:', IVirtualBox_getRevision($gui{websn})]);
    addrow_info([0, 1], ['Package Type:', IVirtualBox_getPackageType($gui{websn})]);
    addrow_info([0, 1], ['Global Settings File:', IVirtualBox_getSettingsFilePath($gui{websn})]);
    addrow_info([0, 1], ['Machine Folder:', $$vhost{machinedir}]);
    addrow_info([0, 1], ['Server Logical CPUs:', $$vhost{maxhostcpuon}]);
    addrow_info([0, 1], ['Server CPU Type:', IHost_getProcessorDescription($$vhost{IHost})]);
    addrow_info([0, 1], ['Server CPU Speed:', IHost_getProcessorSpeed($$vhost{IHost}) . " Mhz (approx)"]);
    addrow_info([0, 1], ['VT-x/AMD-V Support:', IHost_getProcessorFeature($$vhost{IHost}, 'HWVirtEx')]);
    addrow_info([0, 1], ['VT-x/AMD-V Exclusive:', $$vhost{hwexclusive}]);
    addrow_info([0, 1], ['PAE Support:', IHost_getProcessorFeature($$vhost{IHost}, 'PAE')]);
    addrow_info([0, 1], ['Server Memory Size:', "$$vhost{memsize} MB"]);
    addrow_info([0, 1], ['Server OS:', $$vhost{os}]);
    addrow_info([0, 1], ['Server OS Version:', IHost_getOSVersion($$vhost{IHost})]);
    addrow_info([0, 1], ['Default Audio:', ISystemProperties_getDefaultAudioDriver($$vhost{ISystemProperties})]);
    addrow_info([0, 1], ['Min Guest RAM:', "$$vhost{minguestram} MB"]);
    addrow_info([0, 1], ['Max Guest RAM:', bytesToX($$vhost{maxguestram} * 1048576)]);
    addrow_info([0, 1], ['Min Guest Video RAM:', "$$vhost{minguestvram} MB"]);
    addrow_info([0, 1], ['Max Guest Video RAM:', "$$vhost{maxguestvram} MB"]);
    addrow_info([0, 1], ['Max Guest CPUs:', $$vhost{maxguestcpu}]);
    addrow_info([0, 1], ['Max Guest Monitors:', $$vhost{maxmonitors}]);
    addrow_info([0, 1], ['Max HD Image Size:', bytesToX($$vhost{maxhdsize})]);
    addrow_info([0, 1], ['Guest Additions ISO:', $$vhost{additionsiso}]);
    addrow_info([0, 1], ['Autostart DB:', $$vhost{autostartdb}]);
}

# Fills a list of of detect VNC / RDP clients
sub fill_list_rdpvncinfo {
    my %rdpclients = ('xfreerdp',  => 'FreeRDP',
                      'rdesktop',  => 'Rdesktop',
                      'mstsc.exe', => 'Windows RDP Client');

    my %vncclients = ('vncviewer', => 'TigerVNC or RealVNC',
                      'vinagre',   => 'Vinagre');

    my %bothclients = ('remmina', => 'Remmina',
                       'krdc',    => 'KRDC');


    $gui{d}{RDPVNCInfo}{lstoreInfo}->clear();

    foreach my $client (keys(%rdpclients)) {
        my $loc = which($client);
        $loc ? addrow_rdpvncinfo([0, 1, 2], [$rdpclients{$client}, 'RDP', $loc]) : addrow_rdpvncinfo([0, 1, 2], [$rdpclients{$client}, 'RDP', '<Not Detected>']);
    }

    foreach my $client (keys(%vncclients)) {
        my $loc = which($client);
        $loc ? addrow_rdpvncinfo([0, 1, 2], [$vncclients{$client}, 'VNC', $loc]) : addrow_rdpvncinfo([0, 1, 2], [$vncclients{$client}, 'VNC', '<Not Detected>']);
    }

    foreach my $client (keys(%bothclients)) {
        my $loc = which($client);
        $loc ? addrow_rdpvncinfo([0, 1, 2], [$bothclients{$client}, 'RDP & VNC', $loc]) : addrow_rdpvncinfo([0, 1, 2], [$bothclients{$client}, 'RDP & VNC', '<Not Detected>']);
    }
}

# Populate the permanent and transient shared folder list for the guest settings
sub fill_list_edit_shared {
    my ($IMachine) = @_;
    my $sref = get_session($IMachine);
    my @ISharedFolderPerm = IMachine_getSharedFolders($IMachine);
    my $IConsole = ISession_getConsole($$sref{ISession});
    my @ISharedFolderTran = IConsole_getSharedFolders($IConsole) if ($IConsole);
    $gui{d}{Edit}{buttonSharedRemove}->set_sensitive(0);
    $gui{d}{Edit}{buttonSharedEdit}->set_sensitive(0);
    $gui{d}{Edit}{treeviewShared}->signal_handler_block($signal{Edit_treeviewShared_cursorchanged});
    $gui{d}{Edit}{lstoreShared}->clear();
    $gui{d}{Edit}{treeviewShared}->signal_handler_unblock($signal{Edit_treeviewShared_cursorchanged});
    foreach (@ISharedFolderPerm) { addrow_editshared($_, 'Yes'); }
    foreach (@ISharedFolderTran) { addrow_editshared($_, 'No'); }
}

# Populates the guest's storage list
sub fill_list_edit_storage {
    my ($IMachine) = @_;
    set_pointer($gui{d}{Edit}{dialog}, 'watch');
    storage_sens_nosel();
    clr_list_generic($gui{d}{Edit}{treeviewStorage}, $signal{Edit_treeviewStorage_cursorchanged});
    my @IStorageController = IMachine_getStorageControllers($IMachine);

    foreach my $controller (@IStorageController) {
        my %ctr_attr = (name  => 1,
                        bus   => 1);
        get_icontroller_attrs(\%ctr_attr, $controller); # Fill hash with attributes
        my $iter = $gui{d}{Edit}{tstoreStorage}->append(undef);

        $gui{d}{Edit}{tstoreStorage}->set($iter, [0, 1, 2, 3, 4, 5, 7, 12], [$ctr_attr{name},                 # Display Name
                                                                        $ctr_attr{bus} . ' Controller',  # Display Type
                                                                        $ctr_attr{bus} . ' Controller',  # Tooltip
                                                                        1,                               # Is it a controller
                                                                        $ctr_attr{bus},                  # Controller BUS
                                                                        $ctr_attr{name},                 # Controller's Name
                                                                        $controller,                     # IStorageController object
                                                                        $gui{pb}{ctr}{$ctr_attr{bus}}]);

        my @IMediumAttachment = IMachine_getMediumAttachmentsOfController($IMachine, $ctr_attr{name});

        foreach my $attach (@IMediumAttachment) {
            my $citer = $gui{d}{Edit}{tstoreStorage}->append($iter);
            my %medium_attr = (refresh  => 1,
                               size     => 1,
                               logsize  => 1,
                               location => 1);
            get_imedium_attrs(\%medium_attr, $$attach{medium});

            if ($$attach{medium}) { # Is it a medium or empty drive
                my $baseIMedium = IMedium_getBase($$attach{medium});
                my $mediumname = ($$attach{medium} eq $baseIMedium) ? IMedium_getName($baseIMedium) : "(*) " . IMedium_getName($baseIMedium); #Tests for snapshots
                $mediumname = '<Server Drive> ' . $medium_attr{location} if (bl(IMedium_getHostDrive($$attach{medium})));
                $gui{d}{Edit}{tstoreStorage}->set($citer, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], [$mediumname,                            # Display Name
                                                                                                  $$attach{type},                         # Display Type
                                                                                                  "$medium_attr{location}\nPhysical Size: " .
                                                                                                  bytesToX($medium_attr{size}) . "\nLogical Size: " .
                                                                                                  bytesToX($medium_attr{logsize}),       # ToolTip
                                                                                                  0,                                      # Is it a controller
                                                                                                  $ctr_attr{bus},                         # The bus the medium is on
                                                                                                  $ctr_attr{name},                        # The name of the controller it is on
                                                                                                  $$attach{medium},                       # IMedium Object
                                                                                                  $controller,                            # IStorageController it is on
                                                                                                  $$attach{type},                         # Medium Type
                                                                                                  $$attach{device},                       # Device number
                                                                                                  $$attach{port},                         # Port Number
                                                                                                  $medium_attr{location},                 # Location
                                                                                                  $gui{pb}{$$attach{type}}]);

            }
            else {
                $gui{d}{Edit}{tstoreStorage}->set($citer, [0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 12], ['<Empty Drive>',               # Display Name
                                                                                            $$attach{type},                # Display Typee
                                                                                            'Empty Drive',  # Tooltip
                                                                                            0,                             # Is it a controller
                                                                                            $ctr_attr{bus},                # The bus the medium is on
                                                                                            $ctr_attr{name},               # The name of the controller it is on
                                                                                            $controller,                   # IStorageController it is on
                                                                                            $$attach{type},                # Medium Type
                                                                                            $$attach{device},              # Device number
                                                                                            $$attach{port},                # Port Number
                                                                                            $gui{pb}{$$attach{type}}]);
            }
        }
    }

    $gui{d}{Edit}{treeviewStorage}->expand_all();
    set_pointer($gui{d}{Edit}{dialog});
}

# VBPrefs NAT List Handling
{
    my %selected = (INATNetwork => '');

    sub getsel_list_vbprefsnat { return \%selected; }

    sub fill_list_vbprefsnat {
        set_pointer($gui{d}{VBPrefs}{dialog}, 'watch');
        $gui{d}{HostNetMan}{buttonDelNAT}->set_sensitive(0);
        $gui{d}{HostNetMan}{buttonEditNAT}->set_sensitive(0);
        clr_list_generic($gui{d}{HostNetMan}{treeviewNAT}, $signal{HostNetMan_treeviewNAT_cursorChanged});
        my @INATNetwork = IVirtualBox_getNATNetworks($gui{websn});

        foreach my $nat (@INATNetwork) {
            my $iter = $gui{d}{HostNetMan}{lstoreNAT}->append();
            $gui{d}{HostNetMan}{lstoreNAT}->set($iter, [0, 1, 2], [bl(INATNetwork_getEnabled($nat)), INATNetwork_getNetworkName($nat), $nat]);

            if ($nat eq $selected{INATNetwork}) {
                $gui{d}{HostNetMan}{treeviewNAT}->get_selection()->select_iter($iter);
                onsel_list_vbprefsnat();
            }
        }

        set_pointer($gui{d}{VBPrefs}{dialog});
    }

    sub onsel_list_vbprefsnat {
        my ($liststore, $iter) = $gui{d}{HostNetMan}{treeviewNAT}->get_selection->get_selected();
        my @row = $liststore->get($iter) if (defined($iter) and $liststore->iter_is_valid($iter));
        $selected{$_} = shift @row foreach('Enabled', 'Name', 'INATNetwork');
        $gui{d}{HostNetMan}{buttonDelNAT}->set_sensitive(1);
        $gui{d}{HostNetMan}{buttonEditNAT}->set_sensitive(1);
    }
}

# VBPrefs HON List Handling
{
    my %selected = (Uuid => '');

    sub getsel_list_vbprefshon { return \%selected; }

    sub fill_list_vbprefshon {
        set_pointer($gui{d}{VBPrefs}{dialog}, 'watch');
        $gui{d}{HostNetMan}{buttonDelHON}->set_sensitive(0);
        $gui{d}{HostNetMan}{buttonEditHON}->set_sensitive(0);
        clr_list_generic($gui{d}{HostNetMan}{treeviewHON}, $signal{HostNetMan_treeviewHON_cursorChanged});
        my $IHost = IVirtualBox_getHost($gui{websn});
        my @IHostNetworkInterface = IHost_findHostNetworkInterfacesOfType($IHost, 'HostOnly');

        foreach my $if (@IHostNetworkInterface) {
            my $iter = $gui{d}{HostNetMan}{lstoreHON}->append();
            my $uuid = IHostNetworkInterface_getId($if);
            $gui{d}{HostNetMan}{lstoreHON}->set($iter, [0, 1, 2], [IHostNetworkInterface_getName($if), $if, $uuid]);

            if ($uuid eq $selected{Uuid}) {
                $gui{d}{HostNetMan}{treeviewHON}->get_selection()->select_iter($iter);
                onsel_list_vbprefshon();
            }
        }

        set_pointer($gui{d}{VBPrefs}{dialog});
    }

    sub onsel_list_vbprefshon {
        my ($liststore, $iter) =  $gui{d}{HostNetMan}{treeviewHON}->get_selection->get_selected();
        my @row = $liststore->get($iter) if (defined($iter) and $liststore->iter_is_valid($iter));
        $selected{$_} = shift @row foreach ('Name', 'IHostNetworkInterface', 'Uuid');
        $gui{d}{HostNetMan}{buttonDelHON}->set_sensitive(1);
        $gui{d}{HostNetMan}{buttonEditHON}->set_sensitive(1);
    }
}

# Adds entries to the message log and scrolls to bottom
sub addrow_msg_log {
    foreach my $msg (@_) {
        my $iter = $gui{d}{Main}{lstoreMsgLog}->append();
        my ($sec,$min,$hour,$mday,$mon,$year) = localtime();
        $mon += 1;
        $year += 1900;
        $gui{d}{Main}{lstoreMsgLog}->set($iter, [0], [sprintf("%d-%02d-%02d %02d:%02d:%02d    %s", $year, $mon, $mday, $hour, $min, $sec, $msg)]);
        $gui{d}{Main}{treeviewMsgLog}->scroll_to_cell($gui{d}{Main}{treeviewMsgLog}->get_model->get_path($iter), $gui{d}{Main}{treeviewMsgLog}->get_column(0), 1, 1.0, 1.0);
    }
}


sub clear_msg_log {
    $gui{d}{Main}{lstoreMsgLog}->clear();
}

# Adds a row to the editshared list
sub addrow_editshared {
    my ($ISharedFolder, $permanent) = @_;
    my $shrname = ISharedFolder_getName($ISharedFolder);
    my $shrpath = ISharedFolder_getHostPath($ISharedFolder);
    my $shrerror = ISharedFolder_getLastAccessError($ISharedFolder);
    my $shraccessible = ISharedFolder_getAccessible($ISharedFolder);
    my $access = 'Full';
    my $automount = 'No';
    my $tooltip = ($shrerror) ? $shrerror : "$shrname ($shrpath)";
    $tooltip .= ($shraccessible eq 'false') ? ' : Share is not accessible' : '';
    $access = 'Read-Only' if (ISharedFolder_getWritable($ISharedFolder) eq 'false');
    $automount = 'Yes' if (ISharedFolder_getAutoMount($ISharedFolder) eq 'true');
    my $iter = $gui{d}{Edit}{lstoreShared}->append;
    if ($shraccessible eq 'false') { $gui{d}{Edit}{lstoreShared}->set($iter, [0, 1, 2, 3, 4, 5, 6], [$shrname, $shrpath, $access, $automount, $gui{pb}{Error}, $tooltip, $permanent]); }
    else { $gui{d}{Edit}{lstoreShared}->set($iter, [0, 1, 2, 3, 5, 6], [$shrname, $shrpath, $access, $automount, $tooltip, $permanent]); }
}

sub addrow_info {
    my ($cols, $vals) = @_;
    my $iter = $gui{d}{ServerInfo}{lstoreInfo}->append;
    $gui{d}{ServerInfo}{lstoreInfo}->set($iter, $cols, $vals);
    return $iter;
}

sub addrow_rdpvncinfo {
    my ($cols, $vals) = @_;
    my $iter = $gui{d}{RDPVNCInfo}{lstoreInfo}->append;
    $gui{d}{RDPVNCInfo}{lstoreInfo}->set($iter, $cols, $vals);
    return $iter;
}

# Returns the contents of the chosen column of the selected combobox row or
# returns the row iterator if no column is chosen
sub getsel_combo {
    my ($widget, $col) = @_;
    my $returnval = '';
    my $model = $widget->get_model();
    my $iter = $widget->get_active_iter();
    $col = 0 if !defined($col);
    $returnval = $model->get($iter, $col) if (defined($iter) and $model->iter_is_valid($iter));
    return $returnval;
}

# Sets the combobox active to the chosen text in the chosen column
sub combobox_set_active_text {
    my ($combobox, $txt, $col) = @_;
    my $i = 0;
    $combobox->get_model->foreach (
                            sub {
                                my ($model, $path, $iter) = @_;
                                if ($txt eq $model->get_value($iter, $col)) {
                                    ($i) = $path->get_indices;
                                    return 1; # stop
                                }
                                return 0; # continue
                            }
                          );
    $combobox->set_active($i);
}

# Handles single and multiple selections
sub getsel_list_remotefiles {
    my @filearray;
    my $selection = $gui{d}{RemoteFileChooser}{treeviewFile}->get_selection();
    my ($rows, $model) = $selection->get_selected_rows();

    foreach my $path (@{$rows}) {
        my $iter = $model->get_iter($path);
        next if (!$iter);
        my @row = $model->get($iter);

        push @filearray, {Type     => $row[0],
                          FileName => $row[1],
                          Size     => $row[2],
                          Mode     => $row[3]};
    }

    return \@filearray;
}

# Gets a selected item in the shared folder list
sub getsel_list_editshared {
    my ($liststore, $iter) = $gui{d}{Edit}{treeviewShared}->get_selection->get_selected();

    if (defined($iter) and $liststore->iter_is_valid($iter)) {
        my @row = $liststore->get($iter);
        my %hash;
        $hash{$_} = shift @row foreach ('Name', 'Folder', 'Access', 'Mount', 'Accessible', 'Tooltip', 'Permanent');
        return \%hash;
    }
}

# Gets a selection from the Edit Storage List
sub getsel_list_edit_storage {
    my ($treestore, $iter) = $gui{d}{Edit}{treeviewStorage}->get_selection->get_selected();

    if (defined($iter) and $treestore->iter_is_valid($iter)) {
        my @row = $treestore->get($iter);
        my %hash;
        $hash{$_} = shift @row foreach ('DisplayName', 'DisplayType', 'Tooltip', 'IsController', 'Bus', 'ControllerName', 'IMedium', 'IStorageController', 'MediumType', 'Device', 'Port', 'Location', 'Icon');
        return \%hash;
    }
}

# USB Filter List Handling
{
    my %selected = (IUSBDeviceFilter => '');

    sub getsel_list_usbfilters { return \%selected; }

    # On selection of a USB filter
    sub onsel_list_usbfilters {
        my ($liststore, $iter) = $gui{d}{Edit}{treeviewUSB}->get_selection->get_selected();
        my @row = $liststore->get($iter) if (defined($iter) and $liststore->iter_is_valid($iter));
        $selected{$_} = shift @row foreach ('Enabled', 'IUSBDeviceFilter', 'Name', 'Position');
        $gui{d}{Edit}{buttonUSBEdit}->set_sensitive(1);
        $gui{d}{Edit}{buttonUSBRemove}->set_sensitive(1);
        $gui{d}{Edit}{buttonUSBUp}->set_sensitive(1);
        $gui{d}{Edit}{buttonUSBDown}->set_sensitive(1);
    }

    # Fill the USB filter list
    sub fill_list_usbfilters {
        set_pointer($gui{d}{Edit}{dialog}, 'watch');
        my ($IMachine) = @_;
        $gui{d}{Edit}{buttonUSBEdit}->set_sensitive(0);
        $gui{d}{Edit}{buttonUSBRemove}->set_sensitive(0);
        $gui{d}{Edit}{buttonUSBUp}->set_sensitive(0);
        $gui{d}{Edit}{buttonUSBDown}->set_sensitive(0);
        clr_list_generic($gui{d}{Edit}{treeviewUSB}, $signal{Edit_treeviewUSB_cursorchanged});
        my $IUSBDeviceFilters = IMachine_getUSBDeviceFilters($IMachine);
        my @filters = IUSBDeviceFilters_getDeviceFilters($IUSBDeviceFilters);
        my $pos = 0;

        foreach my $filter (@filters) {
            my $iter = $gui{d}{Edit}{lstoreUSB}->append();
            $gui{d}{Edit}{lstoreUSB}->set($iter, [0, 1, 2, 3], [bl(IUSBDeviceFilter_getActive($filter)), $filter, IUSBDeviceFilter_getName($filter), $pos]);

            if ($filter eq $selected{IUSBDeviceFilter}) {
                $gui{d}{Edit}{treeviewUSB}->get_selection()->select_iter($iter);
                onsel_list_usbfilters();
            }

            $pos++;
        }
        set_pointer($gui{d}{Edit}{dialog});
    }
}

sub onsel_list_remotefiles {
    my $filearrayref = getsel_list_remotefiles();

    # We only care about the first file selected, and only if it's a directory
    my $fileref = ${$filearrayref}[0];

    if ($$fileref{FileName} eq '..') { cdup_remotefilechooser(); }
    elsif ($$fileref{Type} eq '(Dir)') {
        my $path = IVFSExplorer_getPath($gui{IVFSExplorer});
        IVFSExplorer_cd($gui{IVFSExplorer}, rcatdir($path, $$fileref{FileName}));
        fill_list_remotefiles(IVFSExplorer_getPath($gui{IVFSExplorer}), $gui{d}{RemoteFileChooser}{entryFilter}->get_text());
    }
}

# Only use the first file returned
sub onsel_list_remotefiles_single {
    my $filearrayref = getsel_list_remotefiles();
    # We only care about the first file selected, and only if it's a file
    my $fileref = ${$filearrayref}[0];
    if ($$fileref{FileName} ne '..' and $$fileref{Type} ne '(Dir)') { $gui{d}{RemoteFileChooser}{entryFile}->set_text($$fileref{FileName}); }
}

# Activates when selecting an item in the edit storage list, could be reduced a little
# as a lot of the options are the same for each controller but this gives flexibility
# to expand
sub onsel_list_editstorage {
    my $storref = getsel_list_edit_storage();
    # Sensitivities for all selections
    $gui{d}{Edit}{gridStorageattr}->show();
    $gui{d}{Edit}{buttonStorageAddattach}->set_sensitive(1);
    $gui{d}{Edit}{checkStorageHotplug}->hide();
    $gui{d}{Edit}{checkStorageSolidstate}->hide();
    $gui{d}{Edit}{sbStoragePortcount}->hide();
    $gui{d}{Edit}{checkStorageBootable}->hide();

    if ($$storref{IsController}) {
        # Sensitivities for all controllers
        $gui{d}{Edit}{buttonStorageRemoveattach}->set_sensitive(0);
        $gui{d}{Edit}{buttonStorageRemovectr}->set_sensitive(1);
        $gui{d}{Edit}{labelStorageName}->show();
        $gui{d}{Edit}{entryStorageName}->show();
        $gui{d}{Edit}{labelStorageCtrtype}->show();
        $gui{d}{Edit}{cboxStorageCtrtype}->show();
        $gui{d}{Edit}{checkStorageIOcache}->show();
        $gui{d}{Edit}{labelStorageConnectedport}->hide();
        $gui{d}{Edit}{cboxStorageConnectedport}->hide();
        $gui{d}{Edit}{checkStorageLivedisc}->hide();
        $gui{d}{Edit}{checkStorageBootable}->show();
        $gui{d}{Edit}{labelPortcount}->hide();
        $gui{d}{Edit}{labelStorageFloppytype}->hide();
        $gui{d}{Edit}{cboxStorageFloppytype}->hide();
        $gui{miAttachHD}->set_sensitive(1);
        $gui{miAttachDVD}->set_sensitive(1);
        $gui{miAttachFloppy}->set_sensitive(0);
        $gui{d}{Edit}{cboxStorageCtrtype}->signal_handler_block($signal{Edit_cboxStorageCtrtype_changed});
        $gui{d}{Edit}{entryStorageName}->set_text($$storref{ControllerName});
        $gui{d}{Edit}{checkStorageIOcache}->set_active(bl(IStorageController_getUseHostIOCache($$storref{IStorageController})));
        $gui{d}{Edit}{checkStorageBootable}->set_active(bl(IStorageController_getBootable($$storref{IStorageController})));

        my $variant = IStorageController_getControllerType($$storref{IStorageController});

        if ($$storref{Bus} eq 'IDE') { $gui{d}{Edit}{cboxStorageCtrtype}->set_model($gui{liststoreEditStorIDECtrType}); }
        elsif ($$storref{Bus} eq 'USB') { $gui{d}{Edit}{cboxStorageCtrtype}->set_model($gui{liststoreEditStorUSBCtrType}); }
        elsif ($$storref{Bus} eq 'SCSI') { $gui{d}{Edit}{cboxStorageCtrtype}->set_model($gui{liststoreEditStorSCSICtrType}); }
        elsif ($$storref{Bus} eq 'VirtioSCSI') { $gui{d}{Edit}{cboxStorageCtrtype}->set_model($gui{liststoreEditStorVirtioSCSICtrType}); }
        elsif ($$storref{Bus} eq 'SATA') {
            $gui{d}{Edit}{labelPortcount}->show();
            $gui{d}{Edit}{sbStoragePortcount}->show();
            $gui{miAttachFloppy}->set_sensitive(0);
            $gui{d}{Edit}{cboxStorageCtrtype}->set_model($gui{liststoreEditStorSATACtrType});
            $gui{d}{Edit}{sbStoragePortcount}->set_range(1, 30);
            $gui{d}{Edit}{adjStoragePortcount}->set_value(IStorageController_getPortCount($$storref{IStorageController}));
        }
        elsif ($$storref{Bus} eq 'SAS') {
            $gui{d}{Edit}{labelPortcount}->show();
            $gui{d}{Edit}{sbStoragePortcount}->show();
            $gui{miAttachFloppy}->set_sensitive(0);
            $gui{d}{Edit}{cboxStorageCtrtype}->set_model($gui{liststoreEditStorSASCtrType});
            $gui{d}{Edit}{sbStoragePortcount}->set_range(1, 254);
            $gui{d}{Edit}{adjStoragePortcount}->set_value(IStorageController_getPortCount($$storref{IStorageController}));
        }
        elsif ($$storref{Bus} eq 'PCIe') {
            $gui{d}{Edit}{labelPortcount}->show();
            $gui{d}{Edit}{sbStoragePortcount}->show();
            $gui{miAttachDVD}->set_sensitive(0);
            $gui{miAttachFloppy}->set_sensitive(0);
            $gui{d}{Edit}{cboxStorageCtrtype}->set_model($gui{liststoreEditStorNVMeCtrType});
            $gui{d}{Edit}{sbStoragePortcount}->set_range(1, 254);
            $gui{d}{Edit}{adjStoragePortcount}->set_value(IStorageController_getPortCount($$storref{IStorageController}));
        }
        else { # Default is floppy
            $gui{miAttachHD}->set_sensitive(0);
            $gui{miAttachDVD}->set_sensitive(0);
            $gui{miAttachFloppy}->set_sensitive(1);
            $gui{d}{Edit}{cboxStorageCtrtype}->set_model($gui{liststoreEditStorFloppyCtrType});
        }

        combobox_set_active_text($gui{d}{Edit}{cboxStorageCtrtype}, $variant, 0);
        $gui{d}{Edit}{cboxStorageCtrtype}->signal_handler_unblock($signal{Edit_cboxStorageCtrtype_changed});
    }
    else { # This is a medium, not a controller
        $gui{d}{Edit}{buttonStorageRemoveattach}->set_sensitive(1);
        $gui{d}{Edit}{buttonStorageRemovectr}->set_sensitive(0);
        $gui{d}{Edit}{labelStorageName}->hide();
        $gui{d}{Edit}{entryStorageName}->hide();
        $gui{d}{Edit}{labelStorageCtrtype}->hide();
        $gui{d}{Edit}{cboxStorageCtrtype}->hide();
        $gui{d}{Edit}{checkStorageIOcache}->hide();
        $gui{d}{Edit}{checkStorageLivedisc}->hide();
        $gui{d}{Edit}{labelStorageConnectedport}->show();
        $gui{d}{Edit}{cboxStorageConnectedport}->show();
        $gui{d}{Edit}{labelPortcount}->hide();
        $gui{d}{Edit}{labelStorageFloppytype}->hide();
        $gui{d}{Edit}{cboxStorageFloppytype}->hide();
        $gui{miAttachHD}->set_sensitive(0);
        $gui{miAttachDVD}->set_sensitive(0);
        $gui{miAttachFloppy}->set_sensitive(0);

        if ($$storref{MediumType} eq 'DVD') {
            my $attach = IMachine_getMediumAttachment($vmc{IMachine}, $$storref{ControllerName}, $$storref{Port}, $$storref{Device});
            $gui{d}{Edit}{checkStorageLivedisc}->show();
            $gui{d}{Edit}{checkStorageLivedisc}->set_active(bl($$attach{temporaryEject}));
            $gui{miAttachDVD}->set_sensitive(1);
            # Only SATA & USB controllers support hot pluggable
            if ($$storref{Bus} eq 'SATA' or $$storref{Bus} eq 'USB') {
                $gui{d}{Edit}{checkStorageHotplug}->set_active(bl($$attach{hotPluggable}));
                $gui{d}{Edit}{checkStorageHotplug}->show();
            }
            else { $gui{d}{Edit}{checkStorageHotplug}->hide(); }
        }
        elsif ($$storref{MediumType} eq 'Floppy') {
            $gui{d}{Edit}{labelStorageFloppytype}->show();
            $gui{d}{Edit}{cboxStorageFloppytype}->show();
            my $fdrivetype = IMachine_getExtraData($vmc{IMachine}, 'VBoxInternal/Devices/i82078/0/LUN#' . $$storref{Device} . '/Config/Type');
            if ($fdrivetype eq 'Floppy 360') { $gui{d}{Edit}{cboxStorageFloppytype}->set_active(0); }
            elsif ($fdrivetype eq 'Floppy 720') { $gui{d}{Edit}{cboxStorageFloppytype}->set_active(1); }
            elsif ($fdrivetype eq 'Floppy 1.20') { $gui{d}{Edit}{cboxStorageFloppytype}->set_active(2); }
            elsif ($fdrivetype eq 'Floppy 2.88') { $gui{d}{Edit}{cboxStorageFloppytype}->set_active(4); }
            elsif ($fdrivetype eq 'Floppy 15.6') { $gui{d}{Edit}{cboxStorageFloppytype}->set_active(5); }
            elsif ($fdrivetype eq 'Floppy 63.5') { $gui{d}{Edit}{cboxStorageFloppytype}->set_active(6); }
            else { $gui{d}{Edit}{cboxStorageFloppytype}->set_active(3); } # Everything else is 1.44MB
            $gui{miAttachFloppy}->set_sensitive(1);
        }
        else { # Default to HD
            my $attach = IMachine_getMediumAttachment($vmc{IMachine}, $$storref{ControllerName}, $$storref{Port}, $$storref{Device});
            $gui{d}{Edit}{checkStorageSolidstate}->set_active(bl($$attach{nonRotational}));
            $gui{d}{Edit}{buttonStorageAddattach}->set_sensitive(0);
            $gui{d}{Edit}{checkStorageSolidstate}->show();
            # Only SATA & USB controllers support hot pluggable
            if ($$storref{Bus} eq 'SATA' or $$storref{Bus} eq 'USB') {
                $gui{d}{Edit}{checkStorageHotplug}->set_active(bl($$attach{hotPluggable}));
                $gui{d}{Edit}{checkStorageHotplug}->show();
            }
            else { $gui{d}{Edit}{checkStorageHotplug}->hide(); }
        }

        # We also need to setup the port comboboxEditStorDevPort
        if ($$storref{Bus} eq 'SATA') {
            $gui{d}{Edit}{cboxStorageConnectedport}->set_model($gui{liststoreEditStorDevPortSATA});
            $gui{d}{Edit}{cboxStorageConnectedport}->set_active($$storref{Port});
        }
        elsif ($$storref{Bus} eq 'IDE') {
            $gui{d}{Edit}{cboxStorageConnectedport}->set_model($gui{liststoreEditStorDevPortIDE});
            if ($$storref{Device} == 0 and $$storref{Port} == 0) { $gui{d}{Edit}{cboxStorageConnectedport}->set_active(0); }
            elsif ($$storref{Device} == 1 and $$storref{Port} == 0) { $gui{d}{Edit}{cboxStorageConnectedport}->set_active(1); }
            elsif ($$storref{Device} == 0 and $$storref{Port} == 1) { $gui{d}{Edit}{cboxStorageConnectedport}->set_active(2); }
            elsif ($$storref{Device} == 1 and $$storref{Port} == 1) { $gui{d}{Edit}{cboxStorageConnectedport}->set_active(3); }
        }
        elsif ($$storref{Bus} eq 'SAS') {
            $gui{d}{Edit}{cboxStorageConnectedport}->set_model($gui{liststoreEditStorDevPortSAS});
            $gui{d}{Edit}{cboxStorageConnectedport}->set_active($$storref{Port});
        }
        elsif ($$storref{Bus} eq 'SCSI') {
            $gui{d}{Edit}{cboxStorageConnectedport}->set_model($gui{liststoreEditStorDevPortSCSI});
            $gui{d}{Edit}{cboxStorageConnectedport}->set_active($$storref{Port});
        }
        elsif ($$storref{Bus} eq 'Floppy') {
            $gui{d}{Edit}{cboxStorageConnectedport}->set_model($gui{liststoreEditStorDevPortFloppy});
            $gui{d}{Edit}{cboxStorageConnectedport}->set_active($$storref{Device});
        }
        elsif ($$storref{Bus} eq 'PCIe') {
            $gui{d}{Edit}{cboxStorageConnectedport}->set_model($gui{liststoreEditStorDevPortNVMe});
            $gui{d}{Edit}{cboxStorageConnectedport}->set_active($$storref{Port});
        }
        elsif ($$storref{Bus} eq 'USB') {
            $gui{d}{Edit}{cboxStorageConnectedport}->set_model($gui{liststoreEditStorDevPortUSB});
            $gui{d}{Edit}{cboxStorageConnectedport}->set_active($$storref{Port});
        }
        elsif ($$storref{Bus} eq 'VirtioSCSI') {
            $gui{d}{Edit}{cboxStorageConnectedport}->set_model($gui{liststoreEditStorDevPortVirtio});
            $gui{d}{Edit}{cboxStorageConnectedport}->set_active($$storref{Port});
        }
    }
}

# VMM Floppy List Handling
{
    my %selected = (IMedium => '');

    # Return the selected entry in the VMM floppy disk list
    sub getsel_list_vmmfloppy { return \%selected; }

    # Fill the floppy media list in the VMM
    sub fill_list_vmmfloppy {
        set_pointer($gui{d}{VMM}{dialog}, 'watch');
        clr_list_vmm($gui{d}{VMM}{tstoreFD});
        my $IMediumRef = get_all_media('Floppy');

        foreach (sort { lc($$IMediumRef{$a}) cmp lc($$IMediumRef{$b}) } (keys %$IMediumRef)) {
            my %mattr = (name       => 1,
                         logsize    => 1,
                         refresh    => 1,
                         accesserr  => 1,
                         location   => 1,
                         type       => 1); # medium attributes to get

            get_imedium_attrs(\%mattr, $_);
            my $iter = $gui{d}{VMM}{tstoreFD}->append(undef);

            if ($mattr{refresh} eq 'Inaccessible') {
                $gui{d}{VMM}{tstoreFD}->set($iter, [0, 1, 2, 3, 4, 5, 6], [$mattr{name},
                                                                             $_,
                                                                             0,
                                                                             $gui{pb}{Error},
                                                                             $mattr{accesserr}, # Tooltip can be access error
                                                                             $mattr{location},
                                                                             $mattr{type}]);
            }
            else {
                $gui{d}{VMM}{tstoreFD}->set($iter, [0, 1, 2, 4, 5, 6], [$mattr{name},
                                                                          $_,
                                                                          bytesToX($mattr{logsize}),
                                                                          $mattr{location}, # Tooltip can be location
                                                                          $mattr{location},
                                                                          $mattr{type}]);
            }

            if ($_ eq $selected{IMedium}) {
                $gui{d}{VMM}{treeviewFD}->get_selection()->select_iter($iter);
                onsel_list_vmmfloppy();
            }
        }

        set_pointer($gui{d}{VMM}{dialog});
    }

    # On selection of a floppy image in the list
    sub onsel_list_vmmfloppy {
        my ($treestore, $iter) = $gui{d}{VMM}{treeviewFD}->get_selection->get_selected();
        my @row = $treestore->get($iter) if (defined($iter) and $treestore->iter_is_valid($iter));
        $selected{$_} = shift @row foreach ('Name', 'IMedium', 'Size', 'Accessible', 'Tooltip', 'Location', 'Type');
        $gui{d}{VMM}{buttonCopy}->set_sensitive(1);
        $gui{d}{VMM}{buttonMove}->set_sensitive(1);
        $gui{d}{VMM}{buttonModify}->set_sensitive(0);
        $gui{d}{VMM}{buttonCompact}->set_sensitive(0);

        my $gnames;
        my @mids = IMedium_getMachineIds($selected{IMedium});

        foreach my $id (@mids) {
            my $snames;
            my $IMachine = IVirtualBox_findMachine($gui{websn}, $id);
            my $mname = IMachine_getName($IMachine);
            my @sids = IMedium_getSnapshotIds($selected{IMedium}, $id);

            foreach my $snapid (@sids) {
                next if ($snapid eq $id);
                if (IMachine_getSnapshotCount($IMachine)) { # Just because the medium says its attached to a snapshot, that snapshot may not longer exist.
                    my $ISnapshot = IMachine_findSnapshot($IMachine, $snapid);
                    my $sname = ISnapshot_getName($ISnapshot) if ($ISnapshot);
                    $snames .= "$sname, " if ($sname);
                }
            }

            if ($snames) {
                $snames =~ s/, $//; # Remove any trailing comma
                $gnames .= "$mname ($snames). ";
            }
            else { $gnames .= "$mname, "; }
        }

        if ($gnames) {
            $gui{d}{VMM}{buttonRemove}->set_sensitive(0);
            $gui{d}{VMM}{buttonRelease}->set_sensitive(1);
            $gnames =~ s/, $//; # Remove any trailing comma
        }
        else {
            $gnames = '<Not Attached>';
            $gui{d}{VMM}{buttonRemove}->set_sensitive(1);
            $gui{d}{VMM}{buttonRelease}->set_sensitive(0);
        }

        set_vmm_fields($gnames, \%selected);
    }
}

# Fills the ISO image list
sub fill_list_new_guest_dvd {
    set_pointer($gui{d}{New}{dialog}, 'watch');
    $gui{d}{New}{lstoreISO}->clear();
    my $IMediumRef = get_all_media('DVD');
    my $iter = $gui{d}{New}{lstoreISO}->append();
    $gui{d}{New}{lstoreISO}->set($iter, [0, 1], ['<None Selected>', undef]);
    $gui{d}{New}{cboxISO}->set_active(0);

    foreach (sort { lc($$IMediumRef{$a}) cmp lc($$IMediumRef{$b}) } (keys %$IMediumRef)) {
        my %mattr = (name       => 1,
                     logsize    => 0,
                     refresh    => 1,
                     accesserr  => 0,
                     location   => 0,
                     type       => 0); # medium attributes to get

        get_imedium_attrs(\%mattr, $_);
        $iter = $gui{d}{New}{lstoreISO}->append();

        if ($mattr{refresh} ne 'Inaccessible') {
            $gui{d}{New}{lstoreISO}->set($iter, [0, 1], [$mattr{name}, $_]);
        }
    }

    set_pointer($gui{d}{New}{dialog});
}

# VMM DVD List Handling
{
    my %selected = (IMedium => '');

    sub getsel_list_vmmdvd { return \%selected; }

    # Fill the DVD media list in the VMM
    sub fill_list_vmmdvd {
        set_pointer($gui{d}{VMM}{dialog}, 'watch');
        clr_list_vmm($gui{d}{VMM}{tstoreDVD});
        my $IMediumRef = get_all_media('DVD');

        foreach (sort { lc($$IMediumRef{$a}) cmp lc($$IMediumRef{$b}) } (keys %$IMediumRef)) {
            my %mattr = (name       => 1,
                         logsize    => 1,
                         refresh    => 1,
                         accesserr  => 1,
                         location   => 1,
                         type       => 1); # medium attributes to get

            get_imedium_attrs(\%mattr, $_);
            my $iter = $gui{d}{VMM}{tstoreDVD}->append(undef);

            if ($mattr{refresh} eq 'Inaccessible') {
                $gui{d}{VMM}{tstoreDVD}->set($iter, [0, 1, 2, 3, 4, 5, 6], [$mattr{name},
                                                                          $_,
                                                                          0,
                                                                          $gui{pb}{Error},
                                                                          $mattr{accesserr}, # Tooltip can be access error
                                                                          $mattr{location},
                                                                          $mattr{type}]);
            }
            else {
                $gui{d}{VMM}{tstoreDVD}->set($iter, [0, 1, 2, 4, 5, 6], [$mattr{name},
                                                                       $_,
                                                                       bytesToX($mattr{logsize}),
                                                                       $mattr{location}, # Tooltip can be location
                                                                       $mattr{location},
                                                                       $mattr{type}]);
            }

            if ($_ eq $selected{IMedium}) {
                $gui{d}{VMM}{treeviewDVD}->get_selection()->select_iter($iter);
                onsel_list_vmmdvd();
            }
        }

        set_pointer($gui{d}{VMM}{dialog});
    }

    # On selection of a DVD image in the list
    sub onsel_list_vmmdvd {
        my ($treestore, $iter) = $gui{d}{VMM}{treeviewDVD}->get_selection->get_selected();
        my @row = $treestore->get($iter) if (defined($iter) and $treestore->iter_is_valid($iter));
        $selected{$_} = shift @row foreach ('Name', 'IMedium', 'Size', 'Accessible', 'Tooltip', 'Location', 'Type');
        $gui{d}{VMM}{buttonCopy}->set_sensitive(0);
        $gui{d}{VMM}{buttonMove}->set_sensitive(1);
        $gui{d}{VMM}{buttonModify}->set_sensitive(0);
        $gui{d}{VMM}{buttonCompact}->set_sensitive(0);

        my $gnames;
        my @mids = IMedium_getMachineIds($selected{IMedium});

        foreach my $id (@mids) {
            my $snames;
            my $IMachine = IVirtualBox_findMachine($gui{websn}, $id);
            my $mname = IMachine_getName($IMachine);
            my @sids = IMedium_getSnapshotIds($selected{IMedium}, $id);

            foreach my $snapid (@sids) {
                next if ($snapid eq $id);
                if (IMachine_getSnapshotCount($IMachine)) { # Just because the medium says its attached to a snapshot, that snapshot may not longer exist.
                    my $ISnapshot = IMachine_findSnapshot($IMachine, $snapid);
                    my $sname = ISnapshot_getName($ISnapshot) if ($ISnapshot);
                    $snames .= "$sname, " if ($sname);
                }
            }

            if ($snames) {
                $snames =~ s/, $//; # Remove any trailing comma
                $gnames .= "$mname ($snames). ";
            }
            else { $gnames .= "$mname, "; }
        }

        if ($gnames) {
            $gui{d}{VMM}{buttonRemove}->set_sensitive(0);
            $gui{d}{VMM}{buttonRelease}->set_sensitive(1);
            $gnames =~ s/, $//; # Remove any trailing comma
        }
        else {
            $gnames = '<Not Attached>';
            $gui{d}{VMM}{buttonRemove}->set_sensitive(1);
            $gui{d}{VMM}{buttonRelease}->set_sensitive(0);
        }

        set_vmm_fields($gnames, \%selected);
    }
}

# IPv4 Port Forwarding List Handling
{
    my %selected = (Name => '');

    sub getsel_list_pf4 { return \%selected; }

    sub fill_list_pf4 {
        my ($INATNetwork) = @_;
        set_pointer($gui{d}{NAT}{dialog} , 'watch');
        clr_list_generic($gui{d}{NAT}{treeviewIPv4}, $signal{NAT_treeviewIPv4_cursor_changed});
        $gui{d}{NAT}{buttonRemove4}->set_sensitive(0);
        $gui{d}{NAT}{buttonEdit4}->set_sensitive(0);
        my @rules = INATNetwork_getPortForwardRules4($INATNetwork);
        foreach my $rule (@rules) {
            my ($rname, $rproto, $rhip, $rhport, $rgip, $rgport) = split ':', $rule;
            $rhip =~ s/[^0-9,.]//g; # Strip everything but these chars
            $rgip =~ s/[^0-9,.]//g; # Strip everything but these chars
            my $iter = $gui{d}{NAT}{lstoreIPv4}->append;
            $gui{d}{NAT}{lstoreIPv4}->set($iter, [0, 1, 2, 3, 4, 5, 6], [$rname, uc($rproto), $rhip, $rhport, $rgip, $rgport, $INATNetwork]);

            if ($rname eq $selected{Name}) {
                $gui{d}{NAT}{treeviewIPv4}->get_selection()->select_iter($iter);
                onsel_list_pf4();
            }
        }
        set_pointer($gui{d}{NAT}{dialog});
    }

    sub onsel_list_pf4 {
        my ($liststore, $iter) = $gui{d}{NAT}{treeviewIPv4}->get_selection->get_selected();
        my @row = $liststore->get($iter) if (defined($iter) and $liststore->iter_is_valid($iter));
        $selected{$_} = shift @row foreach ('Name', 'Protocol', 'HostIP', 'HostPort', 'GuestIP', 'GuestPort', 'INATNetwork');
        $gui{d}{NAT}{buttonRemove4}->set_sensitive(1);
        $gui{d}{NAT}{buttonEdit4}->set_sensitive(1);
    }

}

# IPv6 Port Forwarding List Handling
{
    my %selected = (Name => '');

    sub getsel_list_pf6 { return \%selected; }

    sub fill_list_pf6 {
        my ($INATNetwork) = @_;
        set_pointer($gui{d}{NAT}{dialog}, 'watch');
        clr_list_generic($gui{d}{NAT}{treeviewIPv6}, $signal{NAT_treeviewIPv6_cursor_changed});
        $gui{d}{NAT}{buttonRemove6}->set_sensitive(0);
        $gui{d}{NAT}{buttonEdit6}->set_sensitive(0);
        my @rules = INATNetwork_getPortForwardRules6($INATNetwork);
        foreach my $rule (@rules) {
            # Jump through hoops because VB decided to use : as a column separator! Doh!
            $rule =~ s/\[(.*?)\]//;
            my $rhip = $1;
            $rule =~ s/\[(.*?)\]//;
            my $rgip = $1;
            my ($rname, $rproto, undef, $rhport, undef, $rgport) = split ':', $rule;
            my $iter = $gui{d}{NAT}{lstoreIPv6}->append;
            $gui{d}{NAT}{lstoreIPv6}->set($iter, [0, 1, 2, 3, 4, 5, 6], [$rname, uc($rproto), $rhip, $rhport, $rgip, $rgport, $INATNetwork]);

            if ($rname eq $selected{Name}) {
                $gui{d}{NAT}{treeviewIPv6}->get_selection()->select_iter($iter);
                onsel_list_pf6();
            }
        }
        set_pointer($gui{d}{NAT}{dialog});
    }

    sub onsel_list_pf6 {
        my ($liststore, $iter) = $gui{d}{NAT}{treeviewIPv6}->get_selection->get_selected();
        my @row = $liststore->get($iter) if (defined($iter) and $liststore->iter_is_valid($iter));
        $selected{$_} = shift @row foreach ('Name', 'Protocol', 'HostIP', 'HostPort', 'GuestIP', 'GuestPort', 'INATNetwork');
        $gui{d}{NAT}{buttonRemove6}->set_sensitive(1);
        $gui{d}{NAT}{buttonEdit6}->set_sensitive(1);
    }
}

# VMM HD List Handling
{
    my %selected = (IMedium => '');

    sub getsel_list_vmmhd { return \%selected; }

    # Fill the hard disk media list in the VMM
    sub fill_list_vmmhd {
        set_pointer($gui{d}{VMM}{dialog}, 'watch');
        clr_list_vmm($gui{d}{VMM}{tstoreHD});
        my $IMediumRef = get_all_media('HardDisk');

        foreach (sort { lc($$IMediumRef{$a}) cmp lc($$IMediumRef{$b}) } (keys %$IMediumRef)) {
            recurse_hd_snapshot($gui{d}{VMM}{tstoreHD}, $_, undef);
        }

        set_pointer($gui{d}{VMM}{dialog});
    }

    # On selection of a hard disk image in the list
    sub onsel_list_vmmhd {
        my ($treestore, $iter) = $gui{d}{VMM}{treeviewHD}->get_selection->get_selected();
        my @row = $treestore->get($iter) if (defined($treestore) and $treestore->iter_is_valid($iter));
        $selected{$_} = shift @row foreach ('Name', 'IMedium', 'Asize', 'Vsize', 'Accessible', 'Tooltip', 'Location', 'Type', 'LsizeInt');
        $gui{d}{VMM}{buttonCopy}->set_sensitive(1);
        $gui{d}{VMM}{buttonMove}->set_sensitive(1);
        $gui{d}{VMM}{buttonModify}->set_sensitive(1);
        $gui{d}{VMM}{buttonCompact}->set_sensitive(1);

        my $gnames;
        my @mids = IMedium_getMachineIds($selected{IMedium});

        foreach my $id (@mids) {
            my $snames;
            my $IMachine = IVirtualBox_findMachine($gui{websn}, $id);
            my $mname = IMachine_getName($IMachine);
            my @sids = IMedium_getSnapshotIds($selected{IMedium}, $id);

            foreach my $snapid (@sids) {
                next if ($snapid eq $id);
                my $ISnapshot = IMachine_findSnapshot($IMachine, $snapid);
                my $sname = ISnapshot_getName($ISnapshot);
                $snames .= "$sname, ";
            }

            if ($snames) {
                $snames =~ s/, $//; # Remove any trailing comma
                $gnames .= "$mname ($snames). ";
            }
            else { $gnames .= "$mname, "; }
        }

        if ($gnames) {
            $gui{d}{VMM}{buttonRemove}->set_sensitive(0);
            $gui{d}{VMM}{buttonRelease}->set_sensitive(1);
            $gnames =~ s/, $//; # Remove any trailing comma
        }
        else {
            $gnames = '<Not Attached>';
            $gui{d}{VMM}{buttonRemove}->set_sensitive(1);
            $gui{d}{VMM}{buttonRelease}->set_sensitive(0);
        }

        # Don't allow remove/release if it has sub-snapshots
        if (IMedium_getChildren($selected{IMedium})) {
            $gui{d}{VMM}{buttonRemove}->set_sensitive(0);
            $gui{d}{VMM}{buttonRelease}->set_sensitive(0);
        }

        set_vmm_fields($gnames, \%selected);
    }

    # Recurses through the media for populating the VMM media lists, including
    # identifying snapshots
    sub recurse_hd_snapshot {
        my ($treestore, $IMedium, $iter) = @_;
        my %mattr = (name       => 1,
                     size       => 1,
                     logsize    => 1,
                     refresh    => 1,
                     accesserr  => 1,
                     children   => 1,
                     location   => 1,
                     type       => 1); # medium attributes to get

        get_imedium_attrs(\%mattr, $IMedium);
        my $citer = $treestore->append($iter);

        if ($mattr{refresh} eq 'Inaccessible') {
            $treestore->set($citer, [0, 1, 2, 3, 4, 5, 6, 7, 8], [$mattr{name},
                                                                  $IMedium,
                                                                  0,
                                                                  0,
                                                                  $gui{pb}{Error},
                                                                  $mattr{accesserr},
                                                                  $mattr{location},
                                                                  $mattr{type},
                                                                  $mattr{logsize}]);
        }
        else {
            $treestore->set($citer, [0, 1, 2, 3, 5, 6, 7, 8], [$mattr{name},
                                                               $IMedium,
                                                               bytesToX($mattr{size}),
                                                               bytesToX($mattr{logsize}),
                                                               $mattr{location}, # Tooltip can be location
                                                               $mattr{location},
                                                               $mattr{type},
                                                               $mattr{logsize}]);
        }

        if (($IMedium eq $selected{IMedium})) {
            $gui{d}{VMM}{treeviewHD}->expand_all() if (IMedium_getParent($IMedium)); # If item is a snapshot, we need to expand the list in order for selection to work
            $gui{d}{VMM}{treeviewHD}->get_selection()->select_iter($citer);
            onsel_list_vmmhd();
        }

        recurse_hd_snapshot($treestore, $_, $citer) foreach (@{$mattr{children}});
    }
}

# Sets the contents of the fields in the VMM
sub set_vmm_fields {
    my ($gnames, $selected) = @_;
    $gui{d}{VMM}{labelType}->set_text("$$selected{Type}, " . uc(IMedium_getFormat($$selected{IMedium})) . ', ' . IMedium_getVariant($$selected{IMedium}));
    $gui{d}{VMM}{labelAttachedTo}->set_text($gnames);
    $gui{d}{VMM}{labelLocation}->set_text($$selected{Location});

    if (imedium_has_property($$selected{IMedium}, 'CRYPT/KeyId')) { $gui{d}{VMM}{labelEncrypted}->set_text(IMedium_getProperty($$selected{IMedium}, 'CRYPT/KeyId')); }
    else { $gui{d}{VMM}{labelEncrypted}->set_text('<Not Encrypted>'); }

    $gui{d}{VMM}{labelUUID}->set_text(IMedium_getId($$selected{IMedium}));
}

sub clr_list_vmm {
    my ($treestore) = @_;
    vmm_sens_unselected(); # Do whenever list is cleared
    $gui{d}{VMM}{treeviewHD}->signal_handler_block($signal{VMM_treeviewHD_cursorChanged});
    $gui{d}{VMM}{treeviewDVD}->signal_handler_block($signal{VMM_treeviewDVD_cursorChanged});
    $gui{d}{VMM}{treeviewFD}->signal_handler_block($signal{VMM_treeviewFD_cursorChanged});
    $treestore->clear();
    $gui{d}{VMM}{treeviewHD}->signal_handler_unblock($signal{VMM_treeviewHD_cursorChanged});
    $gui{d}{VMM}{treeviewDVD}->signal_handler_unblock($signal{VMM_treeviewDVD_cursorChanged});
    $gui{d}{VMM}{treeviewFD}->signal_handler_unblock($signal{VMM_treeviewFD_cursorChanged});
}

sub onsel_list_shared {
    $gui{d}{Edit}{buttonSharedRemove}->set_sensitive(1);
    $gui{d}{Edit}{buttonSharedEdit}->set_sensitive(1);
}

# Snapshot List Handling
{
    my %selected = (ISnapshot => '');

    sub getsel_list_snapshots { return \%selected; }

    # On selection of a snapshot in the list
    sub onsel_list_snapshots {
        my ($treestore, $iter) = $gui{d}{Main}{treeviewSnap}->get_selection->get_selected();
        my @row = $treestore->get($iter) if (defined($iter) and $treestore->iter_is_valid($iter));
        $selected{$_} = shift @row foreach ('Name', 'Date', 'ISnapshot', 'Icon');

        if ($selected{ISnapshot}) {
            $gui{d}{Main}{buttonRestoreSnap}->set_sensitive(1);
            $gui{d}{Main}{buttonDelSnap}->set_sensitive(1);
            $gui{d}{Main}{buttonDetailsSnap}->set_sensitive(1);
            $gui{d}{Main}{buttonCloneSnap}->set_sensitive(1);
            $gui{d}{Main}{buttonTakeSnap}->set_sensitive(0);
        }
        else {
            $gui{d}{Main}{buttonRestoreSnap}->set_sensitive(0);
            $gui{d}{Main}{buttonDelSnap}->set_sensitive(0);
            $gui{d}{Main}{buttonDetailsSnap}->set_sensitive(0);
            $gui{d}{Main}{buttonCloneSnap}->set_sensitive(0);
            $gui{d}{Main}{buttonTakeSnap}->set_sensitive(1);
        }
    }

    sub fill_list_snapshots {
        my $gref = getsel_list_guest();
        addrow_msg_log("Retrieving snapshots for $$gref{Name}");
        clr_list_snapshots();

        if (IMachine_getSnapshotCount($$gref{IMachine}) > 0) {
            my $ISnapshot_current = IMachine_getCurrentSnapshot($$gref{IMachine});
            my $ISnapshot = IMachine_findSnapshot($$gref{IMachine}, undef); # get first snapshot
            recurse_snapshot($ISnapshot, undef, $ISnapshot_current, $$gref{IMachine});
            $gui{d}{Main}{treeviewSnap}->expand_all();
        }

        addrow_msg_log("Retrieved snapshots for $$gref{Name}");
    }

    # Clear snapshot list and set sensitivity
    sub clr_list_snapshots {
        $gui{d}{Main}{buttonRestoreSnap}->set_sensitive(0);
        $gui{d}{Main}{buttonDelSnap}->set_sensitive(0);
        $gui{d}{Main}{buttonDetailsSnap}->set_sensitive(0);
        $gui{d}{Main}{buttonCloneSnap}->set_sensitive(0);
        $gui{d}{Main}{treeviewSnap}->signal_handler_block($signal{Main_treeviewSnap_cursorChanged});
        $gui{d}{Main}{tstoreSnap}->clear();
        $gui{d}{Main}{treeviewSnap}->signal_handler_unblock($signal{Main_treeviewSnap_cursorChanged});
    }

    sub recurse_snapshot {
        my ($ISnapshot, $iter, $ISnapshot_current, $IMachine) = @_;
        my $citer = $gui{d}{Main}{tstoreSnap}->append($iter);
        my $snapname = ISnapshot_getName($ISnapshot);
        my $date = scalar(localtime((ISnapshot_getTimeStamp($ISnapshot))/1000)); # VBox returns msecs so / 1000
        $gui{d}{Main}{tstoreSnap}->set($citer, [0, 1, 2, 3, 4], [$snapname,
                                                             $date,
                                                             $ISnapshot,
                                                             bl(ISnapshot_getOnline($ISnapshot)) ? $gui{pb}{SnapshotOnline} : $gui{pb}{SnapshotOffline},
                                                             400]); # 400 , 700 is bold is pango int for normal text

        if ($ISnapshot eq $ISnapshot_current) {
            my $curiter = $gui{d}{Main}{tstoreSnap}->append($citer);

            if (bl(IMachine_getCurrentStateModified($IMachine))) { $gui{d}{Main}{tstoreSnap}->set($curiter, [0, 1, 2, 3, 4], ['[Current State]  (changed)', '', '', $gui{pb}{SnapshotCurrent}, 700]); }
            else { $gui{d}{Main}{tstoreSnap}->set($curiter, [0, 1, 2, 3, 4], ['[Current State]', '', '', $gui{pb}{SnapshotCurrent}, 380]); }

        }

        my @snapshots = ISnapshot_getChildren($ISnapshot);
        if (@snapshots > 0) { recurse_snapshot($_, $citer, $ISnapshot_current, $IMachine) foreach (@snapshots); }
    }
}

# Guest List Handling
{
    my %selected = (Uuid           => 'None',
                    vscrollbar_pos => 0); # Initialize this element as it may be tested before the hash is fully initialized

    sub makesel_list_guest { $selected{Uuid} = $_[0]; }

    sub getsel_list_guest { return \%selected; }

    # On selection of a guest in the list
    sub onsel_list_guest {
        set_pointer($gui{d}{Main}{win}, 'watch');
        my ($treestore, $iter) = $gui{d}{Main}{treeviewGuest}->get_selection->get_selected();
        my @row = $treestore->get($iter) if (defined($iter) and $treestore->iter_is_valid($iter));

        # If there's no IMachine, it's a group so don't waste anymore time
        if (!$row[2]) {
            sens_unselected();
            $gui{d}{Main}{tstoreDetails}->clear();
            set_pointer($gui{d}{Main}{win});
            return;
        }

        $selected{$_} = shift @row foreach ('Name', 'Os', 'IMachine', 'Status', 'Osid', 'Uuid', 'Icon', 'Prettyname', 'Statusicon');
        $prefs{EXTENDEDDETAILS} ? fill_list_details() : fill_list_details_brief();
        sens_unselected();
        fill_list_snapshots();
        my $status = IMachine_getState($selected{IMachine});

        if ($status eq 'Running' | $status eq 'Starting') {
            my @IUSBController = IMachine_getUSBControllers($selected{IMachine});
            $gui{mi}{Action}->set_sensitive(1);
            $gui{mi}{Stop}->set_sensitive(1);
            $gui{mi}{Pause}->set_sensitive(1);
            $gui{mi}{Reset}->set_sensitive(1);
            $gui{mi}{Keyboard}->set_sensitive(1);
            $gui{mi}{Display}->set_sensitive(1);
            $gui{mi}{Logs}->set_sensitive(1);
            $gui{mi}{Settings}->set_sensitive(1);
            $gui{mi}{Floppy}->set_sensitive(1);
            $gui{mi}{DVD}->set_sensitive(1);
            $gui{d}{Main}{buttonStop}->set_sensitive(1);
            $gui{d}{Main}{buttonCAD}->set_sensitive(1);
            $gui{d}{Main}{buttonReset}->set_sensitive(1);
            $gui{d}{Main}{buttonDisplay}->set_sensitive(1);
            $gui{d}{Main}{buttonSettings}->set_sensitive(1);         # Online editing
            $gui{d}{Main}{buttonRefreshSnap}->set_sensitive(1);
            $gui{d}{Main}{buttonTakeSnap}->set_sensitive(1);
            $gui{mi}{Screenshot}->set_sensitive(1);
            $gui{mi}{USB}->set_sensitive(1) if $IUSBController[0];
            $gui{mi}{HotPlugCPU}->set_sensitive(1) if (bl(IMachine_getCPUHotPlugEnabled($selected{IMachine})));
        }
        elsif ($status eq 'Saved') {
            $gui{mi}{Action}->set_sensitive(1);
            $gui{mi}{Start}->set_sensitive(1);
            $gui{mi}{Clone}->set_sensitive(1);
            $gui{mi}{Logs}->set_sensitive(1);
            $gui{mi}{Discard}->set_sensitive(1);
            $gui{mi}{SetGroup}->set_sensitive(1);
            $gui{mi}{Ungroup}->set_sensitive(1);
            $gui{d}{Main}{buttonStart}->set_sensitive(1);
            $gui{d}{Main}{buttonDiscard}->set_sensitive(1);
            $gui{d}{Main}{buttonRefreshSnap}->set_sensitive(1);
            $gui{d}{Main}{buttonTakeSnap}->set_sensitive(1);
        }
        elsif ($status eq 'Paused') {
            $gui{mi}{Action}->set_sensitive(1);
            $gui{mi}{Stop}->set_sensitive(1);
            $gui{mi}{Resume}->set_sensitive(1);
            $gui{mi}{RemoteDisplay}->set_sensitive(1);
            $gui{mi}{Logs}->set_sensitive(1);
            $gui{d}{Main}{buttonStop}->set_sensitive(1);
            $gui{d}{Main}{buttonDisplay}->set_sensitive(1);
            $gui{d}{Main}{buttonRefreshSnap}->set_sensitive(1);
            $gui{d}{Main}{buttonTakeSnap}->set_sensitive(1);
        }
        elsif ($status eq 'PoweredOff' | $status eq 'Aborted') {
            $gui{mi}{ExportAppl}->set_sensitive(1);
            $gui{mi}{Action}->set_sensitive(1);
            $gui{mi}{Start}->set_sensitive(1);
            $gui{mi}{Settings}->set_sensitive(1);
            $gui{mi}{Clone}->set_sensitive(1);
            $gui{mi}{Remove}->set_sensitive(1);
            $gui{mi}{SetGroup}->set_sensitive(1);
            $gui{mi}{Ungroup}->set_sensitive(1);
            $gui{mi}{Logs}->set_sensitive(1);
            $gui{mi}{Floppy}->set_sensitive(1);
            $gui{mi}{DVD}->set_sensitive(1);
            $gui{d}{Main}{buttonStart}->set_sensitive(1);
            $gui{d}{Main}{buttonSettings}->set_sensitive(1);
            $gui{d}{Main}{buttonRefreshSnap}->set_sensitive(1);
            $gui{d}{Main}{buttonTakeSnap}->set_sensitive(1);
            $gui{mi}{HotPlugCPU}->set_sensitive(0);
        }
        elsif ($status eq 'Stuck') {
               sens_unselected();
               $gui{mi}{Stop}->set_sensitive(1);
               $gui{d}{Main}{buttonStop}->set_sensitive(1);
        }
        else { sens_unselected(); }

        set_pointer($gui{d}{Main}{win});
    }

    # Adds a group node
    sub add_guest_group {
        my ($node, $name, $piter) = @_;
        if (defined($$node{$name})) { return $$node{$name}{node}, $$node{$name}{iter}; }
        else {
            my $citer = $gui{d}{Main}{tstoreGuest}->append($piter);
            $gui{d}{Main}{tstoreGuest}->set($citer, [0, 6, 7], [$name, $gui{pb}{VMGroup}, $name]);
            $$node{$name} = { iter => $citer, node => {} };
            return $$node{$name}{node}, $citer;
        }
    }

    sub fill_list_guest {
        my $osver = osver();
        my %grouptree;
        addrow_msg_log("Retrieving guest list from $endpoint");
        set_pointer($gui{d}{Main}{win}, 'watch');
        clr_list_guest();
        my @IMachine = IVirtualBox_getMachines($gui{websn});
        my $selection;
        my %guestlist;

        # Collate all the info we need, so we don't do more net calls than needed. Exclude inaccessib
        foreach my $IMachine (@IMachine) {
            if (bl(IMachine_getAccessible($IMachine))) {
                $guestlist{$IMachine} = {name   => IMachine_getName($IMachine),
                                         groups => IMachine_getGroups($IMachine),  # Remove leading slash, using substitution without modifying in-place
                                         uuid   => IMachine_getId($IMachine),
                                         status => IMachine_getState($IMachine),
                                         osid   => IMachine_getOSTypeId($IMachine)};

                $guestlist{$IMachine}{groups} =~ s/^\///;  # Leading / is optional, remove for simplicity
            }
            else { addrow_msg_log("WARNING: The guest $guestlist{$IMachine}{name} is inaccessible and has been excluded. Fix using vboxmanage or VirtualBox on the server."); }
        }

        # Order the IMachines by group, depending on preference
        my @machine_sorted_group = $prefs{AUTOSORTGUESTLIST} ? sort { lc($guestlist{$a}{groups}) cmp lc($guestlist{$b}{groups}) } keys %guestlist : keys %guestlist;
        # Order the IMachines by name, depending on preference
        my @machine_sorted_name = $prefs{AUTOSORTGUESTLIST} ? sort { lc($guestlist{$a}{name}) cmp lc($guestlist{$b}{name}) } keys %guestlist : keys %guestlist;

        # We need to process the groups first, before adding any guests
        foreach my $IMachine ( @machine_sorted_group  ) {
            my $node = \%grouptree;
            my @parts = split('/', $guestlist{$IMachine}{groups});
            my $piter = undef;

            foreach my $part (@parts) {
                ($node, $piter) = add_guest_group($node, $part, $piter);
            }

            $guestlist{$IMachine}{iter} = $piter; # Associate the group iterator with the guest
        }

        # Process and display each guest
        foreach my $IMachine (@machine_sorted_name) {
            my $uuid = $guestlist{$IMachine}{uuid};
            my $status = $guestlist{$IMachine}{status};
            my $ISnapshot = IMachine_getCurrentSnapshot($IMachine);
            my $osid = $guestlist{$IMachine}{osid};
            my $prettyname = $guestlist{$IMachine}{name};

            # Append snapshot name to prettyname if available (note, this is faster than a ternary version
            if ($ISnapshot) { $prettyname .= ' (' . ISnapshot_getName($ISnapshot) . ")\n$status"; }
            else { $prettyname .= "\n$status"; }

            # Append to the guest list view
            my $iter = $gui{d}{Main}{tstoreGuest}->append($guestlist{$IMachine}{iter});
            $gui{d}{Main}{tstoreGuest}->set($iter, [0, 1, 2, 3, 4, 5, 6, 7, 8], [$guestlist{$IMachine}{name},
                                                                                 $$osver{$osid}{description},
                                                                                 $IMachine,
                                                                                 $status,
                                                                                 $osid,
                                                                                 $uuid,
                                                                                 (-e "$gui{THUMBDIR}/$uuid.png") ? Gtk3::Gdk::Pixbuf->new_from_file("$gui{THUMBDIR}/$uuid.png") : $$osver{$osid}{icon},
                                                                                 $prettyname,
                                                                                 $gui{pb}{$status}]);

            $gui{d}{Main}{treeviewGuest}->expand_all() if $prefs{GUESTLISTEXPAND};
            $selection = $iter if ($uuid eq $selected{Uuid});
        }

        # Select the previously selected guest if it exists
        if ($selection) {
            $gui{d}{Main}{treeviewGuest}->get_selection()->select_iter($selection);
            onsel_list_guest();
        }

        # Restore scrollbar position
        $gui{d}{Main}{scrolledGuest}->get_vadjustment()->set_value($selected{vscrollbar_pos});
        set_pointer($gui{d}{Main}{win});
        addrow_msg_log("Retrieved guest list from $endpoint");
    }


    # Clear the guest list and snapshots
    sub clr_list_guest {
        # Record the vertical scrollbar position for restoring later
        $selected{vscrollbar_pos} = $gui{d}{Main}{scrolledGuest}->get_vadjustment()->get_value();
        sens_unselected();
        $gui{d}{Main}{treeviewGuest}->signal_handler_block($signal{Main_treeviewGuest_cursorChanged});
        $gui{d}{Main}{tstoreGuest}->clear();
        $gui{d}{Main}{treeviewGuest}->signal_handler_unblock($signal{Main_treeviewGuest_cursorChanged});
        $gui{d}{Main}{tstoreDetails}->clear();
        clr_list_snapshots();
    }
}

# Block handling profiles
{
    my %selected = (Name => '');

    # If pname exists we're calling this method directly, otherwise we're calling it from the button
    sub addrow_profile {
        my ($widget, $pname, $url, $username, $password) = @_;
        my $iter = $gui{d}{Connect}{lstoreProfile}->append();

        if ($pname) { $gui{d}{Connect}{lstoreProfile}->set($iter, [0, 1, 2, 3], [$pname, $url, $username, $password]); }
        else {
            $pname = 'Unnamed-' . int(rand(999999));
            $gui{d}{Connect}{lstoreProfile}->set($iter, [0, 1, 2, 3], [$pname, 'http://localhost:18083', '', '']);
            $gui{d}{Profile}{treeviewProfile}->get_selection()->select_iter($iter);
            onsel_list_profile();
        }
    }

    sub getsel_list_profile { return \%selected; }

    # On selection of a profile in the list
    sub onsel_list_profile {
        my ($liststore, $iter) = $gui{d}{Profile}{treeviewProfile}->get_selection->get_selected();

        if (defined($iter) and $liststore->iter_is_valid($iter)) {
            my @row = $liststore->get($iter);
            $selected{$_} = shift @row foreach ('Name', 'URL', 'Username', 'Password');
            $gui{d}{Profile}{entryName}->set_text($selected{Name});
            $gui{d}{Profile}{entryURL}->set_text($selected{URL});
            $gui{d}{Profile}{entryUser}->set_text($selected{Username});
            $gui{d}{Profile}{entryPass}->set_text($selected{Password});
            $gui{d}{Profile}{checkAutoConnect}->set_active(1) if ($selected{Name} eq $prefs{AUTOCONNPROF});
            $gui{d}{Profile}{checkAutoConnect}->set_active(0) if ($selected{Name} ne $prefs{AUTOCONNPROF});
            $gui{d}{Profile}{buttonDelete}->set_sensitive(1);
            $gui{d}{Profile}{gridProfile}->set_sensitive(1);
        }
    }

    # Delete a connection profile
    sub remove_profile {
        my ($liststore, $iter) = $gui{d}{Profile}{treeviewProfile}->get_selection->get_selected();

        if (defined($iter) and $liststore->iter_is_valid($iter)) {
            $gui{d}{Profile}{entryName}->set_text('');
            $gui{d}{Profile}{entryURL}->set_text('');
            $gui{d}{Profile}{entryUser}->set_text('');
            $gui{d}{Profile}{entryPass}->set_text('');
            # Iter is automatically modified to point to the next row or none if it's not valid
            $liststore->remove($iter);
        }

        # If there are no items, desensitise
        if ($liststore->iter_n_children() < 1) {
            $gui{d}{Profile}{buttonDelete}->set_sensitive(0);
            $gui{d}{Profile}{gridProfile}->set_sensitive(0);
        }
    }

    sub profile_name_change {
        my ($liststore, $iter) = $gui{d}{Profile}{treeviewProfile}->get_selection->get_selected();
        # Works around a perl-Gtk3 bug
        my $text = Glib::Object::Introspection::GValueWrapper->new('Glib::String', $gui{d}{Profile}{entryName}->get_text());
        $liststore->set_value($iter, 0, $text) if (defined($iter) and $liststore->iter_is_valid($iter));
    }

    sub profile_url_change {
        my ($liststore, $iter)  = $gui{d}{Profile}{treeviewProfile}->get_selection->get_selected();
        # Works around a perl-Gtk3 bug
        my $text = Glib::Object::Introspection::GValueWrapper->new('Glib::String', $gui{d}{Profile}{entryURL}->get_text());
        $liststore->set_value($iter, 1, $text) if (defined($iter) and $liststore->iter_is_valid($iter));
    }

    sub profile_username_change {
        my ($liststore, $iter) = $gui{d}{Profile}{treeviewProfile}->get_selection->get_selected();
        # Works around a perl-Gtk3 bug
        my $text = Glib::Object::Introspection::GValueWrapper->new('Glib::String', $gui{d}{Profile}{entryUser}->get_text());
        $liststore->set_value($iter, 2, $text) if (defined($iter) and $liststore->iter_is_valid($iter));
    }

    sub profile_password_change {
        my ($liststore, $iter) = $gui{d}{Profile}{treeviewProfile}->get_selection->get_selected();
        # Works around a perl-Gtk3 bug
        my $text = Glib::Object::Introspection::GValueWrapper->new('Glib::String', $gui{d}{Profile}{entryPass}->get_text());
        $liststore->set_value($iter, 3, $text) if (defined($iter) and $liststore->iter_is_valid($iter));
    }

    sub profile_autoconn_change {
        my $state = $gui{d}{Profile}{checkAutoConnect}->get_active();
        if ($state) { $prefs{AUTOCONNPROF} = $gui{d}{Profile}{entryName}->get_text(); }
        else {
            # Only clear it, if the profilename matches the auto connection name
            $prefs{AUTOCONNPROF} = '' if ( $prefs{AUTOCONNPROF} eq $gui{d}{Profile}{entryName}->get_text() );
        }
    }
}

1;
