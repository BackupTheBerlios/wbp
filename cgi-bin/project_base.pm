package project_base;

use vars qw($VERSION);
use strict;
use Class::Date qw(date);

#
# Der Konstruktior der Klasse.
#
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

#
# Pruefen ob ein Typ C oder Typ D User Projekte an legen will etc.
#
sub check_user {

	my $self = shift;

	my $mgr = $self->{MGR};

	if (($mgr->{UserType} ne "A") && ($mgr->{UserType} ne "B")) {
                $mgr->fatal_error($self->{C_MSG}->{NotAllowed});
        }

	return; 
}

#
# Pruefen, ob es Projekte gibt.
#
sub check_for_projects {
 
        my $self = shift;
 
        my $mgr = $self->{MGR};
	my $count;
 
        my $dbh = $mgr->connect;
	unless ($dbh->do("LOCK TABLES $mgr->{ProTable} READ")) {
		warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
			$mgr->{ProTable}, $dbh->errstr);
		$mgr->fatal_error($self->{C_MSG}->{DbError});
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

#
# Pruefen ob es Kategorien gibt.
# 
sub check_for_categories {
 
        my $self = shift;
 
        my $mgr = $self->{MGR};
	my @kategorien;
 
        my $dbh = $mgr->connect;
	unless ($dbh->do("LOCK TABLES $mgr->{CatTable} READ")) {
                warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
                        $mgr->{CatTable}, $dbh->errstr);
		$mgr->fatal_error($self->{C_MSG}->{DbError});
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

#
# Auslesen des Namens einer Kategorie.
#
sub get_cat_name {

	my $self = shift;
	my $kid  = shift;
	
	my $mgr = $self->{MGR};

	my $dbh = $mgr->connect;
	unless ($dbh->do("LOCK TABLES $mgr->{CatTable} READ")) {
                warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
                        $mgr->{CatTable}, $dbh->errstr);
		$mgr->fatal_error($self->{C_MSG}->{DbError});
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

#
# Ueberpruefen, ob ein Projektname schon vorhanden ist.
#
sub check_project_name {

	my $self = shift;
	my $name = shift;
	my $kid  = shift;
	my $pid  = shift;

	my $mgr = $self->{MGR};
	
	my ($error, $check);

	my $dbh = $mgr->connect;
	unless ($dbh->do("LOCK TABLES $mgr->{ProTable} READ")) {
                warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
                        $mgr->{ProTable}, $dbh->errstr);
		$mgr->fatal_error($self->{C_MSG}->{DbError});
        }
	my $sth;
	unless ($pid) {
		$sth = $dbh->prepare(qq{SELECT id FROM $mgr->{ProTable} WHERE name = ? AND cat_id = ?});
		unless ($sth->execute($name, $kid)) {
                	$error++;
        	}
	} else {
		$sth = $dbh->prepare(qq{SELECT id FROM $mgr->{ProTable} WHERE name = ? AND cat_id = ? AND id <> ?});
		unless ($sth->execute($name, $kid, $pid)) {
                	$error++;
        	}
	}

	if ($error) {
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

#
# Hilfsfunktion zum setzen der Projektdaten.
#
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
                        $mgr->{ProTable}, $mgr->{ProUserTable}, $mgr->{PhaTable}, $dbh->errstr);
		$dbh->do("UNLOCK TABLES");
		$mgr->fatal_error($self->{C_MSG}->{DbError});
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

		$tmpldata[$i]{KAT_NAME} = $mgr->decode_all($self->get_cat_name($project[2]));

		$i++;	

	}
	
	$count = $sth->rows;

	$sth->finish;
	$dbh->do("UNLOCK TABLES");

	$mgr->{Template}           = $self->{C_TMPL}->{ProjectShow};
	$mgr->{TmplData}{PROJECTS} = \@tmpldata;

	return $count;
}

#
# Einfuegen der Projektdaten i die Projektliste nach einer Suche.
#
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

#
# Aendern des Status zu einem Projekt.
#
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
                        $mgr->{ProTable}, $dbh->errstr);
		$mgr->fatal_error($self->{C_MSG}->{DbError});
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

#
# Aendern des Modues eines Projekts.
#
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
                        $mgr->{ProTable}, $dbh->errstr);
		$mgr->fatal_error($self->{C_MSG}->{DbError});
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

