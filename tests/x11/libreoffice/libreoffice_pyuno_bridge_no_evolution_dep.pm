# SUSE's openQA tests
#
# Copyright © 2018 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Case 1503978 - LibreOffice: pyuno bridge
# - Launch oowriter
# - Open tools menu and select option "Run macros"
# - On macro selector, choose python samples
# - Run create table and check
# - Quit libreoffice without saving
# Maintainer: Grace Wang <gwang@suse.com>
# Tags: poo#34141

use base "x11test";
use strict;
use warnings;
use testapi;

sub run {
    my $self = shift;

    # Open LibreOffice
    $self->libreoffice_start_program('oowriter');

    # Make sure the tip of the day window disappear
    wait_still_screen;
    # Open the tools and navigate to macro selector
    assert_and_click 'ooffice-writer-tools';
    assert_and_click 'ooffice-tools-macros';
    send_key 'right';
    assert_and_click 'ooffice-writer-tools-run-macros';

    # navigate to the python samples item
    assert_screen 'ooffice-writer-mymacros';
    send_key 'down';
    assert_and_dclick 'ooffice-writer-libreofficemacros';
    send_key_until_needlematch 'ooffice-python-samples', 'down';

    # expand python samples and navigate to table sample
    # In Libreoffice 6.3 send_key 'right'; doesn't work
    # So use assert_and_dclick instead
    assert_and_dclick 'ooffice-python-samples';
    send_key_until_needlematch 'ooffice-table-sample', 'down';

    # run create table
    assert_and_click 'ooffice-run-create-table';
    assert_screen 'ooffice-verify-table';

    # exit ooffice-writer without saving created table
    send_key 'ctrl-q';
    assert_and_click 'ooffice-writer-dont-save';
}

1;
