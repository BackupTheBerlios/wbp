#################################################################################
#                                                                               #
# Name:   package news;                                                         #
#                                                                               #
# Descr.: Enthält die komplette Verwaltung des internen Newssystems.            #
#                                                                               #
# Author: Alexander Vipach (avipach@cs.tu-berlin.de)                            #
#                                                                               #
# ToDo:   - Startdatum beachten                                                 #
#                                                                               #
#################################################################################

package news;

use Class::Date qw(date);
use Class::Singleton;
use base 'Class::Singleton';
use news_config;
use message_base;
use vars qw($VERSION $C_MSG $C_TMPL);
use strict;

$VERSION = sprintf "%d.%03d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/;

$C_MSG  = $news_config::MSG;
$C_TMPL = $news_config::TMPL;

my $Betreuer    = 0;
my $ProLeiter   = 1;
my $Mitarbeiter = 2;

##########################################################################################################
#                                                                                                        #
# Name:   parameter( $mgr );                                                                             #
#                                                                                                        #
# Descr.: Wertet die Paramter aus, wenn news aufgerufen wurde und startet dann entsprechende Prozeduren. #
#                                                                                                        #
##########################################################################################################

sub parameter {

  my $self = shift;
  my $mgr  = shift;

  my $method = $mgr->{CGI}->param('method') || undef;

  if (defined $method) {
    if ($method eq 'show_project_leader') {
      $self->show_leader_messages($mgr, $mgr->{CGI}->param('projectid'));
    } elsif ($method eq 'show_project_member') {
      $self->show_member_messages($mgr, $mgr->{CGI}->param('projectid'));
    } elsif ($method eq 'new_news') {
      $self->news_new_form( $mgr , $mgr->{CGI}->param('projectid') , $mgr->{CGI}->param('pos') );
    } elsif ($method eq 'release_news') {
      $self->release_news( $mgr , $mgr->{CGI}->param('newsid') , $mgr->{CGI}->param('projectid') , '1' );
    } elsif ($method eq 'stop_news') {
      $self->release_news( $mgr , $mgr->{CGI}->param('newsid') , $mgr->{CGI}->param('projectid') , '0' );
    } elsif ($method eq 'edit_news') {
      $self->news_edit_form( $mgr , $mgr->{CGI}->param('newsid') , $mgr->{CGI}->param('projectid') ,
                             $mgr->{CGI}->param('pos') );
    } elsif ($method eq 'del_news') {
      $self->news_del_form( $mgr , $mgr->{CGI}->param('newsid') , $mgr->{CGI}->param('projectid') ,
                            $mgr->{CGI}->param('pos') );
    };
  } else {
    if (defined $mgr->{CGI}->param('create')) {
      $self->news_create($mgr);
      return 1;
    } elsif (defined $mgr->{CGI}->param('show_projects')) {
      $self->news_show_projects($mgr);
      return 1;
    } elsif (defined $mgr->{CGI}->param('delete')) {
      $self->news_del($mgr);
      return 1;
    } elsif (defined $mgr->{CGI}->param('edit')) {
      $self->news_edit($mgr);
      return 1;
    } elsif (($mgr->{UserType} eq "A") || ($mgr->{UserType} eq "B")) {
      $self->news_user_type_AB($mgr);
    } elsif (($mgr->{UserType} eq "C")) {
      $self->news_user_type_C($mgr);
    } elsif (($mgr->{UserType} eq "D")) {
      $self->news_user_type_D($mgr);
    };
  };

  return 1;
};

#############################################################################################
#                                                                                           #
# Name:   news_user_type_AB( $mgr )                                                         #
#                                                                                           #
# Descr.: Zeigt die "Projekte suchen"-Seite für die A- und B-User an.                       #
#                                                                                           #
# Bugs:                                                                                     #
#                                                                                           #
#############################################################################################

sub news_user_type_AB {

  my $self = shift;
  my $mgr  = shift;

  $mgr->{Template} = $C_TMPL->{NewsMainAB};
  $mgr->{TmplData}{FORM} = $mgr->my_url;
  $mgr->fill;

  return 1;

};

#############################################################################################
#                                                                                           #
# Name:   news_user_type_C( $mgr )                                                          #
#                                                                                           #
# Descr.: Zeigt die Projekte an, bei denen der User Mitglied ist und die bei denen er       #
#         Projektleiter ist.                                                                #
#                                                                                           #
# Bugs:                                                                                     #
#                                                                                           #
#############################################################################################