#
# Ausgeben der Projektliste fuer einen Typ C User.
#
sub get_and_set_for_c {

	my $self = shift;
	my $mgr  = $self->{MGR};
	my $dbh  = $mgr->connect;

	unless ($dbh->do("LOCK TABLES $mgr->{ProTable} READ, $mgr->{ProUserTable} READ, ".
			 "$mgr->{CatTable} READ, $mgr->{PhaTable} READ")) {
		warn sprintf("[Error]: Trouble locking table [%s] and [%s]. Reason: [%s].",
			$mgr->{ProTable}, $mgr->{ProUserTable}, $dbh->errstr);
		$dbh->do("UNLOCK TABLES");
		$mgr->fatal_error($self->{C_MSG}->{DbError});
	}

	# Als ersten suchen wir alle Projekte, wo unser Typ C User Projektleiter ist, also Position = 1 hat.
	my $sth = $dbh->prepare(qq{SELECT project_id FROM $mgr->{ProUserTable} WHERE user_id = ? AND position = '1'});

	unless ($sth->execute($mgr->{UserId})) {
		warn sprintf("[Error]: Trouble selecting data from [%s]. Reason: [%s].",
			$mgr->{ProUserTable}, $dbh->errstr);
		$dbh->do("UNLOCK TABLES");	
		$mgr->fatal_error($self->{C_MSG}->{DbError});
	}

	my (@tmpldata, @data, $check);

	# Alle Projektids in ein Array pushen.
        while (my ($data) = $sth->fetchrow_array()) {
        	push (@data, $data);
        }
        $sth->finish;

	# Wenn wir hier eien Wert groesser 0 erhalten, ist unserer User mindestens in einem Projekt 
	# Projektleiter.
	if ($sth->rows != 0) {
		$sth = $dbh->prepare(qq{SELECT id, name, cat_id, start_dt, end_dt, status, mode FROM $mgr->{ProTable} WHERE id = ?});

		my $i = 0;

		# Alle Projekte selecten, wo der User Projektleiter ist und das Templatehash fuellen.
		foreach (@data) {
			unless ($sth->execute($_)) {
                                warn sprintf("[Error]: Trouble selecting data from [%s]. Reason: [%s].",
                                                $mgr->{ProTable}, $dbh->errstr);
                                $dbh->do("UNLOCK TABLES");
                                $mgr->fatal_error($self->{C_MSG}->{DbError});
                        }

			my (@tmpdata) = $sth->fetchrow_array(); 

			# Den richtigen Status einfuegen.
			if ($tmpdata[5] == 1) {
				$tmpldata[$i]{STATUS} = $mgr->decode_all($self->{C_MSG}->{Aktive});
			} elsif ($tmpdata[5] == 0) {
				$tmpldata[$i]{STATUS} = $mgr->decode_all($self->{C_MSG}->{Inaktive});
			} else {
				$tmpldata[$i]{STATUS} = $mgr->decode_all($self->{C_MSG}->{Closed});
			}

			# Analog zum status auch den Modus richtig einfuegen.
			if ($tmpdata[6] == 0) {
				$tmpldata[$i]{MODUS} = $mgr->decode_all($self->{C_MSG}->{Private});
			} elsif ($tmpdata[6] == 1) {
				$tmpldata[$i]{MODUS} = $mgr->decode_all($self->{C_MSG}->{Public});
			}

			# Die restlichen Daten des Projekts setzen.
			$tmpldata[$i]{START_DT}       = $mgr->format_date($tmpdata[3]);
			$tmpldata[$i]{ENDE_DT}        = $mgr->format_date($tmpdata[4]);
			$tmpldata[$i]{CHANGE_PROJECT} = "$mgr->{ScriptName}?action=$mgr->{Action}&sid=$mgr->{Sid}&pid=".
							$_."&method=show_project";
			$tmpldata[$i]{NAME}           = $mgr->decode_all($tmpdata[1]);
			$tmpldata[$i]{KAT_NAME}       = $mgr->decode_all($self->get_cat_name($tmpdata[2]));

			$i++;
		}
		$sth->finish;

		$sth = $dbh->prepare(qq{SELECT COUNT(*) FROM $mgr->{ProUserTable} WHERE project_id = ? AND position = ?});

		$i = 0;

		# Hier werden noch die fehlenden und passenden Mengen von User in einem Projekt mit angeben.
		foreach (@data) {
			unless ($sth->execute($_, "0")) {
                		$check++;
        		}
        		$tmpldata[$i]{USER_AB} = $sth->fetchrow_array;

        		unless ($sth->execute($_, "1")) {
                		$check++;
        		}
        		$tmpldata[$i]{USER_C} = $sth->fetchrow_array;

        		unless ($sth->execute($_, "2")) {
                		$check++;
        		}
        		$tmpldata[$i]{USER_D}        = $sth->fetchrow_array;
			$tmpldata[$i]{CHANGE_USER_D} = "$mgr->{ScriptName}?action=$mgr->{Action}&sid=$mgr->{Sid}&pid=".
                                                        $_."&method=change_user_d";

			if ($check) {
                		warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
                        		$mgr->{ProUserTable}, $dbh->errstr);
                			$dbh->do("UNLOCK TABLES");
                		$mgr->fatal_error($self->{C_MSG}->{DbError});
        		}

			$i++;

			$check = 0;
		}
		$sth->finish;

		$i = 0;

		# Und fuer die Phasen nochmal.
		$sth = $dbh->prepare(qq{SELECT id FROM $mgr->{PhaTable} WHERE project_id = ?});

		foreach (@data) {
        		unless ($sth->execute($_)) {
                		warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
                        		$mgr->{PhaTable}, $dbh->errstr);
                		$dbh->do("UNLOCK TABLES");
                		$mgr->fatal_error($self->{C_MSG}->{DbError});
        		}

        		$tmpldata[$i]{PHASES}        = $sth->rows;
        		$tmpldata[$i]{CHANGE_PHASES} = "$mgr->{ScriptName}?action=$mgr->{Action}&sid=$mgr->{Sid}&pid=".
                                                        $_."&method=show_phase"; 
        
			$i++;
		}
		$sth->finish;

		$mgr->{TmplData}{PROJECTS} = \@tmpldata; 
		
		$dbh->do("UNLOCK TABLES");
		return 1;

	} else {
		$dbh->do("UNLOCK TABLES");
		return 0;
	}	
}

