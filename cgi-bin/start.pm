package start;

use Class::Singleton;
use base 'Class::Singleton';
use start_config;
use vars qw($VERSION $conf);
use strict;

$VERSION = sprintf "%d.%03d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/;

#====================================================================================================#
# SYNOPSIS: parameter($mgr);
# PURPOSE:  Managt dieses Modul in bezug auf die Aufrufe durch POST und GET.
# RETURN:   1;
#====================================================================================================#
sub parameter {
	my $self = shift;
	my $mgr  = shift;

	# Wenn wir eine Session Id haben, pruefen wir, ob der User sich ausloggen will.
	if ($mgr->{Sid}) {
		if (defined $mgr->{CGI}->param('method') && $mgr->{CGI}->param('method') eq "logout") {
			# Session killen und die Logoutseite generien.
			$mgr->{Session}->kill_session($mgr->{CGI}->param('sid'));
			$mgr->{Sid}            = undef;
			$mgr->{Template}       = $mgr->{LoginTmpl};
			$mgr->{TmplData}{FORM} = $mgr->my_url();
			return 1;
		}

		# Sonst geben wir die Startseite wieder aus.
		$self->show_start($mgr);
		return 1;
	}

	# Wenn der Startbutton nicht gedrueckt wurde zeigen wir die Loginseite.
	unless ($mgr->{CGI}->param('start')) {
		$mgr->{Template}       = $mgr->{LoginTmpl};
        	$mgr->{TmplData}{FORM} = $mgr->my_url();
		return 1;
	}

	my $username  = $mgr->{CGI}->param('username') || undef;
	my $password  = $mgr->{CGI}->param('password') || undef;

	my $check = 0;

	# Wurde der Username angegeben?
	unless (defined $username) {
		$mgr->{TmplData}{NO_USERNAME} = $mgr->decode_all($start_config::MSG->{NoUserName});
		$check++;
	}

	# Wurde das Passwort angegeben?
	unless (defined $password) {
		$mgr->{TmplData}{NO_PASSWORD} = $mgr->decode_all($start_config::MSG->{NoPassWord});
		$check++;
	}

	# Wenn ein Fehler gezaehlt wurde, geben wir die Loginseite mit Fehlern aus.
	if ($check) {
		$mgr->{Template}           = $mgr->{LoginTmpl};
        	$mgr->{TmplData}{FORM}     = $mgr->my_url();
		$mgr->{TmplData}{USERNAME} = $mgr->decode_some($username) if (defined $username);
                $mgr->{TmplData}{PASSWORD} = $mgr->decode_some($password) if (defined $password);
		return 1;
	}

	# Ueberpruefen des Usernames und des Passworts.
	if ($self->check($mgr, $username, $password)) {
		$self->show_start($mgr);
		return 1;
	}

	# Sonst Startseite ausgeben.
	$mgr->{Template}       = $mgr->{LoginTmpl};
	$mgr->{TmplData}{FORM} = $mgr->my_url();
	$mgr->{TmplData}{MSG}  = $mgr->decode_all($start_config::MSG->{NoUserExist});
}

#====================================================================================================#
# SYNOPSIS: $self->check($mgr, $username, $password);
# PURPOSE:  Prueft, ob es einen User mit diesem Passwort gibt. Wenn ja kann er sich einloggen.
# RETURN:   true. 
#====================================================================================================#
sub check {
	my $self     = shift;
	my $mgr      = shift;
	my $username = shift;
	my $password = shift;

	# Connecten und nach dem User suchen.
	my $dbh = $mgr->connect;
	my $sth = $dbh->prepare(qq{SELECT * FROM $mgr->{UserTable} WHERE username = ? AND status = '1'});

	# Datenbankanfrage durchfuehren.	
	unless ($sth->execute($username)) {
		warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",
			$mgr->{UserTable}, $dbh->errstr);
		$mgr->fatal_error($start_config::MSG->{DbError});
	}

	if ($sth->rows == 0) {
		warn "[Alert]: Searching password for unknown user or user inaktivated.";
		return undef;
	}

	# Wenn wir hier sind, haben wir einen User gefunden und fuellen die Daten.
	while (my $href = $sth->fetchrow_hashref) {
		unless ($password eq $href->{password})	{
			return undef;
		}

		$mgr->{UserFirstName} = $href->{firstname};
		$mgr->{UserLastName}  = $href->{lastname};
		$mgr->{UserId}        = $href->{id};
		$mgr->{UserType}      = $href->{type};
	}

	# Starten der Session.
	$mgr->{Sid} = $mgr->{Session}->start_session(FIRSTNAME => $mgr->{UserFirstName},
                             			     LASTNAME  => $mgr->{UserLastName},
                             			     USERID    => $mgr->{UserId},
                             			     USERTYPE  => $mgr->{UserType});
	
	1;
}

#====================================================================================================#
# SYNOPSIS: $self->show_start($mgr);
# PURPOSE:  Setzt das richtige Template und fuellt die Navigation aus.
# RETURN:   1;
#====================================================================================================#
sub show_start {
	my $self = shift;
	my $mgr  = shift;

	$mgr->{Template} = $mgr->{StartTmpl};
	$mgr->fill;
	
	return 1;
}

1;