sub news_user_type_C {

  my $self = shift;
  my $mgr  = shift;

  $mgr->{Template} = $C_TMPL->{NewsMainC};

  my @member_projects = $self->news_get_projects($mgr,$Mitarbeiter);

  my $link = $mgr->{ScriptName}."?action=news&sid=".$mgr->{Sid}."&method=show_project_member";

  if (@member_projects) {
    my @tmp;
    for (my $i = 0; $i <= $#member_projects; $i++) {
      $tmp[$i]{PR_TEXT} = $mgr->decode_all($member_projects[$i][1]);
      $tmp[$i]{PR_LINK} = $mgr->decode_all(sprintf("%s&projectid=%s", $link, $member_projects[$i][0]));
    }
    $mgr->{TmplData}{PROJECTS_MEMBER_LOOP} = \@tmp;
  }

  my @leader_projects = $self->news_get_projects($mgr,$ProLeiter);

  $link = $mgr->{ScriptName}."?action=news&sid=".$mgr->{Sid}."&method=show_project_leader";

  if (@leader_projects) {
    my @tmp;
    for (my $i = 0; $i <= $#leader_projects; $i++) {
      $tmp[$i]{PR_TEXT} = $mgr->decode_all($leader_projects[$i][1]);
      $tmp[$i]{PR_LINK} = $mgr->decode_all(sprintf("%s&projectid=%s", $link, $leader_projects[$i][0]));
    }
    $mgr->{TmplData}{PROJECTS_LEADER_LOOP} = \@tmp;
  }

  $mgr->fill;

  return 1;
};

#############################################################################################
#                                                                                           #
# Name:   news_user_type_D( $mgr )                                                          #
#                                                                                           #
# Descr.: Zeigt alle Projekte an in denen der User Mitglied ist.                            #
#                                                                                           #
# Bugs:                                                                                     #
#                                                                                           #
#############################################################################################

sub news_user_type_D {

  my $self = shift;
  my $mgr  = shift;

  $mgr->{Template} = $C_TMPL->{NewsMainD};

  my @member_projects = $self->news_get_projects($mgr,$Mitarbeiter);

  my $link = $mgr->{ScriptName}."?action=news&sid=".$mgr->{Sid}."&method=show_project_member";

  if (@member_projects) {
    my @tmp;
    for (my $i = 0; $i <= $#member_projects; $i++) {
      $tmp[$i]{PR_TEXT} = $mgr->decode_all($member_projects[$i][1]);
      $tmp[$i]{PR_LINK} = $mgr->decode_all(sprintf("%s&projectid=%s", $link, $member_projects[$i][0]));
    };
    $mgr->{TmplData}{PROJECTS_LOOP} = \@tmp;
    $mgr->{TmplData}{MEMBER_IF}=1;
  };

  $mgr->fill;

  return 1;
};

#################################################################################
#                                                                               #
# Name:   news_edit( $mgr );                                                    #
#                                                                               #
# Descr.: Wertet die im News_Edit_Form gemachten Eingaben aus und schreibt sie  #
#         in die Datenbank.                                                     #
#                                                                               #
# Bugs:                                                                         #
#                                                                               #
#################################################################################

sub news_edit {

  my $self      = shift;
  my $mgr       = shift;

  if (($mgr->{CGI}->param('subject') eq '') ||
      ($mgr->{CGI}->param('text') eq '') ||

      ((($mgr->{CGI}->param('day') eq '') ||
        ($mgr->{CGI}->param('month') eq '') ||
        ($mgr->{CGI}->param('year') eq '')) &&
       ($mgr->{CGI}->param('atonce') ne 'atonce'))
     ) {
    # Eine Eingabe ist fehlerhaft
    $mgr->{Template} = $C_TMPL->{NewsEditForm};

    $mgr->{TmplData}{PROID} = $mgr->{CGI}->param('proid');
    $mgr->{TmplData}{NEWSID} = $mgr->{CGI}->param('newsid');
    $mgr->{TmplData}{POS}   = $mgr->{CGI}->param('pos');
    $mgr->{TmplData}{FORM}  = $mgr->my_url;

    $mgr->{TmplData}{SUBJECT} = $mgr->{CGI}->param('subject');
    $mgr->{TmplData}{TEXT}    = $mgr->{CGI}->param('text');
    $mgr->{TmplData}{DAY}     = $mgr->{CGI}->param('day');
    $mgr->{TmplData}{MONTH}   = $mgr->{CGI}->param('month');
    $mgr->{TmplData}{YEAR}    = $mgr->{CGI}->param('year');
    if (defined $mgr->{CGI}->param('atonce')) {
      $mgr->{TmplData}{ATONCE} = 1;
    };

    if ($mgr->{CGI}->param('subject') eq '') { $mgr->{TmplData}{SUBJECT_ERROR} = 1; };
    if ($mgr->{CGI}->param('text') eq '') { $mgr->{TmplData}{TEXT_ERROR} = 1; };
    if ((($mgr->{CGI}->param('day') eq '') ||
         ($mgr->{CGI}->param('month') eq '') ||
         ($mgr->{CGI}->param('year') eq '')) &&
        ($mgr->{CGI}->param('atonce') ne 'atonce')) {
      $mgr->{TmplData}{DATE_ERROR} = 1;
    };

    $mgr->fill;
  } else {
    # alle Eingaben scheinen korrekt zu sein

    my $startdate;
    if (defined $mgr->{CGI}->param('atonce')) {
      $startdate = $mgr->now;
    } else {
      $startdate = date [$mgr->{CGI}->param('year'), $mgr->{CGI}->param('month'), $mgr->{CGI}->param('day'), 00, 00, 00];
    };
    my $release;
    if ($mgr->{CGI}->param('pos') == $Mitarbeiter) {
      $release = 0;
    } else {
      $release = 1;
    };
    my $dbh = $mgr->connect;
    unless ($dbh->do("LOCK TABLES $mgr->{NewsTable} WRITE")) {
      warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",$mgr->{NewsTable}, $dbh->ersstr);
    };
    my $sth = $dbh->prepare(qq{UPDATE $mgr->{NewsTable} SET subject=?, text=?, start_dt=?, project_id=?, status=?,
                               upd_dt=?, upd_id=? WHERE ID=?});
    unless ($sth->execute($mgr->{CGI}->param('subject'), $mgr->{CGI}->param('text'), $startdate,
                          $mgr->{CGI}->param('proid'), "$release", $mgr->now, $mgr->{UserId},
                          $mgr->{CGI}->param('newsid'))) {
      warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",$mgr->{NewsTable}, $dbh->errstr);
      $dbh->do("UNLOCK TABLES");
      $mgr->fatal_error($self->{C_MSG}->{DbError});
    };

    $dbh->do("UNLOCK TABLES");

    $sth->finish;

    if ($mgr->{CGI}->param('pos') == $Mitarbeiter) {
      $self->show_member_messages($mgr, $mgr->{CGI}->param('proid'))
    } else {
      $self->show_leader_messages($mgr, $mgr->{CGI}->param('proid'))
    };

  };

  return 1;
};