#
# Anzeigen der Projektdaten in einer Form zum aendern.
#
sub show_one_project {

	my $self = shift;
	my $pid  = shift;

	my $mgr = $self->{MGR};
	my $dbh = $mgr->connect;

	unless ($dbh->do("LOCK TABLES $mgr->{ProTable} READ, $mgr->{CatTable} READ")) {
		warn srpintf("[Error]: Trouble locking table [%s] and [%s]. Reason: [%s].",
                        $mgr->{ProTable}, $dbh->{CatTable}, $dbh->errstr);
		$dbh->do("UNLOCK TABLES");
                $mgr->fatal_error($self->{C_MSG}->{DbError});
	}

	my $sth = $dbh->prepare(qq{SELECT id, start_dt, end_dt, name, desc_project, cat_id FROM $mgr->{ProTable} WHERE id = ?});
	unless ($sth->execute($pid)) {
		warn sprintf("[Error]: Trouble selecting data from [%s]. Reason: [%s]",
			$mgr->{ProTable}, $dbh->errstr);
		$dbh->do("UNLOCK TABLES");
		$mgr->fatal_error($self->{C_MSG}->{DbError}); 
	}

	my @project_data = $sth->fetchrow_array();

	$mgr->{TmplData}{PID}          = $mgr->decode_some($project_data[0]);
	$mgr->{TmplData}{NAME}         = $mgr->decode_some($project_data[3]);
	$mgr->{TmplData}{START_TAG}    = substr($project_data[1], 8, 2);
	$mgr->{TmplData}{START_MONAT}  = substr($project_data[1], 5, 2);
	$mgr->{TmplData}{START_JAHR}   = substr($project_data[1], 0, 4);
	$mgr->{TmplData}{ENDE_TAG}     = substr($project_data[2], 8, 2);
	$mgr->{TmplData}{ENDE_MONAT}   = substr($project_data[2], 5, 2);
	$mgr->{TmplData}{ENDE_JAHR}    = substr($project_data[2], 0, 4);
	$mgr->{TmplData}{BESCHREIBUNG} = $mgr->decode_some($project_data[4]);

	$sth->finish;

	$sth = $dbh->prepare(qq{SELECT id, name FROM $mgr->{CatTable}});
        unless ($sth->execute()) {
                warn sprintf("[Error]: Trouble selecting data from [%s]. Reason: [%s]",
                        $mgr->{CatTable}, $dbh->errstr);
                $dbh->do("UNLOCK TABLES");
                $mgr->fatal_error($self->{C_MSG}->{DbError});
        }
 
	my @kat_tmpl;
	my $i = 0;

        while (my ($kid, $kname) = $sth->fetchrow_array()) {
		$kat_tmpl[$i]{KID}   = $kid;
		$kat_tmpl[$i]{KNAME} = $mgr->decode_all($kname);

		if ($kid == $project_data[5]) {
			$kat_tmpl[$i]{KSELECT} = 1;
		}

		$i++;
	}
	$sth->finish;
	$dbh->do("UNLOCK TABLES");

	$mgr->{TmplData}{FORM} = $mgr->my_url();
	$mgr->{TmplData}{KATS} = \@kat_tmpl;
}

