package project_base;

use vars qw($VERSION);
use strict;

sub new {

	my $proto = shift;
	my $args  = shift;

	my $class = ref($proto) || $proto;
	my $self  = {};

	foreach (keys %$args) {
		$self->{$_} = $args->{$_};
	}

	bless ($self, $class);
	
	$self;
}

sub check_user {

	my $self = shift;

	my $mgr = $self->{MGR};

	if (($mgr->{UserType} ne "A") && ($mgr->{UserType} ne "B")) {
                $mgr->fatal_error($self->{C_MSG}->{NotAllowed});
        }

	return; 
}

sub check_for_projects {
 
        my $self = shift;
 
        my $mgr = $self->{MGR};
	my $count;
 
        my $dbh = $mgr->connect;
	unless ($dbh->do("LOCK TABLES $mgr->{ProTable} READ")) {
		warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
			$mgr->{ProTable}, $dbh->ersstr);
	}
        my $sth = $dbh->prepare(qq{SELECT * FROM $mgr->{ProTable}});
 
        unless ($sth->execute()) {
                warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
                        $mgr->{ProTable}, $dbh->errstr);
		$dbh->do("UNLOCK TABLES");
                $mgr->fatal_error($self->{C_MSG}->{DbError});
        }

	$count = $sth->rows;
	$sth->finish;
	$dbh->do("UNLOCK TABLES");
        return $count;
}
 
sub check_for_categories {
 
        my $self = shift;
 
        my $mgr = $self->{MGR};
	my @kategorien;
 
        my $dbh = $mgr->connect;
	unless ($dbh->do("LOCK TABLES $mgr->{CatTable} READ")) {
                warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
                        $mgr->{CatTable}, $dbh->ersstr);
        }
        my $sth = $dbh->prepare(qq{SELECT id, name FROM $mgr->{CatTable}});
 
        unless ($sth->execute()) {
                warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
                        $mgr->{CatTable}, $dbh->errstr);
		$dbh->do("UNLOCK TABLES");
                $mgr->fatal_error($self->{C_MSG}->{DbError});
        }

	while (my ($id, $name) = $sth->fetchrow_array()) {
		push (@kategorien, [$id, $name]);
	}

	$sth->finish;
	$dbh->do("UNLOCK TABLES");
        return @kategorien;
} 

sub get_cat_name {

	my $self = shift;
	my $kid  = shift;
	
	my $mgr = $self->{MGR};

	my $dbh = $mgr->connect;
	unless ($dbh->do("LOCK TABLES $mgr->{CatTable} READ")) {
                warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
                        $mgr->{CatTable}, $dbh->ersstr);
        }
        my $sth = $dbh->prepare(qq{SELECT name FROM $mgr->{CatTable} WHERE id = ?});
 
        unless ($sth->execute($kid)) {
                warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
                        $mgr->{CatTable}, $dbh->errstr);
		$dbh->do("UNLOCK TABLES");
                $mgr->fatal_error($self->{C_MSG}->{DbError});
        }

	my ($kname) = $sth->fetchrow_array();

	$sth->finish;
	$dbh->do("UNLOCK TABLES");
	return $kname;
}

sub check_project_name {

	my $self = shift;
	my $name = shift;
	my $kid  = shift;

	my $mgr = $self->{MGR};
	
	my $check;

	my $dbh = $mgr->connect;
	unless ($dbh->do("LOCK TABLES $mgr->{ProTable} READ")) {
                warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
                        $mgr->{ProTable}, $dbh->ersstr);
        }
	my $sth = $dbh->prepare(qq{SELECT id FROM $mgr->{ProTable} WHERE name = ? AND cat_id = ?});

	unless ($sth->execute($name, $kid)) {
		warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
			$mgr->{ProTable}, $dbh->errstr);
			$dbh->do("UNLOCK TABLES");
		$mgr->fatal_error($self->{C_MSG}->{DbError});
	}

	if ($sth->rows != 0) {
		$check++;
	}

	$sth->finish;
	$dbh->do("UNLOCK TABLES");
	return $check;
}

