#################################################################################
#                                                                               #
# Name:   package categories;                                                   #
#                                                                               #
# Descr.: Enthält die komplette Rubrikenverwaltung (anzeigen, anlegen, ändern). #
#                                                                               #
# Author: Alexander Vipach (avipach@cs.tu-berlin.de)                            #
#                                                                               #
#################################################################################

package categories;

use Class::Singleton;
use base 'Class::Singleton';
use categories_config;
use vars qw($VERSION $C_MSG $C_TMPL);
use strict;

$VERSION = sprintf "%d.%03d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/;

$C_MSG  = $categories_config::MSG;
$C_TMPL = $categories_config::TMPL;

################################################################################################################
#                                                                                                              #
# Name:   parameter( $mgr );                                                                                   #
#                                                                                                              #
# Descr.: Wertet die Paramter aus, wenn categories aufgerufen wurde und startet dann entsprechende Prozeduren. #
#                                                                                                              #
################################################################################################################


sub parameter {

  my $self = shift;
  my $mgr  = shift;

  my $method = $mgr->{CGI}->param('method') || undef;

  # Methode abfragen
  if (defined $method) {
    if ($method eq 'show_all') {
      $self->categories_show($mgr,'all');
    } elsif ($method eq 'show_activ') {
      $self->categories_show($mgr,'activ');
    } elsif ($method eq "show_inactiv") {
      $self->categories_show($mgr,'inactiv');
    } elsif ($method eq "create_form") {
      $self->categories_create_form($mgr);
    } elsif ($method eq "change_status") {
      $self->categories_change_status($mgr, $mgr->{CGI}->param('catid'),$mgr->{CGI}->param('cat_art'),$mgr->{CGI}->param('cat_name'));
    } elsif ($method eq "del_cat") {
      $self->categories_delete($mgr,$mgr->{CGI}->param('catid'),$mgr->{CGI}->param('cat_art'),$mgr->{CGI}->param('cat_name'));
    } elsif ($method eq "show_cat") {
      $self->categories_show_one($mgr,$mgr->{CGI}->param('catid'));
    } elsif ($method eq "edit_cat") {
      $self->categories_edit($mgr,$mgr->{CGI}->param('catid'));
    }
  } else {
    if (defined $mgr->{CGI}->param('create')) {
      $self->categories_create($mgr);
      return 1;
    } elsif (defined $mgr->{CGI}->param('change')) {
      $self->categories_change($mgr,$mgr->{CGI}->param('catid'));
      return 1;
    } elsif (defined $mgr->{CGI}->param('create_cat')) {
      $self->categories_create_form($mgr);
      return 1;
    } elsif (defined $mgr->{CGI}->param('show_cats')) {
      $self->categories_show($mgr, $mgr->{CGI}->param('cat_art'), $mgr->{CGI}->param('cat_name'));
      return 1;
    } else {
      # UserType abfragen
      if (($mgr->{UserType} eq "A") || ($mgr->{UserType} eq "B")) {
        $self->categories_user_type_AB($mgr);
      } elsif (($mgr->{UserType} eq "C") || ($mgr->{UserType} eq "D")) {
        $self->categories_user_type_CD($mgr);
      };
    };
  }

  return 1;
};

#############################################################
#                                                           #
# Name:   categories_user_type_AB( $mgr );                  #
#                                                           #
# Descr.: Erstellt die Startseite für User vom Typ A und B. #
#                                                           #
#############################################################


sub categories_user_type_AB {

  my $self = shift;
  my $mgr  = shift;

  $mgr->{Template} = $C_TMPL->{CatMain}; # aktuelles Template festlegen
  $mgr->{TmplData}{FORM} = $mgr->my_url;

  my $dbh = $mgr->connect;

  unless ($dbh->do("LOCK TABLES $mgr->{CatTable} READ")) {
    warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",$mgr->{CatTable}, $dbh->ersstr);
  };

  my $sth = $dbh->prepare(qq{SELECT id FROM $mgr->{CatTable}});

  unless ($sth->execute()) {
    warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{CatTable}, $dbh->errstr);
    $mgr->fatal_error($C_MSG->{db_error});
  };

  $dbh->do("UNLOCK TABLES");

  my @cats;
  while (my ($id) = $sth->fetchrow_array()) {
    push (@cats, [$id]);
  }

  if (@cats) {
    $mgr->{TmplData}{SHOW_CAT_IF} = 1;
  } else {
    $mgr->{TmplData}{SHOW_CAT_IF} = 0;
  }

  $mgr->fill; # Füllt das Template und zeigt es an

  return 1;
};