#
# Aendern eines Projekts in der Datenbank.
#
sub change_project {
	
	my $self = shift;
	my $mgr = $self->{MGR};
	my $cgi = $mgr->{CGI};

	my $pid          = $cgi->param('pid');
	my $kid          = $cgi->param('kategorie');
        my $name         = $cgi->param('name')         || "";
        my $start_tag    = $cgi->param('start_tag')    || "";
        my $start_monat  = $cgi->param('start_monat')  || "";
        my $start_jahr   = $cgi->param('start_jahr')   || "";
        my $ende_tag     = $cgi->param('ende_tag')     || "";
        my $ende_monat   = $cgi->param('ende_monat')   || "";
        my $ende_jahr    = $cgi->param('ende_jahr')    || "";
        my $beschreibung = $cgi->param('beschreibung') || "";

	my $check = 0;
        my ($start_dt, $end_dt);
 
        if (length($name) > 255) {
                $mgr->{TmplData}{ERROR_NAME} = $mgr->decode_all($self->{C_MSG}->{LengthName});
                $check++;
        } elsif ($name eq "") {
                $mgr->{TmplData}{ERROR_NAME} = $mgr->decode_all($self->{C_MSG}->{EmptyName});
                $check++;
        }
 
        if (($start_tag eq "") || ($start_monat eq "") || ($start_jahr eq "")) {
                $mgr->{TmplData}{ERROR_START_DATUM} = $mgr->decode_all($self->{C_MSG}->{ErrorDate});
                $check++;
        }
 
        if (($ende_tag eq "") || ($ende_monat eq "") || ($ende_jahr eq "")) {
                $mgr->{TmplData}{ERROR_ENDE_DATUM} = $mgr->decode_all($self->{C_MSG}->{ErrorDate});
                $check++;
        }
 
        my $check_start_dt = $start_jahr.$start_monat.$start_tag;
        my $check_end_dt   = $ende_jahr.$ende_monat.$ende_tag;
        my $date_check;

	if ($check_start_dt =~ m/\D/) {
                $mgr->{TmplData}{ERROR_START_DATUM} = $mgr->decode_all($self->{C_MSG}->{ErrorDate});
                $check++;
                $date_check++;
        } else {
                $start_dt = date [$start_jahr, $start_monat, $start_tag, 00, 00, 00];
        }
 
        if ($check_end_dt =~ m/\D/) {
                $mgr->{TmplData}{ERROR_ENDE_DATUM} = $mgr->decode_all($self->{C_MSG}->{ErrorDate});
                $check++;
                $date_check++;
        } else {
                $end_dt = date [$ende_jahr, $ende_monat, $ende_tag, 00, 00, 00];
        }
 
        unless ($date_check) {
                if ($start_dt >= $end_dt) {
                        $mgr->{TmplData}{ERROR_START_DATUM} = $mgr->decode_all($self->{C_MSG}->{StartEndDate});
                        $mgr->{TmplData}{ERROR_ENDE_DATUM}  = $mgr->decode_all($self->{C_MSG}->{StartEndDate});
                        $check++;
                }
        }
 
        if ($self->check_project_name($name, $kid, $pid)) {
                $mgr->{TmplData}{ERROR_NAME} = $mgr->decode_all($self->{C_MSG}->{ExistName});
                $check++;
        }
 
        if ($check) {
                $self->set_change_data($self->{C_MSG}->{ErrorChangePro});
		return;
        } else {
 
                my $dbh = $mgr->connect;
                unless ($dbh->do("LOCK TABLES $mgr->{ProTable} WRITE")) {
                        warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
                                $mgr->{ProTable}, $dbh->errstr);
                }
                my $sth = $dbh->prepare(qq{UPDATE $mgr->{ProTable} SET name = ?, desc_project = ?, 
							cat_id = ?, start_dt = ?, end_dt = ?,
                                           		upd_dt = ?, upd_id = ? WHERE id = ?});
 
                unless ($sth->execute($name, $beschreibung, $kid, $start_dt, $end_dt, $mgr->now, $mgr->{UserId}, $pid)) {
                        warn sprintf("[Error]: Trouble updating project into [%s]. Reason [%s].",
                                $mgr->{ProTable}, $dbh->errstr);
                        $dbh->do("UNLOCK TABLES");
                        $mgr->fatal_error($self->{C_MSG}->{DbError});
                }
 
                $dbh->do("UNLOCK TABLES");
                $sth->finish;
                return ($self->{C_MSG}->{UpdateProOk});
        }

}

#
# Wenn ein Fehler beim aendern der Projektdaten aufgetreten ist, wird diese Funktion aufgerufen.
#
sub set_change_data {

	my $self = shift;
	my $msg  = shift;

	my $mgr = $self->{MGR};
	my $cgi = $mgr->{CGI};

	$mgr->{Template} = $self->{C_TMPL}->{ProjectChange};

	my $dbh = $mgr->connect;
	unless ($dbh->do("LOCK TABLES $mgr->{CatTable} READ")) {
                warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
                        $dbh->{CatTable}, $dbh->errstr);
                $mgr->fatal_error($self->{C_MSG}->{DbError});
        }

	my $sth = $dbh->prepare(qq{SELECT id, name FROM $mgr->{CatTable}});
        unless ($sth->execute()) {
                warn sprintf("[Error]: Trouble selecting data from [%s]. Reason: [%s]",
                        $mgr->{CatTable}, $dbh->errstr);
                $dbh->do("UNLOCK TABLES");
                $mgr->fatal_error($self->{C_MSG}->{DbError});
        }
 
        my @kat_tmpl;
        my $i       = 0;
	my $old_kid = $cgi->param('kategorie');
 
        while (my ($kid, $kname) = $sth->fetchrow_array()) {
                $kat_tmpl[$i]{KID}   = $kid;
                $kat_tmpl[$i]{KNAME} = $mgr->decode_all($kname);
 
                if ($kid == $old_kid) {
                        $kat_tmpl[$i]{KSELECT} = 1;
                }
 
                $i++;
        }
        $sth->finish;
        $dbh->do("UNLOCK TABLES");
 
        $mgr->{TmplData}{KATS}         = \@kat_tmpl; 
	$mgr->{TmplData}{FORM}         = $mgr->my_url();
	$mgr->{TmplData}{PID}          = $cgi->param('pid');
        $mgr->{TmplData}{NAME}         = $mgr->decode_some($cgi->param('name'));
        $mgr->{TmplData}{START_TAG}    = $mgr->decode_some($cgi->param('start_tag'));
        $mgr->{TmplData}{START_MONAT}  = $mgr->decode_some($cgi->param('start_monat'));
        $mgr->{TmplData}{START_JAHR}   = $mgr->decode_some($cgi->param('start_jahr'));
        $mgr->{TmplData}{ENDE_TAG}     = $mgr->decode_some($cgi->param('ende_tag'));
        $mgr->{TmplData}{ENDE_MONAT}   = $mgr->decode_some($cgi->param('ende_monat'));
        $mgr->{TmplData}{ENDE_JAHR}    = $mgr->decode_some($cgi->param('ende_jahr'));
        $mgr->{TmplData}{BESCHREIBUNG} = $mgr->decode_some($cgi->param('beschreibung'));
	$mgr->fill($msg);

}

#
# Anzeigen der Phasen zu einem Projekt.
#
sub show_phase {

	my ($self, $pid) = @_;
	
	my $mgr = $self->{MGR};
	my $dbh = $mgr->connect();
	unless ($dbh->do("LOCK TABLES $mgr->{PhaTable} READ")) {
        	warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
                	$mgr->{PhaTable}, $dbh->errstr);
		$mgr->fatal_error($self->{C_MSG}->{DbError});
        }
        my $sth = $dbh->prepare(qq{SELECT id, name, desc_phase, start_dt, end_dt, status FROM $mgr->{PhaTable} WHERE project_id = ?});
 
        unless ($sth->execute($pid)) {
        	warn sprintf("[Error]: Trouble selecting data from [%s]. Reason [%s].",
                		$mgr->{PhaTable}, $dbh->errstr);
                $dbh->do("UNLOCK TABLES");
                $mgr->fatal_error($self->{C_MSG}->{DbError});
        }
	
	my (@tmpl_data, $to);
	my $i = 0;

	while (my (@data) = $sth->fetchrow_array()) {
		$tmpl_data[$i]{START_DT}     = $mgr->format_date($data[3]);
		$tmpl_data[$i]{ENDE_DT}      = $mgr->format_date($data[4]);
		$tmpl_data[$i]{NAME}         = $mgr->decode_all($data[1]);
		$tmpl_data[$i]{BESCHREIBUNG} = $mgr->decode_all($data[2]);

		if ($data[5] eq "0") {
			$tmpl_data[$i]{STATUS} = $self->{C_MSG}->{Aktive};
			$to = 1;
		} else {
			$tmpl_data[$i]{STATUS} = $self->{C_MSG}->{Closed};
			$to = 0;
		}

		$tmpl_data[$i]{STATUS_LINK} = "$mgr->{ScriptName}?action=$mgr->{Action}&sid=$mgr->{Sid}&pid=".$pid.
                                              "&method=change_pha_status&pha_id=".$data[0]."&to=".$to;

		$tmpl_data[$i]{DEL_LINK}    = "$mgr->{ScriptName}?action=$mgr->{Action}&sid=$mgr->{Sid}&pid=".
                                               $pid."&method=del_phase&pha_id=".$data[0];

		$tmpl_data[$i]{CHANGE_LINK} = "$mgr->{ScriptName}?action=$mgr->{Action}&sid=$mgr->{Sid}&pid=".
                                               $pid."&method=show_one_phase&pha_id=".$data[0];
		
		$i++;
	}
 
        $dbh->do("UNLOCK TABLES");
        $sth->finish;

	$mgr->{TmplData}{PHASE} = \@tmpl_data;
	if (defined $tmpl_data[0]) {
		$mgr->{TmplData}{IF_PHASE} = 1;
	}	             
	
}

#
# Anlegen einer Phase zu einem Projekt.
#
sub add_phase {

	my $self = shift;
	my $mgr = $self->{MGR};
        my $cgi = $mgr->{CGI};
 
        my $pid          = $cgi->param('pid');
        my $name         = $cgi->param('name')         || "";
        my $start_tag    = $cgi->param('start_tag')    || "";
        my $start_monat  = $cgi->param('start_monat')  || "";
        my $start_jahr   = $cgi->param('start_jahr')   || "";
        my $ende_tag     = $cgi->param('ende_tag')     || "";
        my $ende_monat   = $cgi->param('ende_monat')   || "";
        my $ende_jahr    = $cgi->param('ende_jahr')    || "";
        my $beschreibung = $cgi->param('beschreibung') || "";
 
        my $check = 0;
        my ($start_dt, $end_dt);
 
        if (length($name) > 255) {
                $mgr->{TmplData}{ERROR_NAME} = $mgr->decode_all($self->{C_MSG}->{LengthName});
                $check++;
        } elsif ($name eq "") {
                $mgr->{TmplData}{ERROR_NAME} = $mgr->decode_all($self->{C_MSG}->{EmptyName});
                $check++;
        }
 
        if (($start_tag eq "") || ($start_monat eq "") || ($start_jahr eq "")) {
                $mgr->{TmplData}{ERROR_START_DATUM} = $mgr->decode_all($self->{C_MSG}->{ErrorDate});
                $check++;
        }
 
        if (($ende_tag eq "") || ($ende_monat eq "") || ($ende_jahr eq "")) {
                $mgr->{TmplData}{ERROR_ENDE_DATUM} = $mgr->decode_all($self->{C_MSG}->{ErrorDate});
                $check++;
        }
 
        my $check_start_dt = $start_jahr.$start_monat.$start_tag;
        my $check_end_dt   = $ende_jahr.$ende_monat.$ende_tag;
        my $date_check;
 
        if ($check_start_dt =~ m/\D/) {
                $mgr->{TmplData}{ERROR_START_DATUM} = $mgr->decode_all($self->{C_MSG}->{ErrorDate});
                $check++;
                $date_check++;
        } else {
                $start_dt = date [$start_jahr, $start_monat, $start_tag, 00, 00, 00];
        }
 
        if ($check_end_dt =~ m/\D/) {
                $mgr->{TmplData}{ERROR_ENDE_DATUM} = $mgr->decode_all($self->{C_MSG}->{ErrorDate});
                $check++;
                $date_check++;
        } else {
                $end_dt = date [$ende_jahr, $ende_monat, $ende_tag, 00, 00, 00]; 
	}
 
        unless ($date_check) {
                if ($start_dt >= $end_dt) {
                        $mgr->{TmplData}{ERROR_START_DATUM} = $mgr->decode_all($self->{C_MSG}->{StartEndDate});
                        $mgr->{TmplData}{ERROR_ENDE_DATUM}  = $mgr->decode_all($self->{C_MSG}->{StartEndDate});
                        $check++;
                }
        }
	# Hier noch pruefen, ob das Anfangsdatum nicht vor dem Anfangsdatum des Projektes liegt. Analog mit dem
	# Endedatum, das von der Phase auch nicht hinter dem Endedatum des Projektes liegen darf.
 
        if ($self->check_phasen_name($name, $pid)) {
                $mgr->{TmplData}{ERROR_NAME} = $mgr->decode_all($self->{C_MSG}->{ExistName});
                $check++;
        }
 
        if ($check) {
		$mgr->{Template} = $self->{C_TMPL}->{ProPhaNew}; 
		$self->set_phasen_data($self->{C_MSG}->{ErrorAddPha});
                return -1;
        } else {
 
                my $dbh = $mgr->connect;
                unless ($dbh->do("LOCK TABLES $mgr->{PhaTable} WRITE")) {
                        warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
                                $mgr->{PhaTable}, $dbh->errstr);
                }
                my $sth = $dbh->prepare(qq{INSERT INTO $mgr->{PhaTable} (name, desc_phase, project_id, start_dt, end_dt, 
						ins_dt, ins_id) VALUES (?, ?, ?, ?, ?, ?, ?)});
 
                unless ($sth->execute($name, $beschreibung, $pid, $start_dt, $end_dt, $mgr->now, $mgr->{UserId})) {
                        warn sprintf("[Error]: Trouble inserting data into [%s]. Reason [%s].",
                                $mgr->{PhaTable}, $dbh->errstr);
                        $dbh->do("UNLOCK TABLES");
                        $mgr->fatal_error($self->{C_MSG}->{DbError});
                }
 
                $dbh->do("UNLOCK TABLES");
                $sth->finish;
                return ($self->{C_MSG}->{InsertPhaOk});
        }  	
}

#
# Pruefen, ob der Name einer Phase schon existiert.
#
sub check_phasen_name {
   	
	my $self   = shift;
        my $name   = shift;
        my $pid    = shift;
	my $pha_id = shift;;
  
        my $mgr = $self->{MGR};
 
        my ($error, $check);
 
        my $dbh = $mgr->connect;
        unless ($dbh->do("LOCK TABLES $mgr->{PhaTable} READ")) {
                warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
                        $mgr->{PhaTable}, $dbh->errstr);
                $mgr->fatal_error($self->{C_MSG}->{DbError});
        }
        my $sth;
        unless ($pha_id) {
                $sth = $dbh->prepare(qq{SELECT id FROM $mgr->{PhaTable} WHERE name = ? AND project_id = ?});
                unless ($sth->execute($name, $pid)) {
                        $error++;
                }
        } else {
                $sth = $dbh->prepare(qq{SELECT id FROM $mgr->{PhaTable} WHERE name = ? AND project_id = ? AND id <> ?});
                unless ($sth->execute($name, $pid, $pha_id)) {
                        $error++;
                }
        }
 
        if ($error) {
                warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
                        $mgr->{PhaTable}, $dbh->errstr);
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

