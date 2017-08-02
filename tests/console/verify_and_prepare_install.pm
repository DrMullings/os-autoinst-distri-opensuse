#TODO if keeping this add Suse header

use base 'opensusebasetest';
use strict;
use testapi;

sub run () {
    
    assert_script_run 'ls /dev | grep vd*';
    assert_script_run 'ls /mnt/';
    type_string "logout\n";
    select_console 'x11';
}
1;
#vim: set sw=4 et;
