package project_config;
 
use vars qw($VERSION);
 
$VERSION = sprintf "%d.%03d", q$Revision: 1.13 $ =~ /(\d+)\.(\d+)/;
 
$MSG = {
	NotAllowed     => "Das Skript wurde mit einer falschen Methode aufgerufen.",
	DbError        => "Es ist ein Fehler mit der Datenbank aufgetreten.",
	NormalError    => "Es ist ein allgemeiner Fehler aufgetreten.",
	ErrorAddPro    => "Es ist ein Fehler beim anlegen des Projekts aufgetreten.",
	ErrorAddPha    => "Es ist ein Fehler beim anlegen der Phase aufgetreten.",
	ErrorChangePro => "Es ist ein Fehler beim �ndern des Projekts aufgetreten.",
	ErrorChangePha => "Es ist ein Fehler beim �ndern der Phase aufgetreten.",
	LengthName     => "Der Name darf nicht l�nger als 255 Zeichen sein.",
	EmptyName      => "Der Name darf nicht leer sein.",
	ErrorDate      => "Das ist kein korecktes Datum.",
	ExistName      => "Dieser Name existiert bereits.",
	InsertProOk    => "Das Projekt wurde angelegt.",
	InsertPhaOk    => "Die Phase wurde angelegt.",
	UpdateProOk    => "Das Projekt wurde ge�ndert.",
	UpdatePhaOk    => "Die Phase wurde ge�ndert.",
	CountProjects  => "Anzahl gefundener Projekte: %s.",
	Inaktive       => "inaktiv",
	Aktive         => "aktiv",
	Closed         => "fertig",
	Private        => "privat",
	Public         => "�ffentlich",
	ChangeStatus   => "Der Status wurde ge�ndert.",
	ChangeMode     => "Der Modus wurde ge�ndert.",
	StartEndDate   => "Das Startdatum mu� vor dem Endedatum liegen.",
	NoProjects     => "Sie sind in keinem Projekt Projektleiter.",
	NoChanges      => "Keine �nderungen vorgenommen.",
	DelPhaOk       => "Die Projetphase wurde gel�scht.",
	NoUserSelected => "Sie haben keinen User ausgew�hlt.",
	UserAddOk      => "Der User wurde erfolgreich hinzufeg�gt.",
	UserDelOk      => "Der User wurde aus dem Projekt gel�scht."
};

$TMPL = {
	ProjectAB     => "project_ab.tmpl",
	ProjectC      => "project_c.tmpl",
	ProjectNew    => "project_new.tmpl",
	ProjectShow   => "project_show.tmpl",
	ProjectChange => "project_change.tmpl",
	ProPhaStart   => "project_phase.tmpl",
	ProPhaNew     => "project_phase_new.tmpl",
	ProPhaChange  => "project_phase_change.tmpl",
	ProUserAB     => "project_user_ab.tmpl",
	ProUserC      => "project_user_c.tmpl",
	ProUserCD     => "project_user_cd.tmpl"
};

1;
