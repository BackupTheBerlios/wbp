package project_config;
 
use vars qw($VERSION);
 
$VERSION = sprintf "%d.%03d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/;
 
$MSG = {
	NotAllowed  => "Das Skript wurde mit einer falschen Methode aufgerufen.",
	DbError     => "Es ist ein Fehler mit der Datenbank aufgetreten.",
	NormalError => "Es ist ein allgemeiner Fehler aufgetreten.",
	ErrorAddPro => "Es ist ein Fehler beim anlegen des Projekts aufgetreten.",
	LengthName  => "Der Name darf nicht l�nger als 255 Zeichen sein.",
	EmptyName   => "Der Name darf nicht leer sein.",
	ErrorDate   => "Das ist kein korecktes Datum.",
	ExistName   => "Dieser Name existiert bereits.",
	InsertProOk => "Das Projekt wurde angelegt."
};

$TMPL = {
	Project    => "project.tmpl",
	ProjectNew => "project_new.tmpl"
};

1;