#################################################################################
#                                                                               #
# Name:   news_edit_form( $mgr , $news_id , $project_id , $pos );               #
#                                                                               #
# Descr.: Zeigt das Formular zum Bearbeiten von Newsbeiträgen an                #
#                                                                               #
# Bugs:                                                                         #
#                                                                               #
#################################################################################

sub news_edit_form {

  my $self       = shift;
  my $mgr        = shift;
  my $news_id    = shift;
  my $project_id = shift;
  my $pos        = shift;

  my $dbh = $mgr->connect;
  unless ($dbh->do("LOCK TABLES $mgr->{NewsTable} READ")) {
    warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",$mgr->{NewsTable}, $dbh->ersstr);
  };

  my $sth = $dbh->prepare(qq{ SELECT id, subject, text, start_dt, status, ins_id, upd_dt, upd_id FROM $mgr->{NewsTable} WHERE id = $news_id });

  unless ($sth->execute()) {
    warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{NewsTable}, $dbh->errstr);
    $mgr->fatal_error($C_MSG->{db_error});
  };

  my @news;
  while (my ($id, $subject, $text, $start_dt, $status, $ins_id, $upd_dt, $upd_id ) = $sth->fetchrow_array()) {
    push (@news, [$id, $subject, $text, $start_dt, $status, $ins_id, $upd_dt, $upd_id ]);
  }
  $sth->finish;
  $dbh->do("UNLOCK TABLES");

  my $start_dt = date $news[0][3];

  $mgr->{Template} = $C_TMPL->{NewsEditForm};

  $mgr->{TmplData}{PROID} = $project_id;
  $mgr->{TmplData}{NEWSID} = $news_id;
  $mgr->{TmplData}{POS}   = $pos;
  $mgr->{TmplData}{FORM}  = $mgr->my_url;

  $mgr->{TmplData}{SUBJECT} = $news[0][1];
  $mgr->{TmplData}{TEXT}    = $news[0][2];
  $mgr->{TmplData}{DAY}     = $start_dt->day;
  $mgr->{TmplData}{MONTH}   = $start_dt->month;
  $mgr->{TmplData}{YEAR}    = $start_dt->year;

  $mgr->fill;

  return(1);
};

#################################################################################
#                                                                               #
# Name:   news_del( $mgr );                                                     #
#                                                                               #
# Descr.: Löscht den Newsbeitrag aus der Datenbank.                             #
#                                                                               #
# Bugs:                                                                         #
#                                                                               #
#################################################################################

sub news_del {

  my $self       = shift;
  my $mgr        = shift;

  my $dbh = $mgr->connect;
  unless ($dbh->do("LOCK TABLES $mgr->{NewsTable} WRITE")) {
    warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",$mgr->{NewsTable}, $dbh->ersstr);
  };

  my $test = $mgr->{CGI}->param('newsid');
  my $sth = $dbh->prepare(qq{DELETE FROM $mgr->{NewsTable} WHERE id = $test });

  unless ($sth->execute()) {
    warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{NewsTable}, $dbh->errstr);
    $mgr->fatal_error($C_MSG->{db_error});
  };

  $sth->finish;
  $dbh->do("UNLOCK TABLES");

  if ($mgr->{CGI}->param('pos') == $Mitarbeiter) {
    $self->show_member_messages( $mgr , $mgr->{CGI}->param('proid') );
  } else {
    $self->show_leader_messages( $mgr , $mgr->{CGI}->param('proid') );
  };

  return(1);
};

