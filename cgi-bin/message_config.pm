package message_config;

use vars qw($VERSION);

$VERSION = sprintf "%d.%03d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/;

$MSG = {
    NoMessages     => "Sie haben keine Nachrichten.", # unused
    InboxEmpty  => "Sie haben keine neuen Nachrichten.", # zero
    InboxMessage     => "Sie haben eine neue Nachricht.", # singular
    InboxMessages    => "Sie haben %s neue Nachrichten.", # plural
    ReceivedEmpty  => "Sie haben keine bekannten Nachrichten.", # zero
    ReceivedMessage     => "Sie haben eine bekannte Nachricht.", # singular
    ReceivedMessages    => "Sie haben %s bekannte Nachrichten.", # plural
    SendEmpty  => "Sie haben keine versandten Nachrichten.", # zero
    SendMessage     => "Sie haben eine Nachricht versandt.", # singular
    SendMessages    => "Sie haben %s Nachrichten versandt.", # plural
    Unknownerror   => "Es ist ein unbekannter Fehler aufgetreten.",
    NoSuchMsgError => "Nachricht konnte nicht gefunden werden.",
    DbError        => "Es ist ein Fehler mit der Datenbank aufgetreten.",
    NoSubject      => "Sie haben kein Betreff angegeben."
};


$TMPL = {
    Message     => "message.tmpl",      # Message Template, for Inbox and Received
    MessageSend => "message_send.tmpl", # MessageSend Template, for send messages
    MessageForm => "message_form.tmpl", # Form Template, for composing a new message
    MessageShow => "message_show.tmpl", # Show template shows one detailed message
    MessageChooseRecv => "message_choose.tmpl"  # Choose receivers
    };

1;


