package project_config;
 
use vars qw($VERSION);
 
$VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/;
 
$MSG = {
	NotAllowed => "Das Skript wurde mit einer falscehn Methode aufgerufen.",
	DbError    => "Es ist ein Fehler mit der Datenbank aufgetreten."
};

$TMPL = {
	Project => "project.tmpl"
};

1;