#######################################################################################################
#                                                                                                     #
# Name:   categories_user_type_CD( $mgr );                                                            #
#                                                                                                     #
# Descr.: Erstellt die Startseite für User vom Typ C und D. Sollte eigentlich _nie_ angezeigt werden. #
#                                                                                                     #
#######################################################################################################

sub categories_user_type_CD {

  my $self = shift;
  my $mgr  = shift;

  $mgr->{Template} = $C_TMPL->{Error};
  $mgr->{TmplData}{MSG} = $C_MSG->{user_cd_error};
  $mgr->fill;

  return 1;
};

#################################################################################################
#                                                                                               #
# Name:   categories_show( $mgr , $status_param , $catname );                                   #
#                                                                                               #
# Descr.: Zeigt alle Rubriken an, die den Suchkriterien $status_param und $catname entsprechen. #
#                                                                                               #
#################################################################################################

sub categories_show {

  my $self = shift;
  my $mgr  = shift;
  my $status_param = shift;
  my $catname = shift;

  my $dbh = $mgr->connect;
  unless ($dbh->do("LOCK TABLES $mgr->{CatTable} READ")) {
    warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",$mgr->{CatTable}, $dbh->ersstr);
  };

  my $sth;

  if ($status_param eq 'all') {
    $sth = $dbh->prepare(qq{SELECT id, name, status FROM $mgr->{CatTable} WHERE name LIKE '%$catname%'});
  } elsif ($status_param eq 'inactiv') {
    $sth = $dbh->prepare(qq{SELECT id, name, status FROM $mgr->{CatTable} WHERE status = '0' AND name LIKE '%$catname%'});
  } elsif ($status_param eq 'activ') {
    $sth = $dbh->prepare(qq{SELECT id, name, status FROM $mgr->{CatTable} WHERE status = '1' AND name LIKE '%$catname%'});
  };

  unless ($sth->execute()) {
    warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{CatTable}, $dbh->errstr);
    $mgr->fatal_error($C_MSG->{db_error});
  };

  my @cats;
  while (my ($id, $name, $status) = $sth->fetchrow_array()) {
    push (@cats, [$id, $name, $status]);
  }
  $sth->finish;
  $dbh->do("UNLOCK TABLES");
  $mgr->{Template} = $C_TMPL->{CatsShow}; # aktuelles Template festlegen

  if (@cats) {

    $mgr->{TmplData}{NO_CATS} = '0';

    my $link_show = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=show_cat";
    my $link_edit = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=edit_cat";
    my $link_del = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=del_cat&cat_art=".$status_param."&cat_name=".$catname;
    my $link_status = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=change_status&cat_art=".$status_param."&cat_name=".$catname;

    my @tmp;
    for (my $i = 0; $i <= $#cats; $i++) {
      $tmp[$i]{CAT_NAME} = $mgr->decode_all($cats[$i][1]);
      $tmp[$i]{SHOW_LINK} = $mgr->decode_all(sprintf("%s&catid=%s", $link_show, $cats[$i][0]));
      $tmp[$i]{EDIT_LINK} = $mgr->decode_all(sprintf("%s&catid=%s", $link_edit, $cats[$i][0]));
      if ($self->categories_checkproject($mgr, $cats[$i][0])) {
        $tmp[$i]{DELETE_IF} = 0;
      } else {
        $tmp[$i]{DELETE_IF} = 1;
        $tmp[$i]{DEL_LINK} = $mgr->decode_all(sprintf("%s&catid=%s", $link_del, $cats[$i][0]));
      };
      if ($cats[$i][2] eq '0') {
        $tmp[$i]{STATUS_TEXT} = $C_MSG->{inactiv};
        $tmp[$i]{STATUS_LINK} = $mgr->decode_all(sprintf("%s&catid=%s", $link_status, $cats[$i][0]));
      } else {
        $tmp[$i]{STATUS_TEXT} = $C_MSG->{activ};
        $tmp[$i]{STATUS_LINK} = $mgr->decode_all(sprintf("%s&catid=%s", $link_status, $cats[$i][0]));
      };

      $mgr->{TmplData}{CATS_LOOP} = \@tmp;
    };
    if ($status_param eq 'all') {
      $mgr->{TmplData}{CAT_STATUS} = $C_MSG->{all_st};
    } elsif ($status_param eq 'inactiv') {
      $mgr->{TmplData}{CAT_STATUS} = $C_MSG->{inactiv_st};
    } elsif ($status_param eq 'activ') {
      $mgr->{TmplData}{CAT_STATUS} = $C_MSG->{activ_st};
    };
  } else {
    $mgr->{TmplData}{NO_CATS}='1';
    if ($status_param eq 'all') {
      $mgr->{TmplData}{CAT_STATUS} = $C_MSG->{exist_all};
    } elsif ($status_param eq 'inactiv') {
      $mgr->{TmplData}{CAT_STATUS} = $C_MSG->{exist_inactiv};
    } elsif ($status_param eq 'activ') {
      $mgr->{TmplData}{CAT_STATUS} = $C_MSG->{exist_activ};
    };
  };
  $mgr->fill;

  return 1;
}

