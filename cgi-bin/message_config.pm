package message_config;

use vars qw($VERSION);

$VERSION = sprintf "%d.%03d", q$Revision: 1.11 $ =~ /(\d+)\.(\d+)/;

# Ausgabemeldungen, sowohl fuer Meldungen im Header, als auch fuer das Error-Template
$MSG = {
    NoMessages       => "Sie haben keine Nachrichten.", # wird z.Z. nicht benutzt
    InboxEmpty       => "Sie haben keine neuen Nachrichten.", # zero
    InboxMessage     => "Sie haben eine neue Nachricht.",     # singular
    InboxMessages    => "Sie haben %s neue Nachrichten.",     # plural
    ReceivedEmpty    => "Sie haben keine bekannten Nachrichten.", # zero
    ReceivedMessage  => "Sie haben eine bekannte Nachricht.",     # singular
    ReceivedMessages => "Sie haben %s bekannte Nachrichten.",     # plural
    SendEmpty        => "Sie haben keine versandten Nachrichten.", # zero
    SendMessage      => "Sie haben eine Nachricht versandt.",      # singular
    SendMessages     => "Sie haben %s Nachrichten versandt.",      # plural
    Unknownerror     => "Es ist ein unbekannter Fehler aufgetreten.",
    NoSuchMsgError   => "Nachricht konnte nicht gefunden werden.",
    NoSelection      => "Keine Aenderung, da keine Auswahl vorgenommen wurde.",
    ProjectAdded     => "Mitglieder von Projekt %s wurden aufgenommen.",
    UsersAdded       => "%s Benutzer aufgenommen.",
    UsersRemoved     => "%s Benutzer entfernt.",
    MessageDeleted   => "Nachricht wurde geloescht",
    DbError          => "Es ist ein Fehler mit der Datenbank aufgetreten.",
    NormalError    => "Es ist ein allgemeiner Fehler aufgetreten.",
    NoRecvError      => "Es konnten keine Empfaenger bestimmt werden.",
    NoSubject        => "Sie haben kein Betreff angegeben.",
    NoReceiver       => "Sie haben keinen Empfaenger angegeben."
};


# Template-Dateien, die HTML::Template verwendet
$TMPL = {
    Error             => "error.tmpl",          # Fehler
    Message           => "message.tmpl",        # empfangene, d.h. gelesene oder neue Nachrichten
    MessageSend       => "message_send.tmpl",   # versendete Nachrichten 
    MessageForm       => "message_form.tmpl",   # Formular zum verfassen einer neuen Nachricht
    MessageShow       => "message_show.tmpl",   # Detaillierte Einzelansicht einer Nachricht
    MessageChooseRecv => "message_choose.tmpl"  # Auswahl der Empfaenger
    };

1;




