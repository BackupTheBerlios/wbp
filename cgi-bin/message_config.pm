package message_config;

use vars qw($VERSION);

$VERSION = sprintf "%d.%03d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/;

$MSG = {
    NoMessages     => "Sie haben keine Nachrichten.",
    NoNewMessages  => "Sie haben keine neuen Nachrichten.",
    NoOldMessages  => "Sie haben keine alten Nachrichten.",
    NewMessages    => "Sie haben %s neue Nachrichten.", # plural
    OldMessages    => "Sie haben %s alte Nachrichten.", # plural
    NewMessage     => "Sie haben eine neue Nachricht.", # singular
    OldMessage     => "Sie haben eine alte Nachricht.", # singular
    Unknownerror   => "Es ist ein unbekannter Fehler aufgetreten.",
    NoSuchMsgError => "Nachricht konnte nicht gefunden werden.",
    DbError        => "Es ist ein Fehler mit der Datenbank aufgetreten.",
    NoSubject      => "Sie haben kein Betreff angegeben."
};


$TMPL = {
    Message     => "message.tmpl",      # Message Template
    MessageForm => "message_form.tmpl", # Form Template
    MessageShow => "message_show.tmpl", # Show template
    MessageTest => "message_test.tmpl"  # --- test output template ---
    };

1;