#################################################################################
#                                                                               #
# Name:   news_del_form( $mgr , $news_id , $project_id , $pos );                #
#                                                                               #
# Descr.: Fragt nach, ob ausgewählter News-Beitrag wirklich gelöscht werden     #
#         soll.                                                                 #
#                                                                               #
# Bugs:                                                                         #
#                                                                               #
#################################################################################

sub news_del_form {

  my $self       = shift;
  my $mgr        = shift;
  my $news_id    = shift;
  my $project_id = shift;

  my $dbh = $mgr->connect;
  unless ($dbh->do("LOCK TABLES $mgr->{NewsTable} READ")) {
    warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",$mgr->{NewsTable}, $dbh->ersstr);
  };

  my $sth = $dbh->prepare(qq{ SELECT id, subject, text, start_dt, status, ins_id, upd_dt, upd_id FROM $mgr->{NewsTable} WHERE id = $news_id });

  unless ($sth->execute()) {
    warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{NewsTable}, $dbh->errstr);
    $mgr->fatal_error($C_MSG->{db_error});
  };

  my @news;
  while (my ($id, $subject, $text, $start_dt, $status, $ins_id, $upd_dt, $upd_id ) = $sth->fetchrow_array()) {
    push (@news, [$id, $subject, $text, $start_dt, $status, $ins_id, $upd_dt, $upd_id ]);
  }
  $sth->finish;
  $dbh->do("UNLOCK TABLES");

  $mgr->{Template} = $C_TMPL->{NewsDelForm};

  $mgr->{TmplData}{PROID} = $project_id;
  $mgr->{TmplData}{NEWSID} = $news_id;
  $mgr->{TmplData}{POS} = $news_id;
  $mgr->{TmplData}{FORM}  = $mgr->my_url;

  $mgr->{TmplData}{STATUS} = $news[0][4];
  $mgr->{TmplData}{SUBJECT} =  $mgr->decode_all($news[0][1]);
  $mgr->{TmplData}{TEXT} =  $mgr->decode_all($news[0][2]);
  $mgr->{TmplData}{AUTHOR} = $mgr->decode_all($self->news_intern_get_user($mgr, $news[0][5]));
  $mgr->{TmplData}{STDATE} = $mgr->format_date($news[0][3]);
  if ($news[0][5] ne $news[0][7]) {
    $mgr->{TmplData}{CHANGE_AUTHOR}    = $mgr->decode_all($self->news_intern_get_user($mgr, $news[0][7]));
    $mgr->{TmplData}{CHANGE_DATE}  = $mgr->format_date($news[0][6]);
  };

  $mgr->fill( $C_MSG->{ask_del} );

  return(1);
};

#################################################################################
#                                                                               #
# Name:   news_show_projects( $mgr )                                            #
#                                                                               #
# Descr.: Zeigt die Projekte an, die den Suchkriterien entsprechen.             #
#                                                                               #
# Bugs:                                                                         #
#                                                                               #
#################################################################################

sub news_show_projects {

  my $self = shift;
  my $mgr  = shift;
  my $uid = $mgr->{UserId};
  my @projects;
  my $proname = $mgr->{CGI}->param('project_name');

  my $dbh = $mgr->connect;
  unless ($dbh->do("LOCK TABLES $mgr->{ProTable} READ, $mgr->{ProUserTable} READ")) {
    warn srpintf("[Error]: Trouble locking tables [%s, %s]. Reason: [%s].",
                 $mgr->{ProTable}, $mgr->{ProUserTable}, $dbh->ersstr);
  };

  if ($mgr->{CGI}->param('project_art') eq 'all') {
    my $sth = $dbh->prepare(qq{SELECT id, name FROM $mgr->{ProTable} WHERE name LIKE '%$proname%'});
    unless ($sth->execute()) {
      warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{ProTable}, $dbh->errstr);
      $mgr->fatal_error($C_MSG->{db_error});
    };
    while (my ($id, $name) = $sth->fetchrow_array()) {
      push (@projects, [$id, $name]);
    };
    $sth->finish;
  } elsif ($mgr->{CGI}->param('project_art') eq 'care') {

    my $sth = $dbh->prepare(qq{SELECT project_id FROM $mgr->{ProUserTable} WHERE user_id='$uid' AND position='$Betreuer'});
    unless ($sth->execute()) {
      warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{ProTable}, $dbh->errstr);
      $mgr->fatal_error($C_MSG->{db_error});
    };

    my @project_ids;
    while (my ($project_id) = $sth->fetchrow_array()) {
      push (@project_ids, [$project_id]);
    };
    for (my $i = 0; $i <= $#project_ids; $i++) {
      my $sth = $dbh->prepare(qq{SELECT id, name FROM $mgr->{ProTable} WHERE id=$project_ids[$i][0]});
      unless ($sth->execute()) {
        warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{ProTable}, $dbh->errstr);
        $mgr->fatal_error($C_MSG->{db_error});
      };
      while (my ($id, $name) = $sth->fetchrow_array()) {
        push (@projects, [$id, $name]);
      };
      $sth->finish;
    };
  } elsif ($mgr->{CGI}->param('project_art') eq 'notcare') {

    my $sth = $dbh->prepare(qq{SELECT project_id FROM $mgr->{ProUserTable} WHERE user_id<>'$uid' AND position<>'$Betreuer'});
    unless ($sth->execute()) {
      warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{ProTable}, $dbh->errstr);
      $mgr->fatal_error($C_MSG->{db_error});
    };

    my @project_ids;
    while (my ($project_id) = $sth->fetchrow_array()) {
      push (@project_ids, [$project_id]);
    };
    for (my $i = 0; $i <= $#project_ids; $i++) {
      my $sth = $dbh->prepare(qq{SELECT id, name FROM $mgr->{ProTable} WHERE id=$project_ids[$i][0]});
      unless ($sth->execute()) {
        warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{ProTable}, $dbh->errstr);
        $mgr->fatal_error($C_MSG->{db_error});
      };
      while (my ($id, $name) = $sth->fetchrow_array()) {
        push (@projects, [$id, $name]);
      };
      $sth->finish;
    };
  };

  $dbh->do("UNLOCK TABLES");

  $mgr->{Template} = $C_TMPL->{NewsShowProjects};

  if (@projects) {
    my $link = $mgr->{ScriptName}."?action=news&sid=".$mgr->{Sid}."&method=show_project_leader";

    my @tmp;
    for (my $i = 0; $i <= $#projects; $i++) {
      $tmp[$i]{PR_TEXT}  = $projects[$i][1];
      $tmp[$i]{PR_LINK} = $mgr->decode_all(sprintf("%s&projectid=%s", $link, $projects[$i][0]));
    };
    $mgr->{TmplData}{PROJECTS_LOOP} = \@tmp;
    $mgr->{TmplData}{MEMBER_IF} = 1;
  } else {
    $mgr->{TmplData}{MEMBER_IF} = 0;
  };

  $mgr->fill;

  return 1;

};

#################################################################################
#                                                                               #
# Name:   news_create( $mgr )                                                   #
#                                                                               #
# Descr.: Wertet die im News_New_Form gemachten Eingaben aus und schreibt sie   #
#         in die Datenbank.                                                     #
#                                                                               #
# Bugs:                                                                         #
#                                                                               #
#################################################################################

sub news_create {

  my $self      = shift;
  my $mgr       = shift;

  if (($mgr->{CGI}->param('subject') eq '') ||
      ($mgr->{CGI}->param('text') eq '') ||

      ((($mgr->{CGI}->param('day') eq '') ||
        ($mgr->{CGI}->param('month') eq '') ||
        ($mgr->{CGI}->param('year') eq '')) &&
       ($mgr->{CGI}->param('atonce') ne 'atonce'))
     ) {
    # Eine Eingabe ist fehlerhaft
    $mgr->{Template} = $C_TMPL->{NewsNewForm};

    $mgr->{TmplData}{PROID} = $mgr->{CGI}->param('proid');
    $mgr->{TmplData}{POS}   = $mgr->{CGI}->param('pos');
    $mgr->{TmplData}{FORM}  = $mgr->my_url;

    $mgr->{TmplData}{SUBJECT} = $mgr->{CGI}->param('subject');
    $mgr->{TmplData}{TEXT}    = $mgr->{CGI}->param('text');
    $mgr->{TmplData}{DAY}     = $mgr->{CGI}->param('day');
    $mgr->{TmplData}{MONTH}   = $mgr->{CGI}->param('month');
    $mgr->{TmplData}{YEAR}    = $mgr->{CGI}->param('year');
    if (defined $mgr->{CGI}->param('atonce')) {
      $mgr->{TmplData}{ATONCE} = 1;
    };

    if ($mgr->{CGI}->param('subject') eq '') { $mgr->{TmplData}{SUBJECT_ERROR} = 1; };
    if ($mgr->{CGI}->param('text') eq '') { $mgr->{TmplData}{TEXT_ERROR} = 1; };
    if ((($mgr->{CGI}->param('day') eq '') ||
         ($mgr->{CGI}->param('month') eq '') ||
         ($mgr->{CGI}->param('year') eq '')) &&
        ($mgr->{CGI}->param('atonce') ne 'atonce')) {
      $mgr->{TmplData}{DATE_ERROR} = 1;
    };

    $mgr->fill;
  } else {
    # alle Eingaben scheinen korrekt zu sein

    my $startdate;
    if ($mgr->{CGI}->param('atonce') eq 'atonce') {
      $startdate = $mgr->now;
    } else {
      $startdate = date [$mgr->{CGI}->param('year'), $mgr->{CGI}->param('month'), $mgr->{CGI}->param('day'), 00, 00, 00];
    };
    my $release;
    if ($mgr->{CGI}->param('pos') == $Mitarbeiter) {
      $release = 0;
    } else {
      $release = 1;
    };
    my $dbh = $mgr->connect;
    unless ($dbh->do("LOCK TABLES $mgr->{NewsTable} WRITE")) {
      warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",$mgr->{NewsTable}, $dbh->ersstr);
    };
    my $sth = $dbh->prepare(qq{INSERT INTO $mgr->{NewsTable} (subject, text, start_dt, project_id, status, ins_dt, ins_id,
                               upd_dt, upd_id) VALUES (?,?,?,?,?,?,?,?,?)});
    unless ($sth->execute($mgr->{CGI}->param('subject'), $mgr->{CGI}->param('text'), $startdate,
                          $mgr->{CGI}->param('proid'), "$release", $mgr->now, $mgr->{UserId}, $mgr->now, $mgr->{UserId})) {
      warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",$mgr->{NewsTable}, $dbh->errstr);
      $dbh->do("UNLOCK TABLES");
      $mgr->fatal_error($self->{C_MSG}->{DbError});
    };

    $dbh->do("UNLOCK TABLES");

    $sth->finish;

    if ($mgr->{CGI}->param('pos') == $Mitarbeiter) {
      $self->show_member_messages($mgr, $mgr->{CGI}->param('proid'))
    } else {
      $self->show_leader_messages($mgr, $mgr->{CGI}->param('proid'))
    };

  };

  return 1;
};

#################################################################################
#                                                                               #
# Name:   show_member_messages( $mgr , $pro_id );                               #
#                                                                               #
# Descr.: Zeigt die News vom Projekt mit der ID $pro_id an!                     #
#                                                                               #
# Bugs:                                                                         #
#                                                                               #
#################################################################################

sub show_member_messages {

  my $self      = shift;
  my $mgr       = shift;
  my $projectid = shift;

  $mgr->{Template} = $C_TMPL->{NewsShowMember};
  $mgr->{TmplData}{NEWS_NEW_LINK} = $mgr->{ScriptName}."?action=news&sid=".$mgr->{Sid}."&method=new_news&projectid=".$projectid."&pos=".$Mitarbeiter;

  my $dbh = $mgr->connect;
  unless ($dbh->do("LOCK TABLES $mgr->{NewsTable} READ")) {
    warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",$mgr->{NewsTable}, $dbh->ersstr);
  };

  my $sth = $dbh->prepare(qq{ SELECT subject, text, start_dt, status, ins_id, upd_dt, upd_id, id FROM $mgr->{NewsTable} WHERE project_id = $projectid ORDER BY start_dt DESC });

  unless ($sth->execute()) {
    warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{NewsTable}, $dbh->errstr);
    $mgr->fatal_error($C_MSG->{db_error});
  };

  my @news;
  while (my ($subject, $text, $start_dt, $status, $ins_id, $upd_dt, $upd_id, $id ) = $sth->fetchrow_array()) {
    push (@news, [$subject, $text, $start_dt, $status, $ins_id, $upd_dt, $upd_id, $id]);
  }
  $sth->finish;
  $dbh->do("UNLOCK TABLES");

  my @tmp;
  # start_dt muss beachtet werden!
  # && (date($news[$i][2]) <= date($mgr->now))
  for (my $i = 0; $i <= $#news; $i++) {
    if ( (($news[$i][3] eq '1') || ($news[$i][4] == $mgr->{UserId})) ) {
      if ($news[$i][4] == $mgr->{UserId}) {
        $tmp[$i]{EDIT_LINK} = $mgr->{ScriptName}."?action=news&sid=".$mgr->{Sid}."&method=edit_news&newsid=".$news[$i][7]."&projectid=".$projectid."&pos=".$Mitarbeiter;
        $tmp[$i]{DELETE_LINK} = $mgr->{ScriptName}."?action=news&sid=".$mgr->{Sid}."&method=del_news&newsid=".$news[$i][7]."&projectid=".$projectid."&pos=".$Mitarbeiter;
      };
      $tmp[$i]{STATUS}  = $news[$i][3];
      $tmp[$i]{SUBJECT} = $mgr->decode_all($news[$i][0]);
      $tmp[$i]{STDATE} = $mgr->format_date($news[$i][2]);
      $tmp[$i]{TEXT}    = $mgr->decode_all($news[$i][1]);
      $tmp[$i]{AUTHOR}  = $mgr->decode_all($self->news_intern_get_user($mgr, $news[$i][4]));
      if ($news[$i][4] ne $news[$i][6]) {
        $tmp[$i]{CHANGE_AUTHOR}    = $mgr->decode_all($self->news_intern_get_user($mgr, $news[$i][6]));
        $tmp[$i]{CHANGE_DATE}  = $mgr->format_date($news[$i][5]);
      };
    };
  };
  $mgr->{TmplData}{NEWS_LOOP} = \@tmp;
  $mgr->fill;

  return 1;
};