sub get_and_set_projects {

	my $self = shift;
	my $mode = shift;
	my $cat  = shift;
	my $name = shift || undef;

	my $mgr = $self->{MGR};
	my ($count, @tmpldata);

	my $sql = qq{SELECT id, name, cat_id, start_dt, end_dt, status, mode FROM $mgr->{ProTable} };

	$sql .= qq{WHERE cat_id = '$cat'} if (defined $cat && $cat != 0);

	if ($mode == 1) {
		if ($cat != 0) {
			$sql .= qq{ AND name like '%$name%'};
		} else {
			$sql .= qq{WHERE name like '%$name%'};
		}
	}

	$sql .= qq{ ORDER BY name, id};

	my $dbh = $mgr->connect;
	unless ($dbh->do("LOCK TABLES $mgr->{ProTable} READ, $mgr->{ProUserTable} READ, $mgr->{PhaTable} READ")) {
                warn srpintf("[Error]: Trouble locking tables [%s, %s, %s]. Reason: [%s].",
                        $mgr->{ProTable}, $mgr->{ProUserTable}, $mgr->{PhaTable}, $dbh->ersstr);
        }
	my $sth = $dbh->prepare($sql);

	unless ($sth->execute()) {
		warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
                        $mgr->{ProTable}, $dbh->errstr);
                        $dbh->do("UNLOCK TABLES");
                $mgr->fatal_error($self->{C_MSG}->{DbError});
	}	

	my $i = 0;

	while (my (@project) = $sth->fetchrow_array) {
		my %tmp = $self->set_project_data(@project);
		
		foreach (keys %tmp) {
			$tmpldata[$i]{$_} = $tmp{$_};
		}

		$i++;	

	}
	
	$count = $sth->rows;

	$sth->finish;
	$dbh->do("UNLOCK TABLES");

	$mgr->{Template}           = $self->{C_TMPL}->{ProjectShow};
	$mgr->{TmplData}{PROJECTS} = \@tmpldata;

	return $count;
}

sub set_project_data {

	my $self    = shift;
	my @project = @_;

	my (%tmpldata, $check);

	my $mgr = $self->{MGR};
	
	my $dbh = $mgr->connect;
	my $sth	= $dbh->prepare(qq{SELECT COUNT(*) FROM $mgr->{ProUserTable} WHERE project_id = ? AND position = ?});

	# Fuer jeden Usertypen einen Select auf die UserProjectTabelle machen und so die Anzahl bestimmen
	# an Usern, die von einem bestimmten Typ zu einem Projekt gehoeren. Die Typen A und B werden zusammen 
	# betrachetet.
	unless ($sth->execute($project[0], "0")) {
        	$check++;
	}
	$tmpldata{USER_AB} = $sth->fetchrow_array;

	unless ($sth->execute($project[0], "1")) {
		$check++;
	}
	$tmpldata{USER_C} = $sth->fetchrow_array;

	unless ($sth->execute($project[0], "2")) {
		$check++;
	}
	$tmpldata{USER_D} = $sth->fetchrow_array;

	# Wenn bei einer Abfrage ein Fehler entstanden sein sollte, brechen wir hier mit einer Meldung ab.
	if ($check) {
		warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
                        $mgr->{ProUserTable}, $dbh->errstr);
                        $dbh->do("UNLOCK TABLES");
                $mgr->fatal_error($self->{C_MSG}->{DbError});
	}

	my $link = "$mgr->{ScriptName}?action=$mgr->{Action}&sid=$mgr->{Sid}&pid=".$project[0]."&method=";

	my ($count_ab, $count_c, $count_d) = $sth->fetchrow_array;

	$tmpldata{CHANGE_USER_AB} = $link."change_user_ab"; 
	$tmpldata{CHANGE_USER_C}  = $link."change_user_c";
	$tmpldata{CHANGE_USER_D}  = $link."change_user_d";

	$sth->finish;	
	$sth = $dbh->prepare(qq{SELECT id FROM $mgr->{PhaTable} WHERE project_id = ?});

	unless ($sth->execute($project[0])) {
                warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
                        $mgr->{PhaTable}, $dbh->errstr);
                        $dbh->do("UNLOCK TABLES");
                $mgr->fatal_error($self->{C_MSG}->{DbError});
        }

	$tmpldata{PHASES}        = $sth->rows;
	$tmpldata{CHANGE_PHASES} = $link."show_phase";	
	
	$sth->finish;

	my ($status_link, $modus, $mode_link);

	$status_link = $link."change_status&to=";
	$mode_link   = $link."change_mode&to=";

	if ($project[6] == 0) {
		$modus      = $self->{C_MSG}->{Private};
		$mode_link .= 1;
	} else {
		$modus      = $self->{C_MSG}->{Public};
		$mode_link .= 0;
	}

	$tmpldata{START_DT}       = $mgr->format_date($project[3]);
	$tmpldata{ENDE_DT}        = $mgr->format_date($project[4]);
	$tmpldata{NAME}           = $mgr->decode_all($project[1]);
	$tmpldata{CHANGE_PROJECT} = $link."show_project";
	$tmpldata{MODUS}          = $mgr->decode_all($modus);
	$tmpldata{CHANGE_MODE}    = $mode_link; 	

	$tmpldata{STATUS_AKTIV}   = $mgr->decode_all($self->{C_MSG}->{Aktive});
	$tmpldata{STATUS_INAKTIV} = $mgr->decode_all($self->{C_MSG}->{Inaktive});
	$tmpldata{STATUS_CLOSED}  = $mgr->decode_all($self->{C_MSG}->{Closed});

	if ($project[5] == 0) {
		$tmpldata{STATUS_AKTIV_LINK}   = $status_link."1";
		$tmpldata{STATUS_CLOSED_LINK}  = $status_link."2";
	} elsif ($project[5] == 1) {
		$tmpldata{STATUS_INAKTIV_LINK} = $status_link."0";
		$tmpldata{STATUS_CLOSED_LINK}  = $status_link."2";
	} else {
		$tmpldata{STATUS_AKTIV_LINK}   = $status_link."1";
		$tmpldata{STATUS_INAKTIV_LINK} = $status_link."0";	
	}

	return %tmpldata;	
}

