package user_config;
 
use vars qw($VERSION);
 
$VERSION = sprintf "%d.%03d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/;
 
$MSG = {
    angelegt		=> "neuen Benutzer angelegt",
    nix_gefunden	=> "keine Entsprechungen gefunden",
    nicht_erlaubt	=> "letzte Aktion war nicht erlaubt !!!",
    geaendert		=> "Benutzer geändert",
    admin_aktiv		=> "der Admin darf nicht deaktiviert werden !!!",
    edit_id		=> "User editieren: ID = ",
    anlegen1		=> "neuen Benutzer vom Typ ",
    anlegen2		=> " anlegen"
};

$TMPL = {
    UserListTmpl 	=> "user_list.tmpl",
    UserEditTmpl 	=> "user_edit.tmpl",
    UserAddTmpl 	=> "user_add.tmpl",
    UserAdd0Tmpl	=> "user_add0.tmpl",
    UserStartTmpl	=> "user_start.tmpl"
};

1;
