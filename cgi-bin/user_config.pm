package user_config;
 
use vars qw($VERSION);
 
$VERSION = sprintf "%d.%03d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/;
 
$MSG = {};

$TMPL = {
    UserListTmpl 	=> "user_list.tmpl",
    UserEditTmpl 	=> "user_edit.tmpl",
    UserAddTmpl 	=> "user_add.tmpl",
    UserAdd0Tmpl	=> "user_add0.tmpl",
    UserStartTmpl	=> "user_start.tmpl"
#    WeiterTmpl		=> "user_weiter.tmpl",
};

1;
