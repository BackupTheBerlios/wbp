package project;

use Class::Date qw(date);
use Class::Singleton;
use base 'Class::Singleton';
use project_base;
use project_config;
use vars qw($VERSION $C_MSG $C_TMPL);
use strict;

$VERSION = sprintf "%d.%03d", q$Revision: 1.16 $ =~ /(\d+)\.(\d+)/;

# Hashes des Configteils sichtbar machen in dieser Klasse.
$C_MSG  = $project_config::MSG;
$C_TMPL = $project_config::TMPL;

#====================================================================================================#
# SYNOPSIS: parameter($mgr);
# PURPOSE:  Managt dieses Modul in bezug auf die Aufrufe durch POST und GET.
# RETURN:   1;
#====================================================================================================#
sub parameter {
	my $self = shift;
	my $mgr  = shift;

	# Typ D User sind hier nicht erlaubt.
	if ($mgr->{UserType} eq "D") {
		$mgr->fatal_error($C_MSG->{NotAllowed});
	}

	# Global for this package here.
	$self->{MGR} = $mgr;

	my $cgi    = $mgr->{CGI};
	my $method = $cgi->param('method') || undef;

	# Objekt der Projekt Basis Klasse anlegen.	
	eval { 
		$self->{BASE} = project_base->new({MGR    => $mgr,
						   C_MSG  => $C_MSG,
						   C_TMPL => $C_TMPL}); 
	};
	if ($@) {
		warn "Can't create class [project_base].";
		warn "[Error]: $@";
		$mgr->fatal_error($C_MSG->{NormalError});
	}	

	# Abarbeitung der Getaufrufe.
	if (defined $method) {
		# Projekt anzeigen lassen.
		if ($method eq "show_project") {
			$self->show_one_project();
			return 1;
		# Phasen zu einem Projekt anzeigen.
		} elsif ($method eq "show_phase") {
			$self->show_phase();
			return 1;
		# Eine Phase anzeigen.
		} elsif ($method eq "show_one_phase") {
			$self->show_one_phase();
			return 1;
		# Den Status von einem Proejtk aendern.
		} elsif ($method eq "change_status") {
			$self->change_status();
			return 1;
		# Den Status zu einer Phase aendern.
		} elsif ($method eq "change_pha_status") {
			$self->change_pha_status();
			return 1;
		# Den Modus eines Projekts aendern.
		} elsif ($method eq "change_mode") {
			$self->change_mode();
			return 1;
		# Die Seite ausgeben lassen, wo man die Typ A/B User hinzufeugen kann.
		} elsif ($method eq "change_user_ab") {
			$self->show_change_user_ab();
			return 1;
		# Die Seite ausgeben lassen, wo man die Typ C User hinzufeugen kann. 
		} elsif ($method eq "change_user_c") {
			$self->show_change_user_c();
			return 1;
		# Die Seite ausgeben lassen, wo man die Typ C/D User hinzufeugen kann.
		} elsif ($method eq "change_user_d") {
			$self->show_change_user_cd();
			return 1;
		# Einen Typ A/B User aus dem Projekt nehmen.
		} elsif ($method eq "del_user_ab") {
			$self->del_user_ab();
			return 1;
		# Einen Typ C User aus einem Proejkt nehmen.
		} elsif ($method eq "del_user_c") {
			$self->del_user_c();
			return 1;
		# Einen Typ C/D User aus einem Projekt nehmen.
		} elsif ($method eq "del_user_cd") {
			$self->del_user_cd();
			return 1;
		# Zurueck aus dem Aendern modus.
		} elsif ($method eq "back_change") {
			$self->tmp_show_projects();
			return 1;
		# Eine Phase aus einem Proejtk loeschen.
		} elsif ($method eq "del_phase") {
			$self->del_phase();
			return 1;
		}
	# Verarbeiten der POST Aufrufe. 
	} else {
		# Ein neues Projekt anlegen.
		if (defined $cgi->param('new')) {
			$self->menue_new();
			return 1;
		# Nach Projekten suchen.
		} elsif (defined $cgi->param('search')) {
			$self->show_projects();
			return 1;
		# Ein neues Proejtk anlegen (in DB speichern).
		} elsif (defined $cgi->param('add_project')) {
			$self->add_project();
			return 1;
		# Menue fuer eine neue Phase ausgeben.
		} elsif (defined $cgi->param('add_phase_menu')) {
			$self->add_phase_menu();
			return 1;
		# Die neue Phase in der DB speichern.
		} elsif (defined $cgi->param('add_phase')) {
			$self->add_phase();
			return 1;
		# Ein Projekt aendern.
		} elsif (defined $cgi->param('change_project')) {
			$self->change_project();
			return 1;
		# Eine Phase aendern.
		} elsif (defined $cgi->param('change_phase')) {
			$self->change_phase();
			return 1;
		# Einen User Typ A/B hinzufuegen.
		} elsif (defined $cgi->param('add_user_ab')) {
			$self->add_user_ab();
			return 1;
		# Einen User Typ C hinzufuegen.
		} elsif (defined $cgi->param('add_user_c')) {
			$self->add_user_c();
			return 1;
		# Einen User Typ C/D hinzufuegen.
		} elsif (defined $cgi->param('add_user_cd')) {
			$self->add_user_cd();
			return 1;
		}
	}

	# Sonst das Projektmenue ausgeben. 
	$self->menue();
}

