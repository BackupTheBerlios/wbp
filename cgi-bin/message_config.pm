package message_config;

use vars qw($VERSION);

$VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/;

$MSG = {
        NoMessages  => "Sie haben keine Nachrichten.",
        Unknownerror => "Es ist ein unbekannter Fehler aufgetreten.",
	DbError => "Es ist ein Fehler mit der Datenbank aufgetreten.",
        NoSubject  => "Sie haben kein Betreff angegeben."
};

1;
