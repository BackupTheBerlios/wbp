package project;

use Class::Singleton;
use base 'Class::Singleton';
use project_config;
use vars qw($VERSION);
use strict;

$VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/;

sub parameter {

	my $self = shift;
	my $mgr  = shift;

	$mgr->{Template} = $mgr->{ProjectTmpl};
	$mgr->fill_header;
}

1;
