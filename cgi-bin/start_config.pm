package start_config;

use vars qw($VERSION);

$VERSION = sprintf "%d.%03d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/;

$MSG = {
	DbError      => "Es ist ein Fehler mit der Datenbank aufgetreten.",
	NoPassWord   => "Bitte geben Sie ein Passwort ein.",
	NoUserName   => "Bitte geben Sie einen Username ein.",
	NoUserExist  => "Es existiert kein User mit diesem Passwort oder der User ist deaktiviert.",
	Unknownerror => "Es ist ein unbekannter Fehler aufgetreten." 
};

1;
