# Edit Shared Folder Settings of a Guest
use strict;
use warnings;
our (%gui, %vmc);

sub init_edit_shared {
    set_pointer($gui{d}{Edit}{dialog}, 'watch');
    # Ie only permanent shares
    if ($vmc{SessionType} eq 'WriteLock') {
        $gui{d}{SharedFolders}{checkPermanent}->set_active(1);
        $gui{d}{SharedFolders}{checkPermanent}->hide();
    }
    else {
        $gui{d}{SharedFolders}{checkPermanent}->set_active(0);
        $gui{d}{SharedFolders}{checkPermanent}->show();
    }

    fill_list_edit_shared($vmc{IMachine});
    IMachine_saveSettings($vmc{IMachine});
    set_pointer($gui{d}{Edit}{dialog});
}

# Show the dialog for adding a shared folder
sub show_dialog_shared {
    my ($widget) = @_;

    if ($widget ne $gui{d}{Edit}{buttonSharedAdd}) {
        my $sref = getsel_list_editshared();
        $gui{d}{SharedFolders}{entryPath}->set_text($$sref{Folder});
        $gui{d}{SharedFolders}{entryName}->set_text($$sref{Name});
        ($$sref{Access} eq 'Read-Only') ? $gui{d}{SharedFolders}{checkReadOnly}->set_active(1) : $gui{d}{SharedFolders}{checkReadOnly}->set_active(0);
        ($$sref{Mount} eq 'Yes') ? $gui{d}{SharedFolders}{checkAutoMount}->set_active(1) : $gui{d}{SharedFolders}{checkAutoMount}->set_active(0);
        ($$sref{Permanent} eq 'Yes') ? $gui{d}{SharedFolders}{checkPermanent}->set_active(1) : $gui{d}{SharedFolders}{checkPermanent}->set_active(0);
    }

    do {
        $gui{d}{SharedFolders}{dialog}->show_all;
        my $response = $gui{d}{SharedFolders}{dialog}->run();

        if ($response eq 'ok') {
            # No validation needed for other entries
            if (!$gui{d}{SharedFolders}{entryPath}->get_text()) { show_err_msg('invalidpath', 0, '(Folder Path)'); }
            elsif (!$gui{d}{SharedFolders}{entryName}->get_text()) { show_err_msg('invalidname', 0, '(Folder Name)'); }
            else {
                $gui{d}{SharedFolders}{dialog}->hide;
                share_remove($widget, $gui{d}{Edit}{treeviewShared}) if ($widget ne $gui{d}{Edit}{buttonSharedAdd});

                if ($gui{d}{SharedFolders}{checkPermanent}->get_active()) {
                    IMachine_createSharedFolder($vmc{IMachine}, $gui{d}{SharedFolders}{entryName}->get_text(),
                                                                $gui{d}{SharedFolders}{entryPath}->get_text(),
                                                                !$gui{d}{SharedFolders}{checkReadOnly}->get_active(),
                                                                $gui{d}{SharedFolders}{checkAutoMount}->get_active());
                }
                else {
                    my $sref = get_session($vmc{IMachine});
                    my $IConsole = ISession_getConsole($$sref{ISession});
                    IConsole_createSharedFolder($IConsole, $gui{d}{SharedFolders}{entryName}->get_text(),
                                                           $gui{d}{SharedFolders}{entryPath}->get_text(),
                                                           !$gui{d}{SharedFolders}{checkReadOnly}->get_active(),
                                                           $gui{d}{SharedFolders}{checkAutoMount}->get_active()) if ($IConsole);
                }

                fill_list_edit_shared($vmc{IMachine});
                IMachine_saveSettings($vmc{IMachine});
            }
        }
        else { $gui{d}{SharedFolders}{dialog}->hide; }

    } until (!$gui{d}{SharedFolders}{dialog}->get_visible());
}

# Deletes a share and handles both permanent and transient
sub share_remove {
    my $shareref = getsel_list_editshared();

    if ($$shareref{Permanent} eq 'Yes') { IMachine_removeSharedFolder($vmc{IMachine}, $$shareref{Name}); }
    else {
        my $sref = get_session($vmc{IMachine});
        my $IConsole = ISession_getConsole($$sref{ISession});
        IConsole_removeSharedFolder($IConsole, $$shareref{Name}) if ($IConsole);
    }

    fill_list_edit_shared($vmc{IMachine});
    IMachine_saveSettings($vmc{IMachine});
}

1;
