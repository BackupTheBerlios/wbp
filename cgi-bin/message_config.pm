package message_config;

use vars qw($VERSION);

$VERSION = sprintf "%d.%03d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/;

$MSG = {
        NoMessages  => "Sie haben keine Nachrichten.",
        Unknownerror => "Es ist ein unbekannter Fehler aufgetreten.",
	DbError => "Es ist ein Fehler mit der Datenbank aufgetreten.",
        NoSubject  => "Sie haben kein Betreff angegeben."
};


$TMPL = {
        Message   => "message.tmpl",      # Message Template
	MessageNew => "message_new.tmpl", # New Message/Form template
	MessagesRead => "messages_read.tmpl", # Message-Read template
	TestOut => "testout.tmpl"         # test output template
};


1;


