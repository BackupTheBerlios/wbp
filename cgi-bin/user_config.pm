package user_config;
 
use vars qw($VERSION);
 
$VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/;
 
$MSG = {};

$TMPL = {
    UserTmpl 		=> "user.tmpl",
    UserEditTmpl 	=> "user_edit.tmpl",
    UserAddTmpl 	=> "user_add.tmpl",
    UserTestTmpl	=> "user_test.tmpl"
};

1;
