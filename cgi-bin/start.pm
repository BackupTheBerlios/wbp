package start;

use Class::Singleton;
use base 'Class::Singleton';
use start_config;
use vars qw($VERSION $conf);
use strict;

$VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/;

sub parameter {

	my $self = shift;
	my $mgr  = shift;

	if ($mgr->{Sid}) {
		$self->main_menu($mgr);
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
		$mgr->{Template}       = $mgr->{LoginTmpl};
        	$mgr->{TmplData}{FORM} = $mgr->my_url();
		return 1;
	}

	if ($self->check($mgr, $username, $password)) {
		$mgr->{Sid} = $mgr->{Session}->start_session();
		$self->main_menu($mgr);
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

	$mgr->{UserFirstName} = "";
	$mgr->{UserLastName}  = "";
	$mgr->{UserId}        = "";
	$mgr->{UserType}      = "";
	
	1;
}

sub main_menu {

	my $self = shift;
	my $mgr  = shift;

	$mgr->{Template} = $mgr->{StartTmpl};

	1;
}

1;