############################################
#                                          #
# Name:   categories_createform( $mgr )    #
#                                          #
# Descr.: Zeigt das CatCreate-Formular an. #
#                                          #
############################################

sub categories_create_form {

  my $self = shift;
  my $mgr  = shift;

  $mgr->{Template} = $C_TMPL->{CatCreate};
  $mgr->{TmplData}{CREATE_CHANGE} = '1';
  $mgr->{TmplData}{CHECKED_ACTIV} = '1';
  $mgr->{TmplData}{FORM} = $mgr->my_url;
  $mgr->fill;

  return 1;

};

######################################################################################
#                                                                                    #
# Name:   categories_create( $mgr )                                                  #
#                                                                                    #
# Descr.: Schreibt die Rubrik mit den Daten aus CatCreate-Formular in die Datenbank. #
#                                                                                    #
######################################################################################

sub categories_create {

  my $self = shift;
  my $mgr  = shift;

  my $dbh = $mgr->connect;
  unless ($dbh->do("LOCK TABLES $mgr->{CatTable} WRITE")) {
    warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",$mgr->{CatTable}, $dbh->ersstr);
  };

  my $cat_name = $mgr->{CGI}->param('cat_name');
  my $sth = $dbh->prepare(qq{SELECT name FROM $mgr->{CatTable} WHERE name='$cat_name'});

  unless ($sth->execute()) {
    warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{CatTable}, $dbh->errstr);
    $mgr->fatal_error($C_MSG->{db_error});
  };

  my @cats;
  while (my ($name) = $sth->fetchrow_array()) {
    push (@cats, [$name]);
  };

  if (@cats) {
    # Error: Kategorie existiert bereits
    $mgr->{Template} = $C_TMPL->{CatCreate};
    $mgr->{TmplData}{FORM} = $mgr->my_url;
    $mgr->{TmplData}{CAT_IF} = '1';
    $mgr->{TmplData}{CAT_NAME} = $cat_name;
    $mgr->{TmplData}{CAT_DESCR} = $mgr->{CGI}->param('descr');
    if ($mgr->{CGI}->param('activ') eq 'activ') {
      $mgr->{TmplData}{CHECKED_ACTIV} = '1';
    } else {
      $mgr->{TmplData}{CHECKED_ACTIV} = '0';
    };
    $mgr->{TmplData}{CREATE_CHANGE} = '1';
    $mgr->fill;
  } else {

    my $status;
    if ($mgr->{CGI}->param('activ') eq 'activ') {
      $status = '1';
    } else {
      $status = '0';
    };

    $sth = $dbh->prepare(qq{INSERT INTO $mgr->{CatTable} (name,desc_category,status,ins_dt,ins_id,upd_dt,upd_id) VALUES
                            (?,?,?,?,?,?,?)});

    unless ($sth->execute($cat_name, $mgr->{CGI}->param('descr'), $status, $mgr->now,
                                $mgr->{UserId}, $mgr->now, $mgr->{UserId})) {
      warn sprintf("[Error]: Trouble inserting project into [%s]. Reason [%s].",$mgr->{CatTable}, $dbh->errstr);
      $mgr->fatal_error($C_MSG->{DbError});
    };

    $sth = $dbh->prepare(qq{SELECT * FROM $mgr->{CatTable} WHERE name='$cat_name'});

    unless ($sth->execute()) {
      warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{CatTable}, $dbh->errstr);
      $mgr->fatal_error($C_MSG->{db_error});
    };

    my @cats;
    while (my ($id, $name, $descr, $status, $ins_dt, $ins_id, $upd_dt, $upd_id) = $sth->fetchrow_array()) {
      push (@cats, [$id, $name, $descr, $status, $ins_dt, $ins_id, $upd_dt, $upd_id]);
    };

    $sth->finish;

    $mgr->{Template} = $C_TMPL->{CatShow}; # aktuelles Template festlegen

    $mgr->{TmplData}{HEADLINE} = $C_MSG->{cat_create};

    $mgr->{TmplData}{ID} = $cats[0][0];
    $mgr->{TmplData}{NAME} = $cats[0][1];
    $mgr->{TmplData}{DESCR} = $cats[0][2];
    if ($cats[0][3] == '0') {
      $mgr->{TmplData}{STATUS} = $C_MSG->{inactiv};
    } else {
      $mgr->{TmplData}{STATUS} = $C_MSG->{activ};
    };
    $mgr->{TmplData}{INS_DT} = $mgr->format_date($cats[0][4]);
    $mgr->{TmplData}{INS_ID} = $self->categories_intern_get_user($mgr,$cats[0][5]);
    $mgr->{TmplData}{UPD_DT} = $mgr->format_date($cats[0][6]);
    $mgr->{TmplData}{UPD_ID} = $self->categories_intern_get_user($mgr,$cats[0][7]);

    $mgr->{TmplData}{EDIT_CAT_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=edit_cat&catid=".$cats[0][0];

    if($self->categories_checkproject($mgr,$cats[0][0])) {
      $mgr->{TmplData}{DELETE_LINK_IF} = 0;
    } else {
      $mgr->{TmplData}{DELETE_LINK_IF} = 1;
      my $link_del = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=del_cat&cat_art=one&catid=".$cats[0][0];
      $mgr->{TmplData}{DELETE_CAT_LINK} = $link_del;
    };

    $mgr->fill;

  };
  $dbh->do("UNLOCK TABLES");
  return 1;
};

