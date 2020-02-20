# SUSE’s openQA tests
#
# Copyright © 2018-2019 IBM Corp.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.
#
# Summary:  Based on consoletest_setup.pm (console test pre setup, stopping and disabling packagekit, install curl and tar to get logs and so on)
# modified for running the testcase TOOL_s390_kernel_1 on s390x.
# Maintainer: Elif Aslan <elas@linux.vnet.ibm.com>

use base "s390base";
use testapi;
use utils;
use warnings;
use strict;

sub run {
    my $self = shift;
    $self->copy_testsuite('TOOL_s390_kernel_1');
    $self->execute_script('cpuplugd.sh',    '', 1200);
    $self->execute_script('mon_fsstatd.sh', '', 6000);

}

sub test_flags {
    return {milestone => 1, fatal => 0};
}

1;
# vim: set sw=4 et: