package project;

use Class::Singleton;
use base 'Class::Singleton';
use vars qw($VERSION);
use strict;

$VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/;

sub parameter {

	my $self = shift;
	my $mgr  = shift;

	$mgr->{Template}      = $mgr->{ErrorTmpl};
        $mgr->{TmplData}{MSG} = $mgr->decode_all("Jau, wir sind im proejct bereich ...");
}

1;
