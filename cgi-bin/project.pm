package project;

use Class::Singleton;
use base 'Class::Singleton';
use project_config;
use vars qw($VERSION);
use strict;

$VERSION = sprintf "%d.%03d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/;

sub parameter {

	my $self = shift;
	my $mgr  = shift;

	if ($mgr->{UserType} eq "D") {
		$mgr->fatal_error($project_config::MSG->{NotAllowed});
	}

	my $cgi    = $mgr->{CGI};
	my $method = $cgi->param('method') || undef;

	if (defined $method) {
		if ($method eq "show_project") {

		} elsif ($method eq "show_phase") {

		} elsif ($method eq "change_user_ab") {

		} elsif ($method eq "change_user_c") {

		} elsif ($method eq "change_user_d") {

		} 
	} else {
		if (defined $cgi->param('new')) {

		} elsif (defined $cgi->param('search')) {

		} elsif (defined $cgi->param('add_project')) {

		} elsif (defined $cgi->param('add_phase')) {
	
		} elsif (defined $cgi->param('change_project')) {

		} elsif (defined $cgi->param('change_phase')) {	

		} elsif (defined $cgi->param('change_user_ab')) {

		} elsif (defined $cgi->param('change_user_c')) {

		} elsif (defined $cgi->param('change_user_d')) {

		}
	}

	$mgr->{Tmpldata}{PROJECTS} = 1 if ($self->check_for_projects($mgr) != 0);
	
	if ($mgr->{UserType} ne "C") {
		$mgr->{TmplData}{USER_AB}    = 1;
		$mgr->{TmplData}{CATEGORIES} = 1 if ($self->check_for_categories($mgr) != 0);
	}
	
	$mgr->{Template} = $project_config::TMPL->{Project};
	$mgr->fill_header;
}

sub check_for_projects {

	my $self = shift;
	my $mgr  = shift;

	my $dbh = $mgr->connect;
	my $sth = $dbh->prepare(qq{SELECT * FROM $mgr->{ProTable}});

	unless ($sth->execute()) {
		warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
			$mgr->{ProTable}, $dbh->errstr);
		$mgr->fatal_error($project_config::MSG->{DbError});
	}

	return $sth->rows;	
}

sub check_for_categories {

	my $self = shift;
	my $mgr  = shift;

	my $dbh = $mgr->connect;
        my $sth = $dbh->prepare(qq{SELECT * FROM $mgr->{CatTable}});
 
        unless ($sth->execute()) {
                warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
                        $mgr->{CatTable}, $dbh->errstr);
                $mgr->fatal_error($project_config::MSG->{DbError});
        }
 
        return $sth->rows;
}

1;