#====================================================================================================#
# SYNOPSIS: $self->menu(|$msg); 
# PURPOSE:  Hauptseite des Projektsmoduls ausgeben und gegebenen falls auch noch ein uebergebenen 
#	    Nachricht mit ausgeben.
# RETURN:   true. 
#====================================================================================================#
sub menue {
        my $self = shift;
        my $msg  = shift || undef;
        my $mgr  = $self->{MGR};
 
        $mgr->{TmplData}{PROJECTS} = 1 if ($self->{BASE}->check_for_projects != 0);

	# Das richtige Modul fuer den jeweilgen User zusammen bauen. 
        if ($mgr->{UserType} ne "C") {
		$mgr->{Template} = $C_TMPL->{ProjectAB};

		# Nach vorhandenen Kategorien suchen und gegebenenfalls ins Template schreiben.	
		my @kategorien = $self->{BASE}->check_for_categories;

		if (@kategorien) {
			my @tmp;

			for (my $i = 0; $i <= $#kategorien; $i++) {
				$tmp[$i]{KID}   = $kategorien[$i][0];
				$tmp[$i]{KNAME} = $mgr->decode_all($kategorien[$i][1]);
			}

			$mgr->{TmplData}{KATEGORIEN} = \@tmp;
		}
        } else {
        	$mgr->{Template} = $C_TMPL->{ProjectC};

		# Daten fuer den C User auf der Haupseite setzen.
		my $check = $self->{BASE}->get_and_set_for_c();
		
		if ($check) {
			$mgr->{TmplData}{IF_PROJECTS} = 1;
		} else {
			$mgr->{TmplData}{NO_PROJECTS} = $mgr->decode_all($C_MSG->{NoProjects});
		}
	}        

	$mgr->{TmplData}{FORM} = $mgr->my_url;
        $mgr->fill($msg);

	return 1;
}

#====================================================================================================#
# SYNOPSIS: $self->menue_new(|$mgr);
# PURPOSE:  Die Seite zum anlegen eines neuen Projekts ausgeben und wenn noetig mit alten Daten 
#	    fuellen, falls Fehler bei der Eingabe gemacht wurden.
# RETURN:   true.
#====================================================================================================#    
sub menue_new {
        my $self = shift;
        my $msg  = shift || undef;
        my $mgr  = $self->{MGR};
        my $cgi  = $self->{MGR}->{CGI};

	$mgr->{TmplData}{KID}   = $cgi->param('kid');

	# Den Namen der Kategorie zu der Id mit auslesen.
	$mgr->{TmplData}{KNAME} = $mgr->decode_all($self->{BASE}->get_cat_name($cgi->param('kid')));

	# Wenn eine Nachricht uebergeben wurde, dann auch die alten Daten mit ausgeben. 
        if ($msg) {
                $mgr->{TmplData}{NAME}         = $mgr->decode_some($cgi->param('name'));
                $mgr->{TmplData}{START_TAG}    = $mgr->decode_some($cgi->param('start_tag'));
                $mgr->{TmplData}{START_MONAT}  = $mgr->decode_some($cgi->param('start_monat'));
                $mgr->{TmplData}{START_JAHR}   = $mgr->decode_some($cgi->param('start_jahr'));
                $mgr->{TmplData}{ENDE_TAG}     = $mgr->decode_some($cgi->param('ende_tag'));
                $mgr->{TmplData}{ENDE_MONAT}   = $mgr->decode_some($cgi->param('ende_monat'));
                $mgr->{TmplData}{ENDE_JAHR}    = $mgr->decode_some($cgi->param('ende_jahr'));
                $mgr->{TmplData}{BESCHREIBUNG} = $mgr->decode_some($cgi->param('beschreibung'));
                $mgr->fill($msg);
        } else {
                $mgr->fill;
        }
 
        $mgr->{Template}       = $C_TMPL->{ProjectNew};
        $mgr->{TmplData}{FORM} = $mgr->my_url;
}                            

