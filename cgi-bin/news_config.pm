package news_config;

use vars qw($VERSION);

$VERSION = sprintf "%d.%03d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/;

$MSG = {
  db_error => "Es ist ein Fehler mit der Datenbank aufgetreten."
};

$TMPL = {
  NewsMainAB       => "news_main_ab.tmpl",
  NewsMainC        => "news_main_c.tmpl",
  NewsMainD        => "news_main_d.tmpl",
  NewsShowMember   => "news_show_member.tmpl",
  NewsShowLeader   => "news_show_leader.tmpl",
  NewsShowProjects => "news_show_projects.tmpl",
  NewsNewForm      => "news_new_form.tmpl"
};

1;
