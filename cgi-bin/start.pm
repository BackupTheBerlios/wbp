package start;

use Class::Singleton;
use base 'Class::Singleton';
use start_config;
use vars qw($VERSION $conf);
use strict;

$VERSION = sprintf "%d.%03d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/;

sub parameter {

	my $self = shift;
	my $mgr  = shift;

	if ($mgr->{Sid}) {
		if (defined $mgr->{CGI}->param('method') && $mgr->{CGI}->param('method') eq "logout") {
			$mgr->{Session}->kill_session($mgr->{CGI}->param('sid'));
			$mgr->{Sid}            = undef;
			$mgr->{Template}       = $mgr->{LoginTmpl};
			$mgr->{TmplData}{FORM} = $mgr->my_url();
			return 1;
		}

		$self->show_start($mgr);
		return 1;
	}

	unless ($mgr->{CGI}->param('start')) {
		$mgr->{Template}       = $mgr->{LoginTmpl};
        	$mgr->{TmplData}{FORM} = $mgr->my_url();
		return 1;
	}

	my $username  = $mgr->{CGI}->param('username') || undef;
	my $password  = $mgr->{CGI}->param('password') || undef;

	my $check = 0;

	unless (defined $username) {
		$mgr->{TmplData}{NO_USERNAME} = $mgr->decode_all($start_config::MSG->{NoUserName});
		$check++;
	}

	unless (defined $password) {
		$mgr->{TmplData}{NO_PASSWORD} = $mgr->decode_all($start_config::MSG->{NoPassWord});
		$check++;
	}

	if ($check) {
		$mgr->{Template}           = $mgr->{LoginTmpl};
        	$mgr->{TmplData}{FORM}     = $mgr->my_url();
		$mgr->{TmplData}{USERNAME} = $mgr->decode_some($username) if (defined $username);
                $mgr->{TmplData}{PASSWORD} = $mgr->decode_some($password) if (defined $password);
		return 1;
	}

	if ($self->check($mgr, $username, $password)) {
		$self->show_start($mgr);
		return 1;
	}

	$mgr->{Template}       = $mgr->{LoginTmpl};
	$mgr->{TmplData}{FORM} = $mgr->my_url();
	$mgr->{TmplData}{MSG}  = $mgr->decode_all($start_config::MSG->{NoUserExist});
}

sub check {
	
	my $self     = shift;
	my $mgr      = shift;
	my $username = shift;
	my $password = shift;

	my $dbh = $mgr->connect;
	my $sth = $dbh->prepare(qq{SELECT * FROM $mgr->{UserTable} WHERE username = ?});
	
	unless ($sth->execute($username)) {
		warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",
			$mgr->{UserTable}, $dbh->errstr);
		$mgr->fatal_error($start_config::MSG->{DbError});
	}

	if ($sth->rows == 0) {
		warn "[Alert]: Searching password for unknown user.";
		return undef;
	}

	while (my $href = $sth->fetchrow_hashref) {
		unless ($password eq $href->{password})	{
			return undef;
		}

		$mgr->{UserFirstName} = $href->{firstname};
		$mgr->{UserLastName}  = $href->{lastname};
		$mgr->{UserId}        = $href->{id};
		$mgr->{UserType}      = $href->{type};
	}

	$mgr->{Sid} = $mgr->{Session}->start_session(FIRSTNAME => $mgr->{UserFirstName},
                             			     LASTNAME  => $mgr->{UserLastName},
                             			     USERID    => $mgr->{UserId},
                             			     USERTYPE  => $mgr->{UserType});
	
	1;
}

sub show_start {

	my $self = shift;
	my $mgr  = shift;

	$mgr->{Template} = $mgr->{StartTmpl};
	$mgr->fill;
	
	return;
}

1;
