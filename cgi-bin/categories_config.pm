package categories_config;

use vars qw($VERSION);

$VERSION = sprintf "%d.%03d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/;

$MSG = {
  user_cd_error => "Die Kategorienverwaltung ist nur fuer User vom Typ A und B interessant.",
  db_error      => "Es ist ein Fehler mit der Datenbank aufgetreten.",
  inactiv       => "inaktiv",
  activ         => "aktiv",
  inactiv_st    => "inaktive",
  activ_st      => "aktive",
  all_st        => "alle",
  category      => "Rubrik",
  cat_create    => "Rubrik wurde angelegt",
  cat_change    => "Rubrik wurde g&auml;ndert",
  exist_all     => "Es existieren keine Rubriken",
  exist_activ   => "Es existieren keine aktiven Rubriken",
  exist_inactiv => "Es existieren keine inaktiven Rubriken"
};

$TMPL = {
  CatMain   => "cats_main.tmpl",
  CatsShow  => "cats_show.tmpl",
  CatCreate => "cat_create.tmpl",
  CatShow   => "cat_show.tmpl"
};

1;
