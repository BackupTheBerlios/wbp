package message;

use Class::Singleton;
use base 'Class::Singleton';
use message_config;
use vars qw($VERSION);
use strict;
 
$VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/;
 
sub parameter {
 
        my $self = shift;
        my $mgr  = shift;
	
	if (defined $mgr->{CGI}->param('method') && $mgr->{CGI}->param('method') eq "write") {
	    $self->message_form($mgr);
	    return 1;
	} elsif (defined $mgr->{CGI}->param('method') && $mgr->{CGI}->param('method') eq "confirm") {
        $mgr->{Template}      = $mgr->{ErrorTmpl};
        $mgr->{TmplData}{MSG} = $mgr->decode_all("Wollen Sie das wirklich?");
	    return 1;
	} else {
	    $self->message_menu($mgr);
	    return 1;
	}
}



sub message_form {
	my $self = shift;
	my $mgr  = shift;

	my $link = $mgr->{ScriptName}."?action=%s&sid=".$mgr->{Sid};

	$mgr->{Template} = $mgr->{MessageFormTmpl};

	$mgr->{TmplData}{ACTION} = $mgr->{Action};
	$mgr->{TmplData}{SID} = $mgr->{Sid};
	$mgr->{TmplData}{FORM} = $mgr->my_url();
	$mgr->{TmplData}{SUBJECT} = "Betreff: blablabla";

	# zurueck ins Main Menue mit action=start
	$mgr->{TmplData}{NAV_START} = sprintf($link, "start");
	$mgr->{TmplData}{NAV_MESSAGE}    = sprintf($link, $mgr->{Action});
	$link .= "&method=%s";
	$mgr->{TmplData}{METHOD}    = "confirm";

	$mgr->fill_header;

	1;
}




sub message_menu {

	my $self = shift;
	my $mgr  = shift;

	my $link = $mgr->{ScriptName}."?action=%s&sid=".$mgr->{Sid};

	$mgr->{Template} = $mgr->{MessageTmpl};

	# zurueck ins Main Menue mit action=start
	$mgr->{TmplData}{NAV_START} = sprintf($link, "start");

	$link .= "&method=%s";
	$mgr->{TmplData}{NAV_MSG_READ}    = sprintf($link, "message","read");
	$mgr->{TmplData}{NAV_MSG_WRITE}    = sprintf($link, "message","write");

	$mgr->fill_header;

	1;
}





1;



