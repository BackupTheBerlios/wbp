package message;

use Class::Singleton;
use base 'Class::Singleton';
use message_config;
use vars qw($VERSION);
use strict;
 
$VERSION = sprintf "%d.%03d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/;

sub parameter {
    
    my $self = shift;
    my $mgr  = shift;
    
    if (defined $mgr->{CGI}->param('method') && $mgr->{CGI}->param('method') eq "write") {
	$self->message_form($mgr);
	return 1;
    } elsif (defined $mgr->{CGI}->param('method') && $mgr->{CGI}->param('method') eq "confirm") {
	$self->message_confirm($mgr);
	return 1;
    } else {
	$self->message_menu($mgr);
	return 1;
    }

    $mgr->{Template}      = $mgr->{ErrorTmpl};
    $mgr->{TmplData}{MSG} = $mgr->decode_all("... ?");
    return 1;
}



sub message_form {
    my $self = shift;
    my $mgr  = shift;

    my $dbh = $mgr->connect;
    my $sth = $dbh->prepare(qq{SELECT id,username,firstname,lastname FROM $mgr->{UserTable}});

    unless ($sth->execute()) {
	warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",
		     $mgr->{UserTable}, $dbh->errstr);
	$mgr->fatal_error($message_config::MSG->{DbError});
    }


    my $loop_data;
    while (my $aref = $sth->fetchrow_arrayref()) {

	unless ($mgr->{UserId} eq $aref->[0]) {
	    my $href = {
		MSG_TO_NAME => sprintf("%s %s (%s)",$aref->[2],$aref->[3],$aref->[1]),
		MSG_TO_UID => $aref->[0]
		};
	    push @$loop_data, $href;
	}
    }

   my $link = $mgr->{ScriptName}."?action=%s&sid=".$mgr->{Sid};
    
    $mgr->{Template} = $mgr->{MessageFormTmpl};
    
    $mgr->{TmplData}{ACTION} = $mgr->{Action};
    $mgr->{TmplData}{SID} = $mgr->{Sid};
    $mgr->{TmplData}{FORM} = $mgr->my_url();
    $mgr->{TmplData}{SUBJECT} = "blablabla";
    $mgr->{TmplData}{MSG_TO_LOOP} = $loop_data;    
    
    # zurueck ins Main Menue mit action=start
    $mgr->{TmplData}{NAV_START} = sprintf($link, "start");
    $mgr->{TmplData}{NAV_MESSAGE}    = sprintf($link, $mgr->{Action});
    $link .= "&method=%s";
    $mgr->{TmplData}{METHOD}    = "confirm";
    
    $mgr->fill_header;

    1;
}



sub message_confirm {
    my $self = shift;
    my $mgr  = shift;


    my $dbh = $mgr->connect;
    my $sth = $dbh->prepare(qq{SELECT id,username,firstname,lastname FROM $mgr->{UserTable}});

    unless ($sth->execute()) {
	warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",
		     $mgr->{UserTable}, $dbh->errstr);
	$mgr->fatal_error($message_config::MSG->{DbError});
    }

    my $loop_data;
    while (my $aref = $sth->fetchrow_arrayref()) {

	unless ($mgr->{UserId} eq $aref->[0]) {
	    my $href = {
		MSG_TO_NAME => sprintf("%s %s (%s)",$aref->[2],$aref->[3],$aref->[1]),
		MSG_TO_UID => $aref->[0]
		};
	    push @$loop_data, $href;
	}
    }


    my $link = $mgr->{ScriptName}."?action=%s&sid=".$mgr->{Sid};
    
    $mgr->{Template} = $mgr->{MessageConfirmTmpl};
    
    $mgr->{TmplData}{ACTION} = $mgr->{Action};
    $mgr->{TmplData}{SID} = $mgr->{Sid};
    $mgr->{TmplData}{FORM} = $mgr->my_url();
    if (defined $mgr->{CGI}->param('subject')) {
	$mgr->{TmplData}{SUBJECT} = $mgr->{CGI}->param('subject');
    } else {
	$mgr->{TmplData}{NO_SUBJECT} = $mgr->decode_all($message_config::MSG->{NoSubject});
    }
    $mgr->{TmplData}{MSG_TO_LOOP} = $loop_data;    
    
    # zurueck ins Main Menue mit action=start
    $mgr->{TmplData}{NAV_START} = sprintf($link, "start");
    $mgr->{TmplData}{NAV_MESSAGE}    = sprintf($link, $mgr->{Action});
    $link .= "&method=%s";
    $mgr->{TmplData}{METHOD}    = "send";
    
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



