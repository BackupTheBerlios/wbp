package project;

use Class::Singleton;
use base 'Class::Singleton';
use project_base;
use project_config;
use vars qw($VERSION $C_MSG $C_TMPL);
use strict;

$VERSION = sprintf "%d.%03d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/;

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

		} elsif ($method eq "show_phase") {

		} elsif ($method eq "change_user_ab") {

		} elsif ($method eq "change_user_c") {

		} elsif ($method eq "change_user_d") {

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
		} elsif (defined $cgi->param('add_phase')) {
	
		} elsif (defined $cgi->param('change_project')) {

		} elsif (defined $cgi->param('change_phase')) {	

		} elsif (defined $cgi->param('change_user_ab')) {

		} elsif (defined $cgi->param('change_user_c')) {

		} elsif (defined $cgi->param('change_user_d')) {

		}
	}

	$self->menue();
}

sub menue {
 
        my $self = shift;
        my $msg  = shift || undef;
 
        my $mgr = $self->{MGR};
 
        $mgr->{TmplData}{PROJECTS} = 1 if ($self->{BASE}->check_for_projects != 0);
 
        if ($mgr->{UserType} ne "C") {
                $mgr->{TmplData}{USER_AB} = 1;
		$mgr->{TmplData}{TYPE_AB} = 1;
		
		my @kategorien = $self->{BASE}->check_for_categories;

		if (@kategorien) {
			my @tmp;

			for (my $i = 0; $i <= $#kategorien; $i++) {
				$tmp[$i]{KID}   = $kategorien[$i][0];
				$tmp[$i]{KNAME} = $mgr->decode_all($kategorien[$i][1]);
			}

			$mgr->{TmplData}{KATEGORIEN} = \@tmp;
		}
        }
 
        $mgr->{Template}       = $C_TMPL->{Project};
        $mgr->{TmplData}{FORM} = $mgr->my_url;
 
        $mgr->fill($msg);

	return;
}
 
sub menue_new {
 
        my $self = shift;
        my $msg  = shift || undef;
 
        my $mgr = $self->{MGR};
        my $cgi = $self->{MGR}->{CGI};

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
 
        my $mgr = $self->{MGR};
        my $cgi = $self->{MGR}->{CGI};

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
# XXX Hier noch pruefen, dass das Startdatum vor dem Endedatum liegt etc.
# XXX Hier noch die beiden Datumsangaben auf Richtigkeit pruefen. 
	$start_dt = sprintf("%04d.%02d.%02d 00:00:00", $start_jahr, $start_monat, $start_tag);
	$end_dt   = sprintf("%04d.%02d.%02d 00:00:00", $ende_jahr, $ende_monat, $ende_tag);
	
	if ($self->{BASE}->check_project_name($name, $kid)) {
		$mgr->{TmplData}{ERROR_NAME} = $mgr->decode_all($C_MSG->{ExistName});
		$check++;
	}

        if ($check) {
                $self->menue_new($C_MSG->{ErrorAddPro});
        } else {

		my $dbh = $mgr->connect;
		unless ($dbh->do("LOCK TABLES $mgr->{ProTable} WRITE, $mgr->{CUserTable} WRITE")) {
                	warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
                        	$mgr->{ProTable}, $dbh->ersstr);
        	}
		my $sth = $dbh->prepare(qq{INSERT INTO $mgr->{ProTable} (name, desc_project, cat_id ,start_dt, end_dt, 
					   ins_dt, ins_id) VALUES (?, ?, ?, ?, ?, ?, ?)});

		unless ($sth->execute($name, $beschreibung, $kid, $start_dt, $end_dt, $mgr->now, $mgr->{UserId})) {
			warn sprintf("[Error]: Trouble inserting project into [%s]. Reason [%s].",
				$mgr->{ProTable}, $dbh->errstr);
			$dbh->do("UNLOCK TABLES");
			$mgr->fatal_error($C_MSG->{DbError});
		}

		my $insertid = $dbh->{mysql_insertid};

		$sth = $dbh->prepare(qq{INSERT INTO $mgr->{CUserTable} (project_id) VALUES (?)});

		unless ($sth->execute($insertid)) {
                        warn sprintf("[Error]: Trouble inserting user count into [%s]. Reason [%s].",
                                $mgr->{CUserTable}, $dbh->errstr);
                        $dbh->do("UNLOCK TABLES");
                        $mgr->fatal_error($C_MSG->{DbError});
                } 

		$dbh->do("UNLOCK TABLES");
		$sth->finish;
		$self->menue($C_MSG->{InsertProOk});
	}
}

sub show_projects {

	my $self  = shift;
	my $check = shift || undef;
 
        my $mgr = $self->{MGR};
        my $cgi = $self->{MGR}->{CGI};

	$self->{BASE}->check_user(); 

	my ($name, $cat);

	if ($check) {
		$name = $mgr->{Session}->get("SearchProjectName") || undef;
		$cat  = $mgr->{Session}->get("SearchCatId");
	} else {
		$name = $cgi->param('project_name') || undef;
		$cat  = $cgi->param('project_category');

		$mgr->{Session}->set(SearchProjectName => $name,
				     SearchCatId       => $cat);
	}

	my $mode = 0; 
	$mode = 1 if ($name);

	$self->{BASE}->get_and_set_projects($mode, $cat, $name);
	
	return 1;	
}

1;