#############################################################################################
#                                                                                           #
# Name:   categories_change( $mgr )                                                         #
#                                                                                           #
# Descr.: Nimmt die Änderungen in der Datenbank vor, die aus dem CatCreate-Formular kommen. #
#                                                                                           #
# Bugs:                                                                                     #
#                                                                                           #
#############################################################################################

sub categories_change {

  my $self = shift;
  my $mgr  = shift;

  my $dbh = $mgr->connect;
  unless ($dbh->do("LOCK TABLES $mgr->{CatTable} WRITE")) {
    warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",$mgr->{CatTable}, $dbh->ersstr);
  };

  my $cat_name = $mgr->{CGI}->param('cat_name');
  my $sth = $dbh->prepare(qq{SELECT id, name FROM $mgr->{CatTable} WHERE name='$cat_name'});

  unless ($sth->execute()) {
    warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{CatTable}, $dbh->errstr);
    $mgr->fatal_error($C_MSG->{db_error});
  };

  my @cats;
  while (my ($name) = $sth->fetchrow_array()) {
    push (@cats, [$name]);
  };

  if ((@cats) && (($mgr->{CGI}->param('catid')) != ($cats[0][0]))) {
    # Error: Kategorie existiert bereits
    $mgr->{Template} = $C_TMPL->{CatCreate}; # aktuelles Template festlegen
    $mgr->{TmplData}{FORM} = $mgr->my_url;
    $mgr->{TmplData}{CAT_IF} = '1';
    $mgr->{TmplData}{CAT_NAME} = $cat_name;
    $mgr->{TmplData}{CAT_DESCR} = $mgr->{CGI}->param('descr');
    $mgr->{TmplData}{CATID} = $mgr->{CGI}->param('catid');
    if ($mgr->{CGI}->param('activ') eq 'activ') {
      $mgr->{TmplData}{CHECKED_ACTIV} = '1';
    } else {
      $mgr->{TmplData}{CHECKED_ACTIV} = '0';
    };
    $mgr->{TmplData}{CREATE_CHANGE} = '0';
    $mgr->fill;
  } else {

    my $status;
    if ($mgr->{CGI}->param('activ') eq 'activ') {
      $status = '1';
    } else {
      $status = '0';
    };

    $sth = $dbh->prepare(qq{UPDATE $mgr->{CatTable} SET NAME=?, DESC_CATEGORY=?, UPD_DT=?, UPD_ID=?, STATUS=? WHERE ID=?});

    unless ($sth->execute( $cat_name,$mgr->{CGI}->param('descr') , $mgr->now,$mgr->{UserId} , $status ,
                           $mgr->{CGI}->param('catid') )) {
      warn sprintf("[Error]: Trouble updating status in [%s]. Reason: [%s].",
                    $mgr->{CatTable}, $dbh->errstr);
                    $dbh->do("UNLOCK TABLES");
      $mgr->fatal_error($self->{C_MSG}->{DbError});
    };

    $sth = $dbh->prepare(qq{SELECT * FROM $mgr->{CatTable} WHERE name='$cat_name'});

    unless ($sth->execute()) {
      warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{CatTable}, $dbh->errstr);
      $mgr->fatal_error($C_MSG->{db_error});
    };

    my @cats;
    while (my ($id, $name, $descr, $status, $ins_dt, $ins_id, $upd_dt, $upd_id) = $sth->fetchrow_array()) {
      push (@cats, [$id, $name, $descr, $status, $ins_dt, $ins_id, $upd_dt, $upd_id]);
    };

    $sth->finish;

    $mgr->{Template} = $C_TMPL->{CatShow}; # aktuelles Template festlegen

    $mgr->{TmplData}{HEADLINE} = $C_MSG->{cat_change};

    $mgr->{TmplData}{ID} = $cats[0][0];
    $mgr->{TmplData}{NAME} = $cats[0][1];
    $mgr->{TmplData}{DESCR} = $cats[0][2];
    if ($cats[0][3] == '0') {
      $mgr->{TmplData}{STATUS} = $C_MSG->{inactiv};
    } else {
      $mgr->{TmplData}{STATUS} = $C_MSG->{activ};
    };
    $mgr->{TmplData}{INS_DT} = $mgr->format_date($cats[0][4]);
    $mgr->{TmplData}{INS_ID} = $self->categories_intern_get_user($mgr,$cats[0][5]);
    $mgr->{TmplData}{UPD_DT} = $mgr->format_date($cats[0][6]);
    $mgr->{TmplData}{UPD_ID} = $self->categories_intern_get_user($mgr,$cats[0][7]);
    $mgr->{TmplData}{EDIT_CAT_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=edit_cat&catid=".$cats[0][0];
    if($self->categories_checkproject($mgr,$cats[0][0])) {
      $mgr->{TmplData}{DELETE_LINK_IF} = 0;
    } else {
      $mgr->{TmplData}{DELETE_LINK_IF} = 1;
      my $link_del= $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=del_cat&proc=one&catid=".$cats[0][0];
      $mgr->{TmplData}{DELETE_CAT_LINK} = $link_del;
    };
    $mgr->fill;
  };
  $dbh->do("UNLOCK TABLES");
  return 1;
}

