package message;

use Class::Singleton;
use base 'Class::Singleton';
use message_base;
use message_config;
use vars qw($VERSION $C_MSG $C_TMPL);
use strict;

$VERSION = sprintf "%d.%03d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/;

$C_MSG  = $message_config::MSG;
$C_TMPL = $message_config::TMPL;

sub parameter {
    
    my $self = shift;
    my $mgr  = shift;
    
    
    # Global for this package here.
    $self->{MGR} = $mgr;
    
    $mgr->{MyUrl} = $mgr->my_url;
    
    my $cgi    = $mgr->{CGI};
    my $method = $cgi->param('method') || undef;
    
    eval { 
	$self->{BASE} = message_base->new({MGR    => $mgr,
					   C_MSG  => $C_MSG,
					   C_TMPL => $C_TMPL}); 
    };
    if ($@) {
	warn "Can't create class [message_base].";
	warn "[Error]: $@";
	$mgr->fatal_error($C_MSG->{NormalError});
    }	
    
    if (defined $method) {

	if ($method eq 'received_new') {
	    # Message-Template mit Uebersicht der neuen Nachrichten
	    $self->received_messages(0);

	} elsif ($method eq 'received_old') {
	    # Message-Template mit Uebersicht der alten Nachrichten
	    $self->received_messages(1);

	} elsif ($method eq "send_messages") {
	    # Message-Template mit Uebersicht der abgeschickten Nachrichten
	    $self->received_messages(0);

	} elsif ($method eq "new") {
	    $self->form();

	} elsif ($method eq "send") {
	    $self->send();

	} elsif ($method eq "show") {
	    $self->show();
	}
    }
    else {
	# Message-Template mit Uebersicht der neuen Nachrichten
	$self->received_messages(0);
    }
}


