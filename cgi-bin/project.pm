package project;

use Class::Date qw(date);
use Class::Singleton;
use base 'Class::Singleton';
use project_base;
use project_config;
use vars qw($VERSION $C_MSG $C_TMPL);
use strict;

$VERSION = sprintf "%d.%03d", q$Revision: 1.15 $ =~ /(\d+)\.(\d+)/;

$C_MSG  = $project_config::MSG;
$C_TMPL = $project_config::TMPL;

sub parameter {
	my $self = shift;
	my $mgr  = shift;

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

	if (defined $method) {
		if ($method eq "show_project") {
			$self->show_one_project();
			return 1;
		} elsif ($method eq "show_phase") {
			$self->show_phase();
			return 1;
		} elsif ($method eq "show_one_phase") {
			$self->show_one_phase();
			return 1;
		} elsif ($method eq "change_status") {
			$self->change_status();
			return 1;
		} elsif ($method eq "change_pha_status") {
			$self->change_pha_status();
			return 1;
		} elsif ($method eq "change_mode") {
			$self->change_mode();
			return 1;
		} elsif ($method eq "change_user_ab") {
			$self->show_change_user_ab();
			return 1;
		} elsif ($method eq "change_user_c") {
			$self->show_change_user_c();
			return 1;
		} elsif ($method eq "change_user_d") {
			$self->show_change_user_cd();
			return 1;
		} elsif ($method eq "del_user_ab") {
			$self->del_user_ab();
			return 1;
		} elsif ($method eq "del_user_c") {
			$self->del_user_c();
			return 1;
		} elsif ($method eq "del_user_cd") {
			$self->del_user_cd();
			return 1;
		} elsif ($method eq "back_change") {
			$self->tmp_show_projects();
			return 1;
		} elsif ($method eq "del_phase") {
			$self->del_phase();
			return 1;
		} 
	} else {
		if (defined $cgi->param('new')) {
			$self->menue_new();
			return 1;
		} elsif (defined $cgi->param('search')) {
			$self->show_projects();
			return 1;
		} elsif (defined $cgi->param('add_project')) {
			$self->add_project();
			return 1;
		} elsif (defined $cgi->param('add_phase_menu')) {
			$self->add_phase_menu();
			return 1;
		} elsif (defined $cgi->param('add_phase')) {
			$self->add_phase();
			return 1;
		} elsif (defined $cgi->param('change_project')) {
			$self->change_project();
			return 1;
		} elsif (defined $cgi->param('change_phase')) {
			$self->change_phase();
			return 1;
		} elsif (defined $cgi->param('add_user_ab')) {
			$self->add_user_ab();
			return 1;
		} elsif (defined $cgi->param('add_user_c')) {
			$self->add_user_c();
			return 1;
		} elsif (defined $cgi->param('add_user_cd')) {
			$self->add_user_cd();
			return 1;
		}
	}

	$self->menue();
}

sub menue {
        my $self = shift;
        my $msg  = shift || undef;
        my $mgr  = $self->{MGR};
 
        $mgr->{TmplData}{PROJECTS} = 1 if ($self->{BASE}->check_for_projects != 0);
 
        if ($mgr->{UserType} ne "C") {
		$mgr->{Template} = $C_TMPL->{ProjectAB};
	
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

		my $check = $self->{BASE}->get_and_set_for_c();
		
		if ($check) {
			$mgr->{TmplData}{IF_PROJECTS} = 1;
		} else {
			$mgr->{TmplData}{NO_PROJECTS} = $mgr->decode_all($C_MSG->{NoProjects});
		}
	}        

	$mgr->{TmplData}{FORM} = $mgr->my_url;
 
        $mgr->fill($msg);

	return;
}
 
sub menue_new {
        my $self = shift;
        my $msg  = shift || undef;
        my $mgr  = $self->{MGR};
        my $cgi  = $self->{MGR}->{CGI};

	$mgr->{TmplData}{KID}   = $cgi->param('kid');

	$mgr->{TmplData}{KNAME} = $mgr->decode_all($self->{BASE}->get_cat_name($cgi->param('kid')));
 
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

sub add_project {
        my $self = shift;
        my $mgr  = $self->{MGR};
        my $cgi  = $self->{MGR}->{CGI};

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
	
	if ($self->{BASE}->check_project_name($name, $kid)) {
		$mgr->{TmplData}{ERROR_NAME} = $mgr->decode_all($C_MSG->{ExistName});
		$check++;
	}

        if ($check) {
                $self->menue_new($C_MSG->{ErrorAddPro});
        } else {

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

sub change_project {
	my $self = shift;
	my $msg  = $self->{BASE}->change_project() || undef;

	if ($msg) {
		$self->show_projects(1, $msg);
	}
}

sub show_projects {
	my $self  = shift;
	my $check = shift || undef;
	my $msg   = shift || "";
        my $mgr   = $self->{MGR};
        my $cgi   = $self->{MGR}->{CGI};

	$self->{BASE}->check_user(); 

	my ($name, $cat);

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

	my $count = $self->{BASE}->get_and_set_projects($mode, $cat, $name);

	if ($msg) {
		$mgr->fill($msg);
	} else {
		$mgr->fill(sprintf($C_MSG->{CountProjects}, $count));
	}

	return 1;	
}

sub show_phase {
	my $self = shift;
	my $mgr  = $self->{MGR};
        my $cgi  = $mgr->{CGI};
        my $pid  = shift || $cgi->param('pid');
	my $msg  = shift || undef;
 
        unless ($pid) {
                warn "[Error]: Wrong script parameters.";
                $mgr->fatal_error($C_MSG->{NotAllowed});
        }

	$mgr->{Template}       = $C_TMPL->{ProPhaStart};
	$mgr->{TmplData}{FORM} = $mgr->my_url;
	$mgr->{TmplData}{PID}  = $pid;

	$self->{BASE}->show_phase($pid);
	
	if ($mgr->{UserType} eq "A" || $mgr->{UserType} eq "B") {
                $mgr->{TmplData}{BACK_CHANGE_LINK} = "$mgr->{ScriptName}?action=$mgr->{Action}&sid=$mgr->{Sid}&method=back_change";
        }

	if ($msg) {
		$mgr->fill($msg);
	} else {
		$mgr->fill();
	}
}

sub add_phase_menu {
	my $self = shift;
        my $msg  = shift || undef;
        my $mgr  = $self->{MGR};
        my $cgi  = $self->{MGR}->{CGI};
	my $pid  = $cgi->param('pid');

	$mgr->{TmplData}{PID} = $pid;
 
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

sub add_phase {
	my $self  = shift;
	my $pid   = $self->{MGR}->{CGI}->param('pid');
	my $check = $self->{BASE}->add_phase();

	if ($check eq "-1") {
		$self->add_phase_menu($C_MSG->{ErrorAddPha});
		return;
	}

	$self->show_phase($pid, $C_MSG->{InsertPhaOk});
}

sub tmp_show_projects {
	my $self = shift;
	
	$self->show_projects(1);
}

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

sub change_status {
	my $self = shift;
        my $cgi  = $self->{MGR}->{CGI};
	my $mode = $cgi->param('to');
	my $pid  = $cgi->param('pid');

	$self->{BASE}->change_status($mode, $pid);

	$self->show_projects(1, $C_MSG->{ChangeStatus});	
}

sub change_mode {
	my $self = shift;
        my $cgi = $self->{MGR}->{CGI};

	my $mode = $cgi->param('to');
	my $pid  = $cgi->param('pid');
 
	$self->{BASE}->change_mode($mode, $pid);

	$self->show_projects(1, $C_MSG->{ChangeMode});	
}

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