##########################################################################
#                                                                        #
# Name:   categories_edit( $mgr , $catid )                               #
#                                                                        #
# Descr.: Füllt das Formular zum Editieren von Rubriken und zeigt es an. #
#                                                                        #
##########################################################################

sub categories_edit {

  my $self  = shift;
  my $mgr   = shift;
  my $catid = shift;

  my $dbh = $mgr->connect;
  unless ($dbh->do("LOCK TABLES $mgr->{CatTable} READ")) {
    warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",$mgr->{CatTable}, $dbh->ersstr);
  };

  my $sth = $dbh->prepare(qq{SELECT * FROM $mgr->{CatTable} WHERE id = '$catid'});

  unless ($sth->execute()) {
    warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{CatTable}, $dbh->errstr);
    $mgr->fatal_error($C_MSG->{db_error});
  };

  my @cats;
  while (my ($id, $name, $descr, $status, $ins_dt, $ins_id, $upd_dt, $upd_id) = $sth->fetchrow_array()) {
    push (@cats, [$id, $name, $descr, $status, $ins_dt, $ins_id, $upd_dt, $upd_id]);
  };

  $sth->finish;
  $dbh->do("UNLOCK TABLES");

  $mgr->{Template} = $C_TMPL->{CatCreate}; # aktuelles Template festlegen
  $mgr->{TmplData}{CREATE_CHANGE} = '0';
  $mgr->{TmplData}{FORM} = $mgr->my_url;
  $mgr->{TmplData}{CAT_IF} = '0';
  $mgr->{TmplData}{CAT_NAME} = $mgr->decode_all($cats[0][1]);
  $mgr->{TmplData}{CAT_DESCR} = $mgr->decode_all($cats[0][2]);
  $mgr->{TmplData}{CATID} = $catid;
  $mgr->{TmplData}{CREATE_CHANGE} = '0';
  $mgr->{TmplData}{CHECKED_ACTIV} = $cats[0][3];
  $mgr->fill;

  return 1;
};

