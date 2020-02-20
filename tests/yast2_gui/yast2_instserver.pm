# SUSE's openQA tests
#
# Copyright © 2019 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: test yast2-instserver using HTTP, FTP and NFS
# - ensure that all needed packages are installed
# - setup instserver using HTTP
# - check that HTTP instserver is working
# - setup instserver using FTP
# - check that FTP instserver is working
# - setup instserver using NFS
# - check that NFS instserver is working
# Maintainer: Paolo Stivanin <pstivanin@suse.com>

use base "y2_module_guitest";
use strict;
use warnings;
use testapi;
use utils "zypper_call";
use version_utils "is_sle";

sub send_key_and_wait {
    my $key        = shift;
    my $still_time = shift;
    send_key $key;
    wait_still_screen $still_time;
}

sub clean_env {
    send_key_and_wait("alt-t", 2);
    send_key_and_wait("alt-f", 2);

    x11_start_program "xterm";
    wait_still_screen 2;
    become_root;
    wait_still_screen 1;
    my $config_file = "/etc/YaST2/instserver/instserver.xml";
    assert_script_run "test -f $config_file && rm -f $config_file";
    # exit xterm
    send_key_and_wait("ctrl-d", 2);
    send_key_and_wait("ctrl-d", 2);
}

sub test_nfs_instserver {
    # select server configuration
    send_key_and_wait("alt-s", 3);
    # select nfs
    send_key_and_wait("alt-f", 2);
    send_key_and_wait("alt-n", 2);
    # use default nfs config
    send_key_and_wait("alt-n", 2);
    # finish wizard
    send_key_and_wait("alt-f", 3);
    # check that the nfs instserver is working
    x11_start_program "xterm";
    wait_still_screen 2;
    become_root;
    wait_still_screen 1;
    my $dir_path = "/mnt/nfstest";
    assert_script_run "showmount -e localhost | grep /srv/install";
    assert_script_run "mkdir $dir_path && mount localhost:/srv/install $dir_path/";
    assert_script_run "ls $dir_path/instserver/CD1/ | grep README";
    script_run "umount $dir_path && rmdir $dir_path";
    # exit xterm
    send_key_and_wait("ctrl-d", 2);
    send_key_and_wait("ctrl-d", 2);
}

sub test_ftp_instserver {
    # select server configuration
    send_key_and_wait("alt-s", 3);
    # select ftp
    send_key_and_wait("alt-o", 2);
    send_key_and_wait("alt-n", 2);
    # select directory alias
    send_key_and_wait(is_sle("<=12-SP5") ? "alt-i" : "alt-d", 2);
    wait_screen_change { type_string "test" };
    send_key_and_wait("alt-n", 2);
    # finish wizard
    send_key_and_wait("alt-f", 3);
    # check that the ftp instserver is working
    x11_start_program "xterm";
    wait_still_screen 2;
    if (is_sle "<=12-SP5") {
        become_root;
        wait_still_screen 1;
        assert_script_run "service xinetd stop";
        assert_script_run "service vsftpd start";
    }
    assert_script_run "lftp -e 'set net:timeout 3; get /srv/install/instserver/CD1/README; bye' -u bernhard,$testapi::password localhost";
    assert_script_run "test -f README";
    # exit xterm
    send_key_and_wait("ctrl-d", 2) if is_sle "<=12-SP5";
    send_key_and_wait("ctrl-d", 2);
}

sub test_http_instserver {
    # by default "configure http repository" is selected
    send_key_and_wait("alt-n", 2);
    send_key_and_wait("alt-i", 1);
    # directory alias
    wait_screen_change { type_string "test" };
    wait_still_screen 2;
    send_key_and_wait("alt-n", 2);
    send_key_and_wait("alt-a", 2);
    send_key_and_wait("alt-p", 2);
    wait_screen_change { type_string "instserver" };
    wait_still_screen 2;
    send_key_and_wait("alt-n", 2);
    # select sr0
    send_key_and_wait("alt-c", 2);
    send_key_and_wait("alt-s", 2);
    send_key_until_needlematch("yast2-instserver_sr0dev", "down", 3);
    send_key_and_wait("alt-n", 2);
    send_key_and_wait("alt-o", 2);
    # copying CD content to local directory may take some time
    wait_still_screen(stilltime => 90, timeout => 90);
    # skip "insert next cd" on SLE 12.x
    send_key_and_wait("alt-s", 2) if is_sle("<=12-SP5");
    # finish wizard
    send_key_and_wait("alt-f", 3);
    # check that the http instserver is working
    x11_start_program "xterm";
    wait_still_screen 2;
    validate_script_output("curl -s http://localhost/test/instserver/CD1/ | grep title", sub { m/.*Index of \/test\/instserver\/CD1.*/ });
    # exit xterm
    send_key_and_wait("ctrl-d", 2);
}

sub start_yast2_instserver {
    my $self = shift;
    $self->launch_yast2_module_x11("instserver", match_timeout => 120);
    wait_still_screen;
}

sub run {
    my $self = shift;

    select_console "root-console";
    zypper_call("in yast2-instserver openslp-server lftp vsftpd yast2-nfs-server nfs-client apache2{,-prefork}", exitcode => [0, 102, 103]);

    select_console "x11";

    start_yast2_instserver $self;
    test_http_instserver;

    start_yast2_instserver $self;
    test_ftp_instserver;

    start_yast2_instserver $self;
    test_nfs_instserver;

    # clean existing config
    start_yast2_instserver $self;
    clean_env;
}

1;