#====================================================================================================#
# SYNOPSIS: received_messages($status);
# PURPOSE:  Uebersicht der empfangenen Nachrichten (status: 0=ungelesen, 1=gelesen)
# RETURN:   ---
#====================================================================================================#
sub received_messages {

        my $self = shift;
	my $status = shift || 0;

        my $mgr = $self->{MGR};

 	my $link = $mgr->{MyUrl};
	my $msg = '';
	# alle empfangenen Nachrichten mit dem angegebenen Status abrufen
	my @messages = $self->{BASE}->fetch_received_messages($status);

	# Message-Template vorbereiten
	$mgr->{Template} = $C_TMPL->{Message};

	# Es wurden Nachrichten gefunden
	if (@messages) {
	    my @loop;
	    my $user;
	    $link .= "&method=%s&mid=%s";

	    for (my $i = 0; $i <= $#messages; $i++) {
		$user = $self->{BASE}->get_user($messages[$i]->{from_uid});
		$loop[$i]{FIRSTNAME} = $mgr->decode_all($user->{firstname});
		$loop[$i]{LASTNAME} = $mgr->decode_all($user->{lastname});
		$loop[$i]{USERNAME}  = $mgr->decode_all($user->{username});
		$loop[$i]{MSG_LINK}  = $mgr->decode_all(sprintf($link, "show", $messages[$i]->{mid}));
		$loop[$i]{SUBJECT}   = $mgr->decode_all($messages[$i]->{subject});
		$loop[$i]{DATE}      = $mgr->decode_all($messages[$i]->{date});
	    }

	    $mgr->{TmplData}{MSG_LOOP} = \@loop;

	    # Es gibt genau eine Nachricht
	    if ($#messages == 0) {
		if ($status == 0) {
		    $msg = sprintf($C_MSG->{NewMessage});
		} else {
		    $msg = sprintf($C_MSG->{OldMessage});
		}
	    } else {
		# Es gibt mehrere Nachrichten
		if ($status == 0) {
		    $msg = sprintf($C_MSG->{NewMessages},$#messages+1);
		} else {
		    $msg = sprintf($C_MSG->{OldMessages},$#messages+1); 
		}
	    }
	} else {
	    # Es gibt keine Nachricht

	    if ($status == 0) {
		$msg = $C_MSG->{NoNewMessages};
	    } else {
		$msg = $C_MSG->{NoOldMessages};
	    }
	}

	$mgr->{TmplData}{MSG_NOTIFY} = $msg;
	$mgr->{TmplData}{MSG} = $msg;
	
	$self->fill_msg_nav();

        $mgr->fill; 

	return;
}



#====================================================================================================#
# SYNOPSIS: show();
# PURPOSE:  Einzelansicht einer empfangenen Nachricht
# RETURN:   ---
#====================================================================================================#
sub show {
 
        my $self = shift;
	
        my $mgr = $self->{MGR};

	my $cgi = $mgr->{CGI};
	my $mid = $cgi->param('mid');

	my $link = $mgr->{MyUrl};
	my $message = $self->{BASE}->get_message($mid);

	
	# Error-Template vorbereiten
#	$mgr->{Template} = $mgr->{ErrorTmpl};
#	$mgr->fill($C_MSG->{NoSuchMsgError});

	
	# MessageShow-Template vorbereiten
	$mgr->{Template} = $C_TMPL->{MessageShow};
	if ($message->{status} eq '0') {
	    $mgr->{TmplData}{STATUS} = 'neu';
	} elsif ($message->{status} eq '1') {
	    $mgr->{TmplData}{STATUS} = 'alt';
	} else {
	    $mgr->{TmplData}{STATUS} = 'alt';
	}
	# Message bezieht sich auf eine Parent-Message
	unless ($message->{parent_mid} == 0) {
	    
	    $link .= "&method=%s&mid=%s";
	    $mgr->{TmplData}{PARENT_LINK} = sprintf($link, "show", $message->{parent_mid});
	}

	$mgr->{TmplData}{DATE} = $message->{date};
	
	my $user = $self->{BASE}->get_user($message->{from_uid});
	$mgr->{TmplData}{FIRSTNAME} = $mgr->decode_all($user->{firstname});
	$mgr->{TmplData}{LASTNAME}  = $mgr->decode_all($user->{lastname});
	$mgr->{TmplData}{USERNAME}  = $mgr->decode_all($user->{username});
	$mgr->{TmplData}{SUBJECT}   = $message->{subject};
	$mgr->{TmplData}{CONTENT}   = $message->{content};
	$link = $mgr->{MyUrl};
	$link .= "&method=%s&parent_mid=%s";
	$mgr->{TmplData}{REPLY} = sprintf($link, "new", $message->{parent_mid});

	$self->fill_msg_nav;
	$mgr->fill;

	return;
}




#====================================================================================================#
# SYNOPSIS: form();
# PURPOSE:  Neue Nachrichten verfassen, d.h. Formular erzeugen
# RETURN:   ---
#====================================================================================================#
sub form {
 
        my $self = shift;

        my $mgr = $self->{MGR};
        my $cgi = $self->{MGR}->{CGI};
 
        my $uid = $cgi->param('uid');
	my $parent_mid = $cgi->param('parent_mid') || 0;
        my $subject = $cgi->param('subject') || "";
        my $content = $cgi->param('content') || "";

	# MessageNew-Template (Formular) vorbereiten
	$mgr->{Template} = $C_TMPL->{MessageForm};

	# Liste von aktiven Usern
	my @users = $self->{BASE}->fetch_users(1);	

	if (@users) {
	    my @loop;
	    for (my $i = 0; $i <= $#users; $i++) {
		$loop[$i]{UID}       = $users[$i]->{id};
		$loop[$i]{FIRSTNAME} = $mgr->decode_all($users[$i]->{firstname});
		$loop[$i]{LASTNAME}  = $mgr->decode_all($users[$i]->{lastname});
		$loop[$i]{USERNAME}  = $mgr->decode_all($users[$i]->{username});
	    }
	    
	    $mgr->{TmplData}{USER_LOOP} = \@loop;
	}

	# Liste von Projekten
	my @projects = $self->{BASE}->fetch_projects;

	if (@projects) {
	    my @loop;
	    
	    for (my $i = 0; $i <= $#projects; $i++) {
		$loop[$i]{PID}   = $projects[$i][0];
		$loop[$i]{PNAME} = $mgr->decode_all($projects[$i][1]);
	    }
	    
	    $mgr->{TmplData}{PROJECT_LOOP} = \@loop;
	}

	$mgr->{TmplData}{FORM_ACTION} = $mgr->{MyUrl};
	$mgr->{TmplData}{METHOD}  = "send";
	$mgr->{TmplData}{SUBJECT} = $mgr->decode_all($subject);
	$mgr->{TmplData}{CONTENT} = $mgr->decode_all($content);
	$mgr->{TmplData}{PARENT_MID} = $mgr->decode_all($parent_mid);


	$self->fill_msg_nav;
	$mgr->fill;

	return;
}

#====================================================================================================#
# SYNOPSIS: send();
# PURPOSE:  Neue Nachricht in den Tables ablegen
# RETURN:   ---
#====================================================================================================#
sub send {
 
        my $self = shift;

        my $mgr = $self->{MGR};
        my $cgi = $self->{MGR}->{CGI};

        my @uid = $cgi->param('uid') || undef;
	my @pid = $cgi->param('pid') || undef;
	my $parent_mid = $cgi->param('parent_mid') || 0;
        my $subject = $cgi->param('subject') || "no subject";
        my $content = $cgi->param('content') || "no content";

	# Die Projektmitglieder in die Liste der UserIDs aufnehmen
	my $project_members = $self->{BASE}->fetch_project_members(\@pid);
	foreach (@$project_members) {
	    push(@uid, $_);
	}
	
	$self->{BASE}->insert_new_messages(\@uid, $parent_mid, $subject, $content);
	# MessageTest-Template vorbereiten
	$mgr->{Template} = $C_TMPL->{MessageTest};
	$self->fill_msg_nav;
	$mgr->fill;
	return;
}



#====================================================================================================#
# SYNOPSIS: fill_msg_nav;
# PURPOSE:  Navigation des Message-Systems vorbereiten
# RETURN:   ---
#====================================================================================================#
sub fill_msg_nav {

    my $self = shift;
    
    my $mgr = $self->{MGR};
    my $link = $mgr->{MyUrl};
    
    # Message-Navigation vorbereiten
    $link .= "&method=%s";
    $mgr->{TmplData}{NAV_MSG_NEW}   = sprintf($link,"received_new");
    $mgr->{TmplData}{NAV_MSG_OLD}   = sprintf($link,"received_old");
    $mgr->{TmplData}{NAV_MSG_SEND}  = sprintf($link,"send");
    $mgr->{TmplData}{NAV_MSG_WRITE} = sprintf($link,"new");
    return;
}


1;
