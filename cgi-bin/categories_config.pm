package categories_config;
 
use vars qw($VERSION);
 
$VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/;
 
$MSG = {
  user_cd_error => "Die Kategorienverwaltung ist nur fuer User vom Typ A und B interessant.",
  db_error      => "Es ist ein Fehler mit der Datenbank aufgetreten."
};

$TMPL = {
  CatMain => "cats_main.tmpl"
};

1;