#====================================================================================================#
# SYNOPSIS: $self->add_projekt();
# PURPOSE:  Daten des Projekts ueberpruefen und bei Richtigkeit in die Datenbank schreiben.
# RETURN:   true.
#====================================================================================================#   
sub add_project {
        my $self = shift;
        my $mgr  = $self->{MGR};
        my $cgi  = $self->{MGR}->{CGI};

	# Schreibt der richtige User hier ein Projekt rein?
	$self->{BASE}->check_user();

        my $kid          = $cgi->param('kid');
	my $kname        = $cgi->param('kname');
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

	# Daten wie den Namen, das Datum etc. auf Richtigkeit pruefen. 
        if (length($name) > 255) {
                $mgr->{TmplData}{ERROR_NAME} = $mgr->decode_all($C_MSG->{LengthName});
                $check++;
        } elsif ($name eq "") {
		$mgr->{TmplData}{ERROR_NAME} = $mgr->decode_all($C_MSG->{EmptyName});
		$check++;
	}

        if (($start_tag eq "") || ($start_monat eq "") || ($start_jahr eq "")) {
                $mgr->{TmplData}{ERROR_START_DATUM} = $mgr->decode_all($C_MSG->{ErrorDate});
                $check++;
        }
 
        if (($ende_tag eq "") || ($ende_monat eq "") || ($ende_jahr eq "")) {
                $mgr->{TmplData}{ERROR_ENDE_DATUM} = $mgr->decode_all($C_MSG->{ErrorDate});
                $check++;
        }

	my $check_start_dt = $start_jahr.$start_monat.$start_tag;
	my $check_end_dt   = $ende_jahr.$ende_monat.$ende_tag;
	my $date_check;

	if ($check_start_dt =~ m/\D/) {
		$mgr->{TmplData}{ERROR_START_DATUM} = $mgr->decode_all($C_MSG->{ErrorDate});
                $check++;
		$date_check++;
	} else {
		$start_dt = date [$start_jahr, $start_monat, $start_tag, 00, 00, 00];
	}

	if ($check_end_dt =~ m/\D/) {
		$mgr->{TmplData}{ERROR_ENDE_DATUM} = $mgr->decode_all($C_MSG->{ErrorDate});
                $check++;
		$date_check++;
	} else {
		$end_dt = date [$ende_jahr, $ende_monat, $ende_tag, 00, 00, 00];
	}

	unless ($date_check) {
		if ($start_dt >= $end_dt) {
			$mgr->{TmplData}{ERROR_START_DATUM} = $mgr->decode_all($C_MSG->{StartEndDate});
			$mgr->{TmplData}{ERROR_ENDE_DATUM}  = $mgr->decode_all($C_MSG->{StartEndDate});
			$check++;
		}
	}

	# Pruefen, ob der Projektname schon existiert.	
	if ($self->{BASE}->check_project_name($name, $kid)) {
		$mgr->{TmplData}{ERROR_NAME} = $mgr->decode_all($C_MSG->{ExistName});
		$check++;
	}

	# Wenn Fehler aufgetreten sind noch mal die Eingaben korrigieren lassen.
        if ($check) {
                $self->menue_new($C_MSG->{ErrorAddPro});
        } else {

		# Daten in die Datenbank speichern.
		my $dbh = $mgr->connect;
		unless ($dbh->do("LOCK TABLES $mgr->{ProTable} WRITE")) {
                	warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
                        	$mgr->{ProTable}, $dbh->errstr);
        	}
		my $sth = $dbh->prepare(qq{INSERT INTO $mgr->{ProTable} (name, desc_project, cat_id ,start_dt, end_dt, 
					   ins_dt, ins_id) VALUES (?, ?, ?, ?, ?, ?, ?)});

		unless ($sth->execute($name, $beschreibung, $kid, $start_dt, $end_dt, $mgr->now, $mgr->{UserId})) {
			warn sprintf("[Error]: Trouble inserting project into [%s]. Reason [%s].",
				$mgr->{ProTable}, $dbh->errstr);
			$dbh->do("UNLOCK TABLES");
			$mgr->fatal_error($C_MSG->{DbError});
		}

		$dbh->do("UNLOCK TABLES");
		$sth->finish;
		$self->menue($C_MSG->{InsertProOk});
	}
}

