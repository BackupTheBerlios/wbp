package categories;

use Class::Singleton;
use base 'Class::Singleton';
use categories_config;
use vars qw($VERSION $C_MSG $C_TMPL);
use strict;

$VERSION = sprintf "%d.%03d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/;

$C_MSG  = $categories_config::MSG;
$C_TMPL = $categories_config::TMPL;

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
      $self->categories_change_status($mgr, $mgr->{CGI}->param('catid'), $mgr->{CGI}->param('show'));
    } elsif ($method eq "del_cat") {
      $self->categories_delete($mgr,$mgr->{CGI}->param('catid'),$mgr->{CGI}->param('proc'));
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
      $self->categories_change($mgr);
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

sub categories_user_type_AB {

  my $self = shift;
  my $mgr  = shift;

  $mgr->{Template} = $C_TMPL->{CatMain}; # aktuelles Template festlegen

  my $dbh = $mgr->connect;
  my $sth = $dbh->prepare(qq{SELECT id FROM $mgr->{CatTable}});

  unless ($sth->execute()) {
    warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{CatTable}, $dbh->errstr);
    $mgr->fatal_error($C_MSG->{db_error});
  };

  my @cats;
  while (my ($id) = $sth->fetchrow_array()) {
    push (@cats, [$id]);
  }

  if (@cats) {
    $mgr->{TmplData}{SHOW_CAT_IF} = 1;
    $mgr->{TmplData}{SHOW_ALL_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=show_all";
    $mgr->{TmplData}{SHOW_ACTIV_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=show_activ";
    $mgr->{TmplData}{SHOW_INACTIV_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=show_inactiv";
  } else {
    $mgr->{TmplData}{SHOW_CAT_IF} = 0;
  }
  $mgr->{TmplData}{CREATE_CAT_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=create_form";

  $mgr->fill; # Füllt das Template und zeigt es an

  return 1;
};

sub categories_user_type_CD {

  my $self = shift;
  my $mgr  = shift;

  $mgr->{Template} = $C_TMPL->{Error}; # aktuelles Template festlegen
  $mgr->{TmplData}{MSG} = $C_MSG->{user_cd_error};
  $mgr->fill;

  return 1;
};

sub categories_show {

  my $self = shift;
  my $mgr  = shift;
  my $status_param = shift;

  my $dbh = $mgr->connect;
  my $sth;

  if ($status_param eq 'all') {
    $sth = $dbh->prepare(qq{SELECT id, name, status FROM $mgr->{CatTable}});
  } elsif ($status_param eq 'inactiv') {
    $sth = $dbh->prepare(qq{SELECT id, name, status FROM $mgr->{CatTable} WHERE STATUS = '0'});
  } elsif ($status_param eq 'activ') {
    $sth = $dbh->prepare(qq{SELECT id, name, status FROM $mgr->{CatTable} WHERE STATUS = '1'});
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

  $mgr->{Template} = $C_TMPL->{CatsShow}; # aktuelles Template festlegen

  if (@cats) {

    $mgr->{TmplData}{NO_CATS} = '0';

    my $link_show = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=show_cat";
    my $link_edit = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=edit_cat";
    my $link_del = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=del_cat&proc=".$status_param;
    my $link_status = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=change_status"."&show=".$status_param;

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
  } else {
    $mgr->{TmplData}{NO_CATS}='1';
  };

  if ($status_param eq 'all') {
    $mgr->{TmplData}{SHOW_ACTIV_LINK_IF} = '1';
    $mgr->{TmplData}{SHOW_ACTIV_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=show_activ";
    $mgr->{TmplData}{SHOW_INACTIV_LINK_IF} = '1';
    $mgr->{TmplData}{SHOW_INACTIV_LINK}= $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=show_inactiv";
  } elsif ($status_param eq 'inactiv') {
    $mgr->{TmplData}{SHOW_ALL_LINK_IF} = '1';
    $mgr->{TmplData}{SHOW_ALL_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=show_all";
    $mgr->{TmplData}{SHOW_ACTIV_LINK_IF} = '1';
    $mgr->{TmplData}{SHOW_ACTIV_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=show_activ";
  } elsif ($status_param eq 'activ') {
    $mgr->{TmplData}{SHOW_ALL_LINK_IF} = '1';
    $mgr->{TmplData}{SHOW_ALL_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=show_all";
    $mgr->{TmplData}{SHOW_INACTIV_LINK_IF} = '1';
    $mgr->{TmplData}{SHOW_INACTIV_LINK}= $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=show_inactiv";
  };
  if ($status_param eq 'all') {
    $mgr->{TmplData}{CAT_STATUS} = $C_MSG->{exist_all};
  } elsif ($status_param eq 'inactiv') {
    $mgr->{TmplData}{CAT_STATUS} = $C_MSG->{exist_inactiv};
  } elsif ($status_param eq 'activ') {
    $mgr->{TmplData}{CAT_STATUS} = $C_MSG->{exist_activ};
  };

  $mgr->{TmplData}{CREATE_CAT_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=create_form";

  $mgr->fill; # Füllt das Template und zeigt es an

  return 1;
}

sub categories_create_form {

  my $self = shift;
  my $mgr  = shift;

  $mgr->{Template} = $C_TMPL->{CatCreate}; # aktuelles Template festlegen
  $mgr->{TmplData}{CREATE_CHANGE} = '1';
  $mgr->{TmplData}{FORM} = $mgr->my_url;
  $mgr->fill;

  return 1;

};

sub categories_create {

  my $self = shift;
  my $mgr  = shift;

  my $dbh = $mgr->connect;
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
    $mgr->{Template} = $C_TMPL->{CatCreate}; # aktuelles Template festlegen
    $mgr->{TmplData}{FORM} = $mgr->my_url;
    $mgr->{TmplData}{CAT_IF} = '1';
    $mgr->{TmplData}{CAT_NAME} = $cat_name;
    $mgr->{TmplData}{CAT_DESCR} = $mgr->{CGI}->param('descr');
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
#      $dbh->do("UNLOCK TABLES");
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
    $mgr->{TmplData}{INS_DT} = $cats[0][4];
    $mgr->{TmplData}{INS_ID} = $self->categories_intern_get_user($mgr,$cats[0][5]);
    $mgr->{TmplData}{UPD_DT} = $cats[0][6];
    $mgr->{TmplData}{UPD_ID} = $self->categories_intern_get_user($mgr,$cats[0][7]);

    $mgr->{TmplData}{SHOW_ALL_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=show_all";
    $mgr->{TmplData}{SHOW_ACTIV_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=show_activ";
    $mgr->{TmplData}{SHOW_INACTIV_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=show_inactiv";
    $mgr->{TmplData}{CREATE_CAT_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=create_form";
    $mgr->{TmplData}{EDIT_CAT_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=edit_cat&catid=".$cats[0][0];

    if($self->categories_checkproject($mgr,$cats[0][0])) {
      $mgr->{TmplData}{DELETE_LINK_IF} = 0;
    } else {
      $mgr->{TmplData}{DELETE_LINK_IF} = 1;
      my $link_del = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=del_cat&proc=one&catid=".$cats[0][0];
      $mgr->{TmplData}{DELETE_CAT_LINK} = $link_del;
    };

    $mgr->fill;

  };

  return 1;
}

sub categories_change {

  my $self = shift;
  my $mgr  = shift;

  my $dbh = $mgr->connect;
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
    $mgr->fill;
  } else {

    unless ($dbh->do("LOCK TABLES $mgr->{CatTable} WRITE")) {
      warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",$mgr->{CatTable}, $dbh->ersstr);
    };

    $sth = $dbh->prepare(qq{UPDATE $mgr->{CatTable} SET NAME = ?, DESC_CATEGORY = ?, UPD_DT = ?, UPD_ID = ? WHERE ID = ?});

    unless ($sth->execute($cat_name,$mgr->{CGI}->param('descr'),$mgr->now,$mgr->{UserId},$mgr->{CGI}->param('catid'))) {
      warn sprintf("[Error]: Trouble updating status in [%s]. Reason: [%s].",
                    $mgr->{CatTable}, $dbh->errstr);
                    $dbh->do("UNLOCK TABLES");
      $mgr->fatal_error($self->{C_MSG}->{DbError});
    };

    $dbh->do("UNLOCK TABLES");

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
    $mgr->{TmplData}{INS_DT} = $cats[0][4];
    $mgr->{TmplData}{INS_ID} = $self->categories_intern_get_user($mgr,$cats[0][5]);
    $mgr->{TmplData}{UPD_DT} = $cats[0][6];
    $mgr->{TmplData}{UPD_ID} = $self->categories_intern_get_user($mgr,$cats[0][7]);

    $mgr->{TmplData}{SHOW_ALL_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=show_all";
    $mgr->{TmplData}{SHOW_ACTIV_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=show_activ";
    $mgr->{TmplData}{SHOW_INACTIV_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=show_inactiv";
    $mgr->{TmplData}{CREATE_CAT_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=create_form";
    $mgr->{TmplData}{EDIT_CAT_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=edit_cat&catid=".$cats[0][0];

    if($self->categories_checkproject($mgr,$cats[0][0])) {
      $mgr->{TmplData}{DELETE_LINK_IF} = 0;
    } else {
      $mgr->{TmplData}{DELETE_LINK_IF} = 1;
      my $link_del = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=del_cat&proc=one&catid=".$cats[0][0];
      $mgr->{TmplData}{DELETE_CAT_LINK} = $link_del;
    };

    $mgr->fill;

  };

  return 1;
}

sub categories_edit {

  my $self  = shift;
  my $mgr   = shift;
  my $catid = shift;

  my $dbh = $mgr->connect;
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

  $mgr->{Template} = $C_TMPL->{CatCreate}; # aktuelles Template festlegen
  $mgr->{TmplData}{CREATE_CHANGE} = '0';
  $mgr->{TmplData}{FORM} = $mgr->my_url;
  $mgr->{TmplData}{CAT_IF} = '0';
  $mgr->{TmplData}{CAT_NAME} = $cats[0][1];
  $mgr->{TmplData}{CAT_DESCR} = $cats[0][2];
  $mgr->{TmplData}{CATID} = $catid;

  $mgr->fill;

  return 1;
};

sub categories_change_status {

  my $self  = shift;
  my $mgr   = shift;
  my $catid = shift;
  my $show  = shift;

  my $dbh = $mgr->connect;
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

  $self->categories_show($mgr,$show);

  return 1;
};

sub categories_show_one {

  my $self  = shift;
  my $mgr   = shift;
  my $catid = shift;

  my $dbh = $mgr->connect;
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
  $mgr->{TmplData}{INS_DT} = $cats[0][4];
  $mgr->{TmplData}{INS_ID} = $self->categories_intern_get_user($mgr,$cats[0][5]);
  $mgr->{TmplData}{UPD_DT} = $cats[0][6];
  $mgr->{TmplData}{UPD_ID} = $self->categories_intern_get_user($mgr,$cats[0][7]);

  $mgr->{TmplData}{SHOW_ALL_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=show_all";
  $mgr->{TmplData}{SHOW_ACTIV_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=show_activ";
  $mgr->{TmplData}{SHOW_INACTIV_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=show_inactiv";
  $mgr->{TmplData}{CREATE_CAT_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=create_form";
  $mgr->{TmplData}{EDIT_CAT_LINK} = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=edit_cat&catid".$cats[0][0];


  if($self->categories_checkproject($mgr,$cats[0][0])) {
    $mgr->{TmplData}{DELETE_LINK_IF} = 0;
  } else {
    $mgr->{TmplData}{DELETE_LINK_IF} = 1;
    my $link_del = $mgr->{ScriptName}."?action=categories&sid=".$mgr->{Sid}."&method=del_cat&proc=one&catid=".$cats[0][0];
    $mgr->{TmplData}{DELETE_CAT_LINK} = $link_del;
  }

  $mgr->fill;

  return 1;
};


sub categories_intern_get_user {

  my $self  = shift;
  my $mgr   = shift;
  my $uid = shift;

  my $dbh = $mgr->connect;
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

  return $user[0][0];
};

sub categories_delete {

  my $self  = shift;
  my $mgr   = shift;
  my $catid = shift;
  my $proc  = shift;

  my $dbh = $mgr->connect;
  my $sth = $dbh->prepare(qq{DELETE FROM $mgr->{CatTable} WHERE id = $catid});

  unless ($sth->execute()) {
    warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{CatTable}, $dbh->errstr);
    $mgr->fatal_error($C_MSG->{db_error});
  };

  $sth->finish;

  if (($proc eq 'all') || ($proc eq 'inactiv') || ($proc eq 'activ')) {
    $self->categories_show($mgr,$proc);
  } elsif ($proc eq 'one') {
    $self->categories_user_type_AB($mgr);
  };

  return 1;
};

sub categories_checkproject {

  my $self  = shift;
  my $mgr   = shift;
  my $catid = shift;

  my $dbh = $mgr->connect;
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

  if (@projects) {
    return 1;
  } else {
    return 0;
  };
};

1;