#################################################################################
#                                                                               #
# Name:   show_leader_messages( $mgr , $pro_id );                               #
#                                                                               #
# Descr.: Zeigt die News vom Projekt mit der ID $pro_id an!                     #
#                                                                               #
# Bugs:                                                                         #
#                                                                               #
#################################################################################

sub show_leader_messages {

  my $self      = shift;
  my $mgr       = shift;
  my $projectid = shift;

  $mgr->{Template} = $C_TMPL->{NewsShowLeader};
  $mgr->{TmplData}{NEWS_NEW_LINK} = $mgr->{ScriptName}."?action=news&sid=".$mgr->{Sid}."&method=new_news&projectid=".$projectid."&pos=".$ProLeiter;

  my $dbh = $mgr->connect;
  unless ($dbh->do("LOCK TABLES $mgr->{NewsTable} READ")) {
    warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",$mgr->{NewsTable}, $dbh->ersstr);
  };

  my $sth = $dbh->prepare(qq{ SELECT subject, text, start_dt, status, ins_id, upd_dt, upd_id, id FROM $mgr->{NewsTable} WHERE project_id = $projectid ORDER BY start_dt DESC });

  unless ($sth->execute()) {
    warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{NewsTable}, $dbh->errstr);
    $mgr->fatal_error($C_MSG->{db_error});
  };

  my @news;
  while (my ($subject, $text, $start_dt, $status, $ins_id, $upd_dt, $upd_id, $id ) = $sth->fetchrow_array()) {
    push (@news, [$subject, $text, $start_dt, $status, $ins_id, $upd_dt, $upd_id, $id]);
  }
  $sth->finish;
  $dbh->do("UNLOCK TABLES");

  my @tmp;
  # start_dt muss beachtet werden!
  # && (date($news[$i][2]) <= date($mgr->now))
  for (my $i = 0; $i <= $#news; $i++) {
    $tmp[$i]{EDIT_LINK} = $mgr->{ScriptName}."?action=news&sid=".$mgr->{Sid}."&method=edit_news&newsid=".$news[$i][7]."&projectid=".$projectid."&pos=".$ProLeiter;
    $tmp[$i]{DELETE_LINK} = $mgr->{ScriptName}."?action=news&sid=".$mgr->{Sid}."&method=del_news&newsid=".$news[$i][7]."&projectid=".$projectid."&pos=".$ProLeiter;
    if ($news[$i][3] == '1') {
      $tmp[$i]{RELEASE_LINK} = $mgr->{ScriptName}."?action=news&sid=".$mgr->{Sid}."&method=stop_news&newsid=".$news[$i][7]."&projectid=".$projectid;
    } else {
      $tmp[$i]{RELEASE_LINK} = $mgr->{ScriptName}."?action=news&sid=".$mgr->{Sid}."&method=release_news&newsid=".$news[$i][7]."&projectid=".$projectid;
    };
    $tmp[$i]{STATUS}  = $news[$i][3];
    $tmp[$i]{SUBJECT} = $mgr->decode_all($news[$i][0]);
    $tmp[$i]{STDATE} = $mgr->format_date($news[$i][2]);
    $tmp[$i]{TEXT}    = $mgr->decode_all($news[$i][1]);
    $tmp[$i]{AUTHOR}  = $mgr->decode_all($self->news_intern_get_user($mgr, $news[$i][4]));
    if ($news[$i][4] ne $news[$i][6]) {
      $tmp[$i]{CHANGE_AUTHOR}    = $mgr->decode_all($self->news_intern_get_user($mgr, $news[$i][6]));
      $tmp[$i]{CHANGE_DATE}  = $mgr->format_date($news[$i][5]);
    };
  };
  $mgr->{TmplData}{NEWS_LOOP} = \@tmp;
  $mgr->fill;

  return 1;
};


#################################################################################
#                                                                               #
# Name:   news_new_form( $mgr , $pro_id , $pos )                                #
#                                                                               #
# Descr.: Zeigt das neue News schreiben Formular an.                            #
#                                                                               #
# Bugs:                                                                         #
#                                                                               #
#################################################################################

sub news_new_form {

  my $self   = shift;
  my $mgr    = shift;
  my $pro_id = shift;
  my $pos    = shift;

  $mgr->{Template} = $C_TMPL->{NewsNewForm};

  $mgr->{TmplData}{PROID} = $pro_id;
  $mgr->{TmplData}{POS}   = $pos;
  $mgr->{TmplData}{FORM}  = $mgr->my_url;

  $mgr->fill;

  return 1;
};