#
# Den Status einer Phase aendern.
#
sub change_pha_status {
	
	my ($self, $pha_id, $to) = @_;
	my $mgr                  = $self->{MGR};
	my $dbh                  = $mgr->connect();

	unless ($dbh->do("LOCK TABLES $mgr->{PhaTable} WRITE")) {
                warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
                        $mgr->{PhaTable}, $dbh->errstr);
                $mgr->fatal_error($self->{C_MSG}->{DbError});
        }

	my $sth = $dbh->prepare(qq{UPDATE $mgr->{PhaTable} SET status = ? WHERE id = ?}); 
	unless ($sth->execute($to, $pha_id)) {
		warn sprintf("[Error]: Trouble updating [%s]. Reason: [%s].",
                        $mgr->{PhaTable}, $dbh->errstr);
                        $dbh->do("UNLOCK TABLES");
                $mgr->fatal_error($self->{C_MSG}->{DbError});
	}

	$sth->finish;
	$dbh->do("UNLOCK TABLES");
}

#
# Eine Phase loeschen, aus einem Projekt.
#
sub del_phase {

	my ($self, $pha_id) = @_;
	my $mgr             = $self->{MGR};
        my $dbh             = $mgr->connect();

	unless ($dbh->do("LOCK TABLES $mgr->{PhaTable} WRITE")) {
                warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
                        $mgr->{PhaTable}, $dbh->errstr);
                $mgr->fatal_error($self->{C_MSG}->{DbError});
        }
 
        my $sth = $dbh->prepare(qq{DELETE FROM $mgr->{PhaTable} WHERE id = ?});
        unless ($sth->execute($pha_id)) {
                warn sprintf("[Error]: Trouble updating [%s]. Reason: [%s].",
                        $mgr->{PhaTable}, $dbh->errstr);
                        $dbh->do("UNLOCK TABLES");
                $mgr->fatal_error($self->{C_MSG}->{DbError});
        }
 
        $sth->finish;
        $dbh->do("UNLOCK TABLES");
}

#
# Anzeigen von Daten einer Phase, um sie zu aendern.
#
sub show_one_phase {
 
        my ($self, $pid, $pha_id) = @_; 
 
        my $mgr = $self->{MGR};
        my $dbh = $mgr->connect();
 
        unless ($dbh->do("LOCK TABLES $mgr->{PhaTable} READ")) {
                warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
                        $mgr->{ProTable}, $dbh->errstr);
                $mgr->fatal_error($self->{C_MSG}->{DbError});
        }
 
        my $sth = $dbh->prepare(qq{SELECT start_dt, end_dt, name, desc_phase FROM $mgr->{PhaTable} WHERE id = ?});
        unless ($sth->execute($pha_id)) {
                warn sprintf("[Error]: Trouble selecting data from [%s]. Reason: [%s]",
                        $mgr->{PhaTable}, $dbh->errstr);
                $dbh->do("UNLOCK TABLES");
                $mgr->fatal_error($self->{C_MSG}->{DbError});
        }
 
        my @data = $sth->fetchrow_array();

	$mgr->{TmplData}{PID}          = $pid; 
        $mgr->{TmplData}{PHA_ID}       = $pha_id;
        $mgr->{TmplData}{NAME}         = $mgr->decode_some($data[2]);
        $mgr->{TmplData}{START_TAG}    = substr($data[0], 8, 2);
        $mgr->{TmplData}{START_MONAT}  = substr($data[0], 5, 2);
        $mgr->{TmplData}{START_JAHR}   = substr($data[0], 0, 4);
        $mgr->{TmplData}{ENDE_TAG}     = substr($data[1], 8, 2);
        $mgr->{TmplData}{ENDE_MONAT}   = substr($data[1], 5, 2);
        $mgr->{TmplData}{ENDE_JAHR}    = substr($data[1], 0, 4);
        $mgr->{TmplData}{BESCHREIBUNG} = $mgr->decode_some($data[3]);
 
        $sth->finish;
        $dbh->do("UNLOCK TABLES");
 
        $mgr->{TmplData}{FORM}      = $mgr->my_url();
	$mgr->{TmplData}{BACK_LINK} = "$mgr->{ScriptName}?action=$mgr->{Action}&sid=$mgr->{Sid}&pid=".$pid.
                                      "&method=show_phase"; 
}

