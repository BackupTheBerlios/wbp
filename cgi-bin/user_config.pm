package user_config;
 
use vars qw($VERSION);
 
$VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/;
 
$MSG = {};

$TMPL = {
    UserListTmpl 	=> "user_list.tmpl",
    UserEditTmpl 	=> "user_edit.tmpl",
    UserAddTmpl 	=> "user_add.tmpl",
    UserStartTmpl	=> "user_start.tmpl",
    WeiterTmpl		=> "user_weiter.tmpl",
};

1;