sub change_status {

	my $self   = shift;
	my $status = shift;
	my $pid    = shift;

	my $mgr = $self->{MGR};
	my $new_status;

	my $dbh = $mgr->connect;
	my $sth = $dbh->prepare(qq{UPDATE $mgr->{ProTable} SET status = ?, upd_dt = ?, upd_id = ? WHERE id = ?});
	
	unless ($dbh->do("LOCK TABLES $mgr->{ProTable} WRITE")) {
                warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
                        $mgr->{ProTable}, $dbh->ersstr);
        }
	
	unless ($sth->execute($status, $mgr->now(), $mgr->{UserId}, $pid)) {
                warn sprintf("[Error]: Trouble updating status in [%s]. Reason: [%s].",
                        $mgr->{ProTable}, $dbh->errstr);
                        $dbh->do("UNLOCK TABLES");
                $mgr->fatal_error($self->{C_MSG}->{DbError});
	}

	$sth->finish;
	$dbh->do("UNLOCK TABLES");

	return 1;
}

sub change_mode {

	my $self = shift;
        my $mode = shift;
	my $pid  = shift;
 
        my $mgr = $self->{MGR};
	my $new_mode;
 
        if ($mode == 0) {
                $new_mode = "0";
        } else {
                $new_mode = "1";
        }
 
        my $dbh = $mgr->connect;
 
        unless ($dbh->do("LOCK TABLES $mgr->{ProTable} WRITE")) {
                warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
                        $mgr->{ProTable}, $dbh->ersstr);
        }
 
        my $sth = $dbh->prepare(qq{UPDATE $mgr->{ProTable} SET mode = ?, upd_dt = ?, upd_id = ? WHERE id = ?});
 
        unless ($sth->execute($new_mode, $mgr->now(), $mgr->{UserId}, $pid)) {
                warn sprintf("[Error]: Trouble updating mode in [%s]. Reason: [%s].",
                        $mgr->{ProTable}, $dbh->errstr);
                        $dbh->do("UNLOCK TABLES");
                $mgr->fatal_error($self->{C_MSG}->{DbError});
        }
 
        $sth->finish;
        $dbh->do("UNLOCK TABLES");	

	return 1;
}

1;