#################################################################################
#                                                                               #
# Name:   release_news( $mgr , $news_id , $project_id , $status );              #
#                                                                               #
# Descr.: Gibt den News-Artikel mit der ID $news_id frei.                       #
#                                                                               #
# Bugs:                                                                         #
#                                                                               #
#################################################################################

sub release_news {

  my $self   = shift;
  my $mgr    = shift;
  my $news_id = shift;
  my $project_id = shift;
  my $status = shift;

  my $dbh = $mgr->connect;
  unless ($dbh->do("LOCK TABLES $mgr->{NewsTable} WRITE")) {
    warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",$mgr->{NewsTable}, $dbh->ersstr);
  };

  my $sth = $dbh->prepare(qq{UPDATE $mgr->{NewsTable} SET STATUS=? WHERE ID=?});

  unless ($sth->execute( $status, $news_id )) {
    warn sprintf("[Error]: Trouble updating status in [%s]. Reason: [%s].",
                  $mgr->{NewsTable}, $dbh->errstr);
                  $dbh->do("UNLOCK TABLES");
    $mgr->fatal_error($self->{C_MSG}->{DbError});
  };

  $sth->finish;
  $dbh->do("UNLOCK TABLES");

  $self->show_leader_messages( $mgr , $project_id );

  return 1;
};

#############################################################################################
#                                                                                           #
# Name:   news_get_projects( $mgr , $pos )                                                  #
#                                                                                           #
# Descr.: Liefert alle Projekte zurück in denen der aktuelle User die Position $pos hat.    #
#                                                                                           #
# Bugs:                                                                                     #
#                                                                                           #
#############################################################################################

sub news_get_projects {

  my $self = shift;
  my $mgr  = shift;
  my $pos  = shift;

  my $dbh = $mgr->connect;
  unless ($dbh->do("LOCK TABLES $mgr->{ProUserTable} READ")) {
    warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",$mgr->{ProUserTable}, $dbh->ersstr);
  };
  my $sth = $dbh->prepare(qq{SELECT project_id FROM $mgr->{ProUserTable}
                             WHERE user_id = $mgr->{UserId} AND position = '$pos'});
  unless ($sth->execute()) {
    warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",$mgr->{ProUserTable}, $dbh->errstr);
    $dbh->do("UNLOCK TABLES");
    $mgr->fatal_error($self->{C_MSG}->{DbError});
  };

  $dbh->do("UNLOCK TABLES");

  my @pro_user;
  while (my ($project_id) = $sth->fetchrow_array()) {
    push (@pro_user, [$project_id]);
  };
  $sth->finish;

  if (@pro_user) {

    unless ($dbh->do("LOCK TABLES $mgr->{ProTable} READ")) {
      warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",$mgr->{ProTable}, $dbh->ersstr);
    };
    my @projects;
    for (my $i = 0; $i <= $#pro_user; $i++) {
      $sth = $dbh->prepare(qq{SELECT * FROM $mgr->{ProTable} WHERE id = $pro_user[$i][0]});
      unless ($sth->execute()) {
        warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",$mgr->{ProTable}, $dbh->errstr);
        $dbh->do("UNLOCK TABLES");
        $mgr->fatal_error($self->{C_MSG}->{DbError});
      };
      while (my ($id, $name, $desc_project, $cat_id, $start_dt, $end_dt, $status, $mode, $ins_dt, $ins_id,
                 $upd_dt, $upd_id) = $sth->fetchrow_array()) {
        push (@projects, [$id, $name, $desc_project, $cat_id, $start_dt, $end_dt, $status,
                        $mode, $ins_dt, $ins_id, $upd_dt, $upd_id]);
      };
    };

    $dbh->do("UNLOCK TABLES");

    $sth->finish;

    return @projects;

  } else {

    return;

  };
};

######################################################
#                                                    #
# Name:   news_intern_get_user( $mgr , $uid )        #
#                                                    #
# Descr.: Liefert den Usernamen zu einer UID zurück. #
#                                                    #
######################################################

sub news_intern_get_user {

  my $self  = shift;
  my $mgr   = shift;
  my $uid = shift;

  my $dbh = $mgr->connect;
  unless ($dbh->do("LOCK TABLES $mgr->{UserTable} READ")) {
    warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",$mgr->{UserTable}, $dbh->ersstr);
  };

  my $sth = $dbh->prepare(qq{SELECT username FROM $mgr->{UserTable} WHERE id = $uid});

  unless ($sth->execute()) {
    warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{UserTable}, $dbh->errstr);
    $mgr->fatal_error($C_MSG->{db_error});
  };

  my @user;
  while (my ($username) = $sth->fetchrow_array()) {
    push (@user, [$username]);
  }

  $sth->finish;
  $dbh->do("UNLOCK TABLES");

  return $user[0][0];
};

1;