#====================================================================================================#
# SYNOPSIS: $self->change_projekt();
# PURPOSE:  Gibt die Seite zum aendern eines Projekts aus.
# RETURN:   true.
#====================================================================================================#   
sub change_project {
	my $self = shift;
	my $msg  = $self->{BASE}->change_project() || undef;

	if ($msg) {
		$self->show_projects(1, $msg);
	}
}

#====================================================================================================#
# SYNOPSIS: $self->show_projekts(|$check, $msg);
# PURPOSE:  Zeigt die Projekte in der Datenbank an und gibt diese formatiert aus.
# RETURN:   true.
#====================================================================================================#   
sub show_projects {
	my $self  = shift;
	my $check = shift || undef;
	my $msg   = shift || "";
        my $mgr   = $self->{MGR};
        my $cgi   = $self->{MGR}->{CGI};

	# Wieder den User ueberpruefen.
	$self->{BASE}->check_user(); 

	my ($name, $cat);
	# Den Suchparameter in die Session speichern oder davon lesen.
	if ($check) {
		$name = $mgr->{Session}->get("SearchProjectName") || "";
		$cat  = $mgr->{Session}->get("SearchCatId");
	} else {
		$name = $cgi->param('project_name') || "";
		$cat  = $cgi->param('project_category');

		$mgr->{Session}->del("SearchProjectName");
		$mgr->{Session}->del("SearchCatId");       

		$mgr->{Session}->set(SearchProjectName => $name);
	        $mgr->{Session}->set(SearchCatId       => $cat);

	}

	my $mode = 0; 
	$mode = 1 if ($name);

	# Daten der Projekte setzen etc.
	my $count = $self->{BASE}->get_and_set_projects($mode, $cat, $name);

	# ... und die Navigationsleiste fuellen.
	if ($msg) {
		$mgr->fill($msg);
	} else {
		$mgr->fill(sprintf($C_MSG->{CountProjects}, $count));
	}

	return 1;	
}

#====================================================================================================#
# SYNOPSIS: $self->show_phase(|$pid, $msg);
# PURPOSE:  Die Phasen zu einem Projekt anzeigen lassen.
# RETURN:   true.
#====================================================================================================#   
sub show_phase {
	my $self = shift;
	my $mgr  = $self->{MGR};
        my $cgi  = $mgr->{CGI};
        my $pid  = shift || $cgi->param('pid');
	my $msg  = shift || undef;

	# Die sollte eingeltlich immer da sein. 
        unless ($pid) {
                warn "[Error]: Wrong script parameters.";
                $mgr->fatal_error($C_MSG->{NotAllowed});
        }

	$mgr->{Template}       = $C_TMPL->{ProPhaStart};
	$mgr->{TmplData}{FORM} = $mgr->my_url;
	$mgr->{TmplData}{PID}  = $pid;

	# Die Basisfunktion aufrufen und die Arbeit verrichten.
	$self->{BASE}->show_phase($pid);

	# Wenn es ein A/B User war, kamm er woanders her ud braucht einen back link.	
	if ($mgr->{UserType} eq "A" || $mgr->{UserType} eq "B") {
                $mgr->{TmplData}{BACK_CHANGE_LINK} = "$mgr->{ScriptName}?action=$mgr->{Action}&sid=$mgr->{Sid}&method=back_change";
        }

	if ($msg) {
		$mgr->fill($msg);
	} else {
		$mgr->fill();
	}
}