############################################################################
#                                                                          #
# Name:   categories_change_status( $mgr , $catid , $cat_art , $cat_name ) #
#                                                                          #
# Descr.: Ändert den Status einer Rubrik.                                  #
#                                                                          #
# Bugs:                                                                    #
#                                                                          #
############################################################################

sub categories_change_status {

  my $self     = shift;
  my $mgr      = shift;
  my $catid    = shift;
  my $cat_art  = shift;
  my $cat_name = shift;


  my $dbh = $mgr->connect;
  unless ($dbh->do("LOCK TABLES $mgr->{CatTable} WRITE")) {
    warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",$mgr->{CatTable}, $dbh->ersstr);
  };

  my $sth = $dbh->prepare(qq{SELECT id, status FROM $mgr->{CatTable} WHERE id = $catid});

  unless ($sth->execute()) {
    warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{CatTable}, $dbh->errstr);
    $mgr->fatal_error($C_MSG->{db_error});
  };

  my @cats;
  while (my ($id, $status) = $sth->fetchrow_array()) {
    push (@cats, [$id, $status]);
  }

  if ($cats[0][1] == '0') {
    $sth = $dbh->prepare( qq{ UPDATE $mgr->{CatTable} SET STATUS = '1' WHERE id = $catid });
  } else {
    $sth = $dbh->prepare( qq{ UPDATE $mgr->{CatTable} SET STATUS = '0' WHERE id = $catid });
  }

  unless ($sth->execute()) {
    warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{CatTable}, $dbh->errstr);
    $mgr->fatal_error($C_MSG->{db_error});
  };

  $sth->finish;
  $dbh->do("UNLOCK TABLES");

  $self->categories_show($mgr,$cat_art,$cat_name);

  return 1;
};

################################################
#                                              #
# Name:   categories_show_one( $mgr , $catid ) #
#                                              #
# Descr.: Zeigt eine Rubrik an.                #
#                                              #
################################################

