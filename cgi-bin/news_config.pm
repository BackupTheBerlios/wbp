package news_config;

use vars qw($VERSION);

$VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/;
 
$MSG = {
  allesFalsch1  => "Sie haben keine Nachrichten.",
  allesFalsch2 => "Es ist ein unbekannter Fehler aufgetreten.",
  allesFalsch3 => "Es ist ein Fehler mit der Datenbank aufgetreten.",
  allesFalsch4  => "Sie haben kein Betreff angegeben."
};

$TMPL = {
  NewsMainAB => "news_main_ab.tmpl",
  NewsMainC  => "news_main_c.tmpl",
  NewsMainD  => "news_main_d.tmpl"
};

1;