#====================================================================================================#
# SYNOPSIS: $self->add_phase_menu(|$msg);
# PURPOSE:  Gibt das Menue zum anlegen einer Phase zu einem bestimmten Projekt aus.
# RETURN:   true.
#====================================================================================================#   
sub add_phase_menu {
	my $self = shift;
        my $msg  = shift || undef;
        my $mgr  = $self->{MGR};
        my $cgi  = $self->{MGR}->{CGI};
	my $pid  = $cgi->param('pid');

	$mgr->{TmplData}{PID} = $pid;

	# Gab es eine Nachricht, wurden bei der Eingabe Fehler gemacht. 
        if ($msg) {
                $mgr->{TmplData}{NAME}         = $mgr->decode_some($cgi->param('name'));
                $mgr->{TmplData}{START_TAG}    = $mgr->decode_some($cgi->param('start_tag'));
                $mgr->{TmplData}{START_MONAT}  = $mgr->decode_some($cgi->param('start_monat'));
                $mgr->{TmplData}{START_JAHR}   = $mgr->decode_some($cgi->param('start_jahr'));
                $mgr->{TmplData}{ENDE_TAG}     = $mgr->decode_some($cgi->param('ende_tag'));
                $mgr->{TmplData}{ENDE_MONAT}   = $mgr->decode_some($cgi->param('ende_monat'));
                $mgr->{TmplData}{ENDE_JAHR}    = $mgr->decode_some($cgi->param('ende_jahr'));
                $mgr->{TmplData}{BESCHREIBUNG} = $mgr->decode_some($cgi->param('beschreibung'));
                $mgr->fill($msg);
        } else {
                $mgr->fill;
        }
 
        $mgr->{Template}            = $C_TMPL->{ProPhaNew};
        $mgr->{TmplData}{FORM}      = $mgr->my_url;
	$mgr->{TmplData}{BACK_LINK} = "$mgr->{ScriptName}?action=$mgr->{Action}&sid=$mgr->{Sid}&method=show_phase&pid=".$pid;
}

#====================================================================================================#
# SYNOPSIS: $self->add_phase();
# PURPOSE:  Anlegen einer Phase zu einem bestimmten Projekt, nach dem die Daten geprueft wurden.
# RETURN:   true.
#====================================================================================================#   
sub add_phase {
	my $self  = shift;
	my $pid   = $self->{MGR}->{CGI}->param('pid');
	my $check = $self->{BASE}->add_phase();

	# Pruefen, ob das anlegen ok war.
	if ($check eq "-1") {
		$self->add_phase_menu($C_MSG->{ErrorAddPha});
		return;
	}

	# ... sonst die Phasendaten korriegieren und nochmal probieren.
	$self->show_phase($pid, $C_MSG->{InsertPhaOk});
}

#====================================================================================================#
# SYNOPSIS: tmp_show_projects();
# PURPOSE:  Hilfsfunktion.
# RETURN:   true.
#====================================================================================================#   
sub tmp_show_projects {
	my $self = shift;
	
	$self->show_projects(1);
}

#====================================================================================================#
# SYNOPSIS: $self->shwo_one_project();
# PURPOSE:  Gibt die Daten zu einem Projekt aus.
# RETURN:   true.
#====================================================================================================#   
sub show_one_project {
	my $self = shift;
	my $mgr  = $self->{MGR};
        my $cgi  = $mgr->{CGI};
	my $pid  = $cgi->param('pid');

	unless ($pid) {
		warn "[Error]: Wrong script parameters.";
		$mgr->fatal_error($C_MSG->{NotAllowed});
	}

	$mgr->{Template} = $C_TMPL->{ProjectChange};	

	$self->{BASE}->show_one_project($pid);

	if ($mgr->{UserType} eq "A" || $mgr->{UserType} eq "B") {
		$mgr->{TmplData}{IF_USER_AB}       = 1;
		$mgr->{TmplData}{BACK_CHANGE_LINK} = "$mgr->{ScriptName}?action=$mgr->{Action}&sid=$mgr->{Sid}&method=back_change";
	}	

	$mgr->fill;
}

#====================================================================================================#
# SYNOPSIS: $self->change_status();
# PURPOSE:  Aendert den Status von einem Projekt.
# RETURN:   true.
#====================================================================================================#   
sub change_status {
	my $self = shift;
        my $cgi  = $self->{MGR}->{CGI};
	my $mode = $cgi->param('to');
	my $pid  = $cgi->param('pid');

	$self->{BASE}->change_status($mode, $pid);

	$self->show_projects(1, $C_MSG->{ChangeStatus});	
}