#
# Aenderungen zu einem Projekt in die Datenbank speichern.
#
sub change_phase {

	my $self = shift;
	my $mgr  = $self->{MGR};
        my $cgi  = $mgr->{CGI};
 
        my $pid          = $cgi->param('pid');
        my $pha_id       = $cgi->param('pha_id');
        my $name         = $cgi->param('name')         || "";
        my $start_tag    = $cgi->param('start_tag')    || "";
        my $start_monat  = $cgi->param('start_monat')  || "";
        my $start_jahr   = $cgi->param('start_jahr')   || "";
        my $ende_tag     = $cgi->param('ende_tag')     || "";
        my $ende_monat   = $cgi->param('ende_monat')   || "";
        my $ende_jahr    = $cgi->param('ende_jahr')    || "";
        my $beschreibung = $cgi->param('beschreibung') || "";
 
        my $check = 0;
        my ($start_dt, $end_dt);
 
        if (length($name) > 255) {
                $mgr->{TmplData}{ERROR_NAME} = $mgr->decode_all($self->{C_MSG}->{LengthName});
                $check++;
        } elsif ($name eq "") {
                $mgr->{TmplData}{ERROR_NAME} = $mgr->decode_all($self->{C_MSG}->{EmptyName});
                $check++;
        }
 
        if (($start_tag eq "") || ($start_monat eq "") || ($start_jahr eq "")) {
                $mgr->{TmplData}{ERROR_START_DATUM} = $mgr->decode_all($self->{C_MSG}->{ErrorDate});
                $check++;
        }
 
        if (($ende_tag eq "") || ($ende_monat eq "") || ($ende_jahr eq "")) {
                $mgr->{TmplData}{ERROR_ENDE_DATUM} = $mgr->decode_all($self->{C_MSG}->{ErrorDate});
                $check++;
        }
 
        my $check_start_dt = $start_jahr.$start_monat.$start_tag;
        my $check_end_dt   = $ende_jahr.$ende_monat.$ende_tag;
        my $date_check;
 
        if ($check_start_dt =~ m/\D/) {
                $mgr->{TmplData}{ERROR_START_DATUM} = $mgr->decode_all($self->{C_MSG}->{ErrorDate});
                $check++;
                $date_check++;
        } else {
                $start_dt = date [$start_jahr, $start_monat, $start_tag, 00, 00, 00];
        }
 
        if ($check_end_dt =~ m/\D/) {
                $mgr->{TmplData}{ERROR_ENDE_DATUM} = $mgr->decode_all($self->{C_MSG}->{ErrorDate});
                $check++;
                $date_check++;
        } else {             
		$end_dt = date [$ende_jahr, $ende_monat, $ende_tag, 00, 00, 00];
        }
 
        unless ($date_check) {
                if ($start_dt >= $end_dt) {
                        $mgr->{TmplData}{ERROR_START_DATUM} = $mgr->decode_all($self->{C_MSG}->{StartEndDate});
                        $mgr->{TmplData}{ERROR_ENDE_DATUM}  = $mgr->decode_all($self->{C_MSG}->{StartEndDate});
                        $check++;
                }
        }
 
        if ($self->check_phasen_name($name, $pid, $pha_id)) {
                $mgr->{TmplData}{ERROR_NAME} = $mgr->decode_all($self->{C_MSG}->{ExistName});
                $check++;
        }

        if ($check) {
		$mgr->{Template}         = $self->{C_TMPL}->{ProPhaChange};
		$mgr->{TmplData}{PHA_ID} = $pha_id; 
                $self->set_phasen_data($self->{C_MSG}->{ErrorChangePro});
                return -1;
        } else {
 
                my $dbh = $mgr->connect;
                unless ($dbh->do("LOCK TABLES $mgr->{PhaTable} WRITE")) {
                        warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
                                $mgr->{PhaTable}, $dbh->errstr);
                }
                my $sth = $dbh->prepare(qq{UPDATE $mgr->{PhaTable} SET name = ?, desc_phase = ?,
                                                        start_dt = ?, end_dt = ?,
                                                        upd_dt = ?, upd_id = ? WHERE id = ?});
 
                unless ($sth->execute($name, $beschreibung, $start_dt, $end_dt, $mgr->now, $mgr->{UserId}, $pha_id)) { 
                        warn sprintf("[Error]: Trouble updating phase in [%s]. Reason [%s].",
                                $mgr->{PhaTable}, $dbh->errstr);
                        $dbh->do("UNLOCK TABLES");
                        $mgr->fatal_error($self->{C_MSG}->{DbError});
                }
 
                $dbh->do("UNLOCK TABLES");
                $sth->finish;
                return ();
        }                                     
}

#
# Wenn beim anlegen oder aendern Fehler auftreten, wird diese Methode aufgerufen und die Daten neu eingetragen.
#
sub set_phasen_data {
	
	my $self = shift;
	my $msg  = shift;
	my $mgr  = $self->{MGR};
	my $cgi  = $mgr->{CGI};

	$mgr->{TmplData}{PID}          = $cgi->param('pid');
	$mgr->{TmplData}{NAME}         = $mgr->decode_some($cgi->param('name'));
	$mgr->{TmplData}{BESCHREIBUNG} = $mgr->decode_some($cgi->param('beschreibung'));
	$mgr->{TmplData}{START_TAG}    = $cgi->param('start_tag');
	$mgr->{TmplData}{START_MONAT}  = $cgi->param('start_monat');
	$mgr->{TmplData}{START_JAHR}   = $cgi->param('start_jahr');
	$mgr->{TmplData}{ENDE_TAG}     = $cgi->param('ende_tag');
	$mgr->{TmplData}{ENDE_MONAT}   = $cgi->param('ende_monat');
	$mgr->{TmplData}{ENDE_JAHR}    = $cgi->param('ende_jahr');
	$mgr->{TmplData}{FORM}         = $mgr->my_url();
        $mgr->{TmplData}{BACK_LINK}    = "$mgr->{ScriptName}?action=$mgr->{Action}&sid=$mgr->{Sid}&pid=".
					 $cgi->param('pid')."&method=show_phase";

	$mgr->fill($msg);
}

1;