sub categories_show_one {

  my $self  = shift;
  my $mgr   = shift;
  my $catid = shift;

  my $dbh = $mgr->connect;
  unless ($dbh->do("LOCK TABLES $mgr->{CatTable} READ")) {
    warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",$mgr->{CatTable}, $dbh->ersstr);
  };

  my $sth = $dbh->prepare(qq{SELECT * FROM $mgr->{CatTable} WHERE id = $catid});

  unless ($sth->execute()) {
    warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{CatTable}, $dbh->errstr);
    $mgr->fatal_error($C_MSG->{db_error});
  };

  my @cats;
  while (my ($id, $name, $descr, $status, $ins_dt, $ins_id, $upd_dt, $upd_id) = $sth->fetchrow_array()) {
    push (@cats, [$id, $name, $descr, $status, $ins_dt, $ins_id, $upd_dt, $upd_id]);
  };

  $sth->finish;
  $dbh->do("UNLOCK TABLES");

  $mgr->{Template} = $C_TMPL->{CatShow}; # aktuelles Template festlegen

  $mgr->{TmplData}{HEADLINE} = $C_MSG->{category};

  $mgr->{TmplData}{ID} = $cats[0][0];
  $mgr->{TmplData}{NAME} = $cats[0][1];
  $mgr->{TmplData}{DESCR} = $cats[0][2];
  if ($cats[0][3] == '0') {
    $mgr->{TmplData}{STATUS} = $C_MSG->{inactiv};
  } else {
    $mgr->{TmplData}{STATUS} = $C_MSG->{activ};
  };
  $mgr->{TmplData}{INS_DT} = $mgr->format_date($cats[0][4]);
  $mgr->{TmplData}{INS_ID} = $self->categories_intern_get_user($mgr,$cats[0][5]);
  $mgr->{TmplData}{UPD_DT} = $mgr->format_date($cats[0][6]);
  $mgr->{TmplData}{UPD_ID} = $self->categories_intern_get_user($mgr,$cats[0][7]);

  $mgr->{TmplData}{EDIT_CAT_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=edit_cat&catid=".$cats[0][0];


  if($self->categories_checkproject($mgr,$cats[0][0])) {
    $mgr->{TmplData}{DELETE_LINK_IF} = 0;
  } else {
    $mgr->{TmplData}{DELETE_LINK_IF} = 1;
    my $link_del = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=del_cat&cat_art=one&catid=".$cats[0][0];
    $mgr->{TmplData}{DELETE_CAT_LINK} = $link_del;
  }

  $mgr->fill;

  return 1;
};

######################################################
#                                                    #
# Name:   categories_intern_get_user( $mgr , $uid )  #
#                                                    #
# Descr.: Liefert den Usernamen zu einer UID zurück. #
#                                                    #
######################################################

sub categories_intern_get_user {

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

#####################################################################
#                                                                   #
# Name:   categories_delete( $mgr , $catid , $cat_art , $cat_name ) #
#                                                                   #
# Descr.: Löscht eine Kategorie.                                    #
#                                                                   #
# Bugs:                                                             #
#                                                                   #
#####################################################################

sub categories_delete {

  my $self     = shift;
  my $mgr      = shift;
  my $catid    = shift;
  my $cat_art  = shift;
  my $cat_name = shift;

  my $dbh = $mgr->connect;
  unless ($dbh->do("LOCK TABLES $mgr->{CatTable} WRITE")) {
    warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",$mgr->{CatTable}, $dbh->ersstr);
  };

  my $sth = $dbh->prepare(qq{DELETE FROM $mgr->{CatTable} WHERE id = $catid});

  unless ($sth->execute()) {
    warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{CatTable}, $dbh->errstr);
    $mgr->fatal_error($C_MSG->{db_error});
  };

  $sth->finish;
  $dbh->do("UNLOCK TABLES");

  if (($cat_art eq 'all') || ($cat_art eq 'inactiv') || ($cat_art eq 'activ')) {
    $self->categories_show($mgr,$cat_art,$cat_name);
  } elsif ($cat_art eq 'one') {
    $self->categories_user_type_AB($mgr);
  };

  return 1;
};

####################################################
#                                                  #
# Name:   categories_checkproject( $mgr , $catid ) #
#                                                  #
# Descr.: Prüft ob eine Rubrik Projekte enthält.   #
#                                                  #
####################################################

sub categories_checkproject {

  my $self  = shift;
  my $mgr   = shift;
  my $catid = shift;

  my $dbh = $mgr->connect;
  unless ($dbh->do("LOCK TABLES $mgr->{ProTable} READ")) {
    warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",$mgr->{ProTable}, $dbh->ersstr);
  };

  my $sth = $dbh->prepare(qq{SELECT name FROM $mgr->{ProTable} WHERE cat_id = $catid});

  unless ($sth->execute()) {
    warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{ProTable}, $dbh->errstr);
    $mgr->fatal_error($C_MSG->{db_error});
  };

  my @projects;
  while (my ($name) = $sth->fetchrow_array()) {
    push (@projects, [$name]);
  };

  $sth->finish;
  $dbh->do("UNLOCK TABLES");

  if (@projects) {
    return 1;
  } else {
    return 0;
  };
};

1;