#====================================================================================================#
# SYNOPSIS: $self->change_mode();
# PURPOSE:  Aendern den Modus eines Projekts.
# RETURN:   true.
#====================================================================================================#   
sub change_mode {
	my $self = shift;
        my $cgi = $self->{MGR}->{CGI};

	my $mode = $cgi->param('to');
	my $pid  = $cgi->param('pid');
 
	$self->{BASE}->change_mode($mode, $pid);

	$self->show_projects(1, $C_MSG->{ChangeMode});	
}

#====================================================================================================#
# SYNOPSIS: $self->change_pha_status(); 
# PURPOSE:  Aendern den Status von einer Phase.
# RETURN:   true.
#====================================================================================================#   
sub change_pha_status {
	my $self   = shift;
	my $pha_id = $self->{MGR}->{CGI}->param('pha_id');
	my $to     = $self->{MGR}->{CGI}->param('to');
	my $pid    = $self->{MGR}->{CGI}->param('pid');

	unless ($pha_id) {
                warn "[Error]: Wrong script parameters.";
                $self->{MGR}->fatal_error($C_MSG->{NotAllowed});
        } 	

	$self->{BASE}->change_pha_status($pha_id, $to);

	$self->show_phase($pid, $C_MSG->{ChangeStatus});
}

#====================================================================================================#
# SYNOPSIS: $self->del_phase();
# PURPOSE:  Loescht eine Phase aus einem Projekt.
# RETURN:   true.
#====================================================================================================#   
sub del_phase {
	my $self   = shift;
	my $mgr    = $self->{MGR};
	my $pid    = $mgr->{CGI}->param('pid')    || "";
	my $pha_id = $mgr->{CGI}->param('pha_id') || "";

	unless ($pid && $pha_id) {
		warn "[Error]: Wrong script parameters.";
                $mgr->fatal_error($C_MSG->{NotAllowed});	
	}

	$self->{BASE}->del_phase($pha_id);

	$self->show_phase($pid, $C_MSG->{DelPhaOk});
}

#====================================================================================================#
# SYNOPSIS: $self->show_one_phase();
# PURPOSE:  Zeigt eine Phase an.
# RETURN:   true.
#====================================================================================================#   
sub show_one_phase {
	my $self   = shift;
        my $mgr    = $self->{MGR};
        my $pid    = $mgr->{CGI}->param('pid')    || "";
	my $pha_id = $mgr->{CGI}->param('pha_id') || "";
 
        unless ($pid && $pha_id) {
                warn "[Error]: Wrong script parameters.";
                $mgr->fatal_error($C_MSG->{NotAllowed});
        }
 
        $mgr->{Template} = $C_TMPL->{ProPhaChange};
 
        $self->{BASE}->show_one_phase($pid, $pha_id);
 
        $mgr->fill;             
}

#====================================================================================================#
# SYNOPSIS: $self->change_phase();
# PURPOSE:  Aendert eine Phase in der Datenbank.
# RETURN:   true.
#====================================================================================================#   
sub change_phase {
	my $self = shift;
	my $mgr  = $self->{MGR};
	my $pid  = $self->{MGR}->{CGI}->param('pid') || "";

	my $check = $self->{BASE}->change_phase() || "";
	if ($check eq "-1") {
		return;
	}
	
	$self->show_phase($pid, $C_MSG->{UpdatePhaOk});
}

#====================================================================================================#
# SYNOPSIS: $self->show_change_user_ab();
# PURPOSE:  Zeigt das Menue zum aendern der User des Typs A/B an.
# RETURN:   true.
#====================================================================================================#   
sub show_change_user_ab {
	my $self = shift;
	my $mgr  = $self->{MGR};
	my $pid  = $mgr->{CGI}->param('pid') || "";

	unless ($pid) {
		warn "[Error]: Wrong script parameters.";
                $mgr->fatal_error($C_MSG->{NotAllowed});
	}

	$self->{BASE}->show_change_user_ab($pid);
}

#====================================================================================================#
# SYNOPSIS: $self->show_change_user_c();
# PURPOSE:  Zeigt das Menue zum aendern der User des Typs C an.
# RETURN:   true.
#====================================================================================================#   
sub show_change_user_c {
	my $self = shift;
	my $mgr  = $self->{MGR};
	my $pid  = $mgr->{CGI}->param('pid') || "";
 
        unless ($pid) {
                warn "[Error]: Wrong script parameters.";
                $mgr->fatal_error($C_MSG->{NotAllowed});
        }

	$self->{BASE}->show_change_user_c($pid);
}

