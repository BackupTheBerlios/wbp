package news;

use Class::Singleton;
use base 'Class::Singleton';
use news_config;
use message_base;
use vars qw($VERSION $C_MSG $C_TMPL);
use strict;

$VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/;

$C_MSG  = $news_config::MSG;
$C_TMPL = $news_config::TMPL;

my $Betreuer    = 0;
my $ProLeiter   = 1;
my $Mitarbeiter = 2;

sub parameter {

  my $self = shift;
  my $mgr  = shift;

  # UserType abfragen

  if (($mgr->{UserType} eq "A") || ($mgr->{UserType} eq "B")) {
    $self->news_user_type_AB($mgr);
  } elsif (($mgr->{UserType} eq "C")) {
    $self->news_user_type_C($mgr);
  } elsif (($mgr->{UserType} eq "D")) {
    $self->news_user_type_D($mgr);
  }

  return 1;
};

sub news_user_type_AB {

  my $self = shift;
  my $mgr  = shift;

  my $dbh = $mgr->connect;
  my $sth = $dbh->prepare(qq{SELECT id, name FROM $mgr->{ProTable}});

  unless ($sth->execute()) {
    warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{ProTable}, $dbh->errstr);
    $mgr->fatal_error($message_config::MSG->{DbError});
  };

  my @projects;
  while (my ($id, $name) = $sth->fetchrow_array()) {
    push (@projects, [$id, $name]);
  }
  $sth->finish;

  $mgr->{Template} = $C_TMPL->{NewsMainAB}; # aktuelles Template festlegen

  my $link = $mgr->{ScriptName}."?action=news&sid=".$mgr->{Sid}."&method=show_project";

  if (@projects) {
    my @tmp;
    for (my $i = 0; $i <= $#projects; $i++) {
      $tmp[$i]{PR_TEXT} = $mgr->decode_all($projects[$i][1]);
      $tmp[$i]{PR_LINK} = $mgr->decode_all(sprintf("%s&projectid=%s", $link, $projects[$i][0]));
    }
    $mgr->{TmplData}{PROJECT_LOOP} = \@tmp;
  }

  $mgr->fill; # Füllt das Template und zeigt es an

  return 1;
};

sub news_user_type_C {
  return 1;
};

sub news_user_type_D {

  my $self = shift;
  my $mgr  = shift;

  my $dbh = $mgr->connect;
  unless ($dbh->do("LOCK TABLES $mgr->{UserProTable} READ")) {
    warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",$mgr->{UserProTable}, $dbh->ersstr);
  };
  my $sth = $dbh->prepare(qq{SELECT project_id FROM $mgr->{UserProTable} WHERE user_id = $mgr->{UserId}});
  unless ($sth->execute()) {
    warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",$mgr->{UserProTable}, $dbh->errstr);
    $dbh->do("UNLOCK TABLES");
    $mgr->fatal_error($self->{C_MSG}->{DbError});
  };

  $dbh->do("UNLOCK TABLES");

  my @pro_user;
  while (my ($project_id) = $sth->fetchrow_array()) {
    push (@pro_user, [$project_id]);
  }
  $sth->finish;

  if (@pro_user) {
    for (my $i = 0; $i <= $#pro_user; $i++) {

    };
  } else {
    $mgr->{Template} = $C_TMPL->{NewsMainC};
    $mgr->{Template}{MEMBER_IF} = '0';
    $mgr->fill;
  };

  return 1;
};

1;
