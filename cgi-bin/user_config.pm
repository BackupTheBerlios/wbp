package user_config;
 
use vars qw($VERSION);
 
$VERSION = sprintf "%d.%03d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/;
 
$MSG = {
    # Statusmeldungen
    angelegt		=> "neuen Benutzer angelegt",
    nix_gefunden	=> "keine Entsprechungen gefunden",
    nicht_erlaubt	=> "letzte Aktion war nicht erlaubt !!!",
    geaendert		=> "Benutzerdaten ge�ndert ...",
    admin_aktiv		=> "der Admin darf nicht deaktiviert werden !!!",
    
    # Formular-Fehlermeldungen
    user_error		=> "Username exisitert bereits ...",
    user_kurz		=> "Bitte geben Sie einen Usernamen ein ...",
    user_lang		=> "Username zu lang ( > 8 )",
    pass_kurz		=> "Bitte geben Sie ein Passwort ein ...",
    pass_lang		=> "Passwort zu lang ( > 8 )",
    pass_error1		=> "Passwort und dessen ...",
    pass_error2		=> "... Best�tigung stimmen nicht �berein",
    first_kurz		=> "Bitte geben Sie einen Vornamen ein ...",
    first_lang		=> "Vorname zu lang ( > 30 )",
    last_kurz		=> "Bitte geben Sie einen Nachnamen ein ...",
    last_lang		=> "Nachname zu lang ( > 30 )",
    mail_kurz		=> "Bitte geben Sie eine eMail-Adresse ein ...",
    mail_lang		=> "Mail-Adresse zu lang ( > 100 )",
    mail_error		=> "Das Format der eMail-Adresse ist ung�ltig ...",
    desc_lang		=> "Beschreibung zu lang ( > 500 )",
    
    # normale Texte in Templates
    s_suchen		=> "User suchen:",
    s_anlegen		=> "User anlegen:",
    edit_id		=> "User editieren: ID = ",
    anlegen1		=> "neuen Benutzer vom Typ ",
    anlegen2		=> " anlegen",
    
    # Buttons
    b_anlegen		=> "anlegen",
    b_uebernehmen	=> "�bernehmen",
    b_suchen		=> "suchen",
    
    # Tabellenk�pfe bzw. Feldbezeichner
    firstname_		=> "Vorname",
    lastname_		=> "Nachname",
    desc_		=> "Beschreibung",
    mail_		=> "eMail-Adresse",
    password_		=> "Passwort",
    confirm_		=> "Best�tigung",
    type_		=> "Typ",
    state_		=> "Status",
    aktiv_		=> "aktiv",
    inaktiv_		=> "inaktiv"    
};

$TMPL = {
    UserListTmpl 	=> "user_list.tmpl",
    UserEditTmpl 	=> "user_edit.tmpl",
    UserAddTmpl 	=> "user_add.tmpl",
    UserAdd0Tmpl	=> "user_add0.tmpl",
    UserStartTmpl	=> "user_start.tmpl"
};

1;