#====================================================================================================#
# SYNOPSIS: $self->show_change_user_cd();
# PURPOSE:  Zeigt das Menue zum aendern der User des Typs C/D an.
# RETURN:   true.
#====================================================================================================#   
sub show_change_user_cd {
	my $self = shift;
	my $mgr  = $self->{MGR};
	my $pid  = $mgr->{CGI}->param('pid') || "";
 
        unless ($pid) {
                warn "[Error]: Wrong script parameters.";
                $mgr->fatal_error($C_MSG->{NotAllowed});
        }

	$self->{BASE}->show_change_user_cd($pid);	
}

#====================================================================================================#
# SYNOPSIS: $self->add_user_ab();
# PURPOSE:  Fuegt einen User vom Typ AB in ein Projekt ein.
# RETURN:   true.
#====================================================================================================#   
sub add_user_ab {
	my $self = shift;
	my $mgr  = $self->{MGR};
        my $pid  = $mgr->{CGI}->param('pid') || "";

	unless ($pid) {
                warn "[Error]: Wrong script parameters.";
                $mgr->fatal_error($C_MSG->{NotAllowed});
        }
	
	$self->{BASE}->add_user_ab($pid); 
}

#====================================================================================================#
# SYNOPSIS: $self->add_user_c();
# PURPOSE:  Fuegt einen User vom Typ C in ein Projekt ein.
# RETURN:   true.
#====================================================================================================#   
sub add_user_c {
        my $self = shift;
        my $mgr  = $self->{MGR};
        my $pid  = $mgr->{CGI}->param('pid') || "";
 
        unless ($pid) {
                warn "[Error]: Wrong script parameters.";
                $mgr->fatal_error($C_MSG->{NotAllowed});
        }
 
        $self->{BASE}->add_user_c($pid);
} 

#====================================================================================================#
# SYNOPSIS: $self->add_user_cd();
# PURPOSE:  Fuegt einen User vom Typ C/D in ein Projekt ein.
# RETURN:   true.
#====================================================================================================#   
sub add_user_cd {
        my $self = shift;
        my $mgr  = $self->{MGR};
        my $pid  = $mgr->{CGI}->param('pid') || "";
 
        unless ($pid) {
                warn "[Error]: Wrong script parameters.";
                $mgr->fatal_error($C_MSG->{NotAllowed});
        }
 
        $self->{BASE}->add_user_cd($pid);
} 

#====================================================================================================#
# SYNOPSIS: $self->del_user_ab();
# PURPOSE:  Loescht einen User des Typs A/B aus einem Projekt.
# RETURN:   true.
#====================================================================================================#   
sub del_user_ab {
	my $self = shift;
        my $mgr  = $self->{MGR};
	my $pid  = $mgr->{CGI}->param('pid') || "";
	my $uid  = $mgr->{CGI}->param('uid') || "";
	
	unless ($pid && $uid) {
                warn "[Error]: Wrong script parameters.";
                $mgr->fatal_error($C_MSG->{NotAllowed});
        }

	$self->{BASE}->del_user_ab($pid, $uid);
}

#====================================================================================================#
# SYNOPSIS: $self->del_user_c();
# PURPOSE:  Loescht einen User des Typs C aus einem Projekt.
# RETURN:   true.
#====================================================================================================#   
sub del_user_c {
	my $self = shift;
        my $mgr  = $self->{MGR};
	my $pid  = $mgr->{CGI}->param('pid') || "";
        my $uid  = $mgr->{CGI}->param('uid') || "";
 
        unless ($pid && $uid) {
                warn "[Error]: Wrong script parameters.";
                $mgr->fatal_error($C_MSG->{NotAllowed});
        }
 
        $self->{BASE}->del_user_c($pid, $uid);
}

#====================================================================================================#
# SYNOPSIS: $self->del_user_cd();
# PURPOSE:  Loescht einen User des Typs C/D aus einem Projekt.
# RETURN:   true.
#====================================================================================================#   
sub del_user_cd {
	my $self = shift;
        my $mgr  = $self->{MGR};
	my $pid  = $mgr->{CGI}->param('pid') || "";
        my $uid  = $mgr->{CGI}->param('uid') || "";
 
        unless ($pid && $uid) {
                warn "[Error]: Wrong script parameters.";
                $mgr->fatal_error($C_MSG->{NotAllowed});
        }
 
        $self->{BASE}->del_user_cd($pid, $uid);
}

1;
