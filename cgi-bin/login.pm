package login;

use Class::Singleton;
use base 'Class::Singleton';
use vars qw($VERSION);
use strict;

$VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/;

sub parameter {

	my $self = shift;
	my $mgr  = shift;

	unless ($mgr->{CGI}->param('login')) {
		$mgr->{Template}       = $mgr->{LoginTmpl};
        	$mgr->{TmplData}{FORM} = $mgr->my_url();
		return 1;
	}

	my $username  = $mgr->{CGI}->param('username') || undef;
	my $password  = $mgr->{CGI}->param('password') || undef;

	my $check = 0;

	unless (defined $username) {
		$mgr->{TmplData}{NO_USERNAME} = $mgr->decode_all("Bitte geben Sie einen Usernamen ein.");
		$check++;
	}

	unless (defined $password) {
		$mgr->{TmplData}{NO_PASSWORD} = $mgr->decode_all("Bitte geben Sie ein Passwort ein.");
		$check++;
	}

	if ($check) {
		$mgr->{Template}       = $mgr->{LoginTmpl};
        	$mgr->{TmplData}{FORM} = $mgr->my_url();
		return 1;
	}

	if ($self->check($mgr, $username, $password)) {
		$self->main_menu($mgr);
		return 1;
	}

	$mgr->{Template}       = $mgr->{LoginTmpl};
	$mgr->{TmplData}{FORM} = $mgr->my_url();
	$mgr->{TmplData}{MSG}  = $mgr->decode_all("Es existiert kein Benutzer mit diesem Passwort.");
}

sub check {
	
	my $self     = shift;
	my $mgr      = shift;
	my $username = shift;
	my $password = shift;

	1;
}

sub main_menu {

	my $self = shift;
	my $mgr  = shift;

	$mgr->{Template} = $mgr->{MainTmpl};
	$mgr->{Sid}      = $mgr->{Session}->start_session();

	return;
}

1;
