package message;

use Class::Date qw(date);
use Class::Singleton;
use base 'Class::Singleton';
use message_base;
use message_config;
use vars qw($VERSION $C_MSG $C_TMPL);
use strict;

$VERSION = sprintf "%d.%03d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/;

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
	if ($method eq 'inbox') {
	    # Message-Template mit Uebersicht der neuen Nachrichten
	    $self->view_messages(0);
	    return 1;
	} elsif ($method eq 'received') {
	    # Message-Template mit Uebersicht der alten Nachrichten
	    $self->view_messages(1);
	    return 1;
	} elsif ($method eq "send") {
	    # Message-Template mit Uebersicht der abgeschickten Nachrichten
	    $self->view_send_messages();
	    return 1;
	} elsif ($method eq "compose_message") {
	    $self->compose_message();
	    return 1;
	} elsif ($method eq "show_message") {
	    $self->show_message();
	    return 1;
	} elsif ($method eq "show_send_message") {
	    $self->show_send_message();
	    return 1;
	}
    }
    else {
	if (defined $cgi->param('send_message')) {
	    # Nachricht versenden, d.h. in die Tables eintragen
	    $self->send_message();
	    return 1;
	} elsif (defined $cgi->param('choose_receivers')) {
	    $self->choose_receivers();
	    return 1;
	} elsif (defined $cgi->param('spy_harddisk')) {

	} elsif (defined $cgi->param('spread_virus')) {

	} elsif (defined $cgi->param('surprise...')) {

	}
    }

    # default
    $self->view_messages(0); # Uebersicht der Inbox-Messages anzeigen
}


#====================================================================================================#
# SYNOPSIS: view_messages($status);
# PURPOSE:  Uebersicht der empfangenen Nachrichten ($status=0 Inbox, $status=1 Received)
# RETURN:   1
#====================================================================================================#
sub view_messages {

        my $self = shift;
	my $status = shift || 0;

        my $mgr = $self->{MGR};

	# alle empfangenen Nachrichten mit dem angegebenen Status abrufen
	# Jede der Nachrichten besteht aus (mid,from_uid,date,subject)
	my @received = $self->{BASE}->fetch_received($status);

	# Message-Template vorbereiten
	$mgr->{Template} = $C_TMPL->{Message};

	my $message_status;

	# Es wurden Nachrichten gefunden
	if (@received) {
	    my @message_loop;
	    my @user;
	    my $link = $mgr->my_url;
	    $link .= "&method=%s&mid=%s";

	    for (my $i = 0; $i <= $#received; $i++) {
		# Namen des Absenders bestimmen
		@user = $self->{BASE}->get_user($received[$i][1]);
		$message_loop[$i]{MESSAGE_SENDER}  =
		    $mgr->decode_all(sprintf("%s %s (%s)", $user[0], $user[1], $user[2]));
		$message_loop[$i]{MESSAGE_LINK}    = $mgr->decode_all(sprintf($link, "show_message", $received[$i][0]));
		$message_loop[$i]{MESSAGE_SUBJECT} = $mgr->decode_all($received[$i][3]);
		$message_loop[$i]{MESSAGE_DATE}    = $mgr->decode_all($mgr->format_date($received[$i][2]));
	    }

	    $mgr->{TmplData}{MESSAGE_LOOP} = \@message_loop;

	    # Es gibt genau eine Nachricht
	    if ($#received == 0) {
		if ($status == 0) {
		    $message_status = $C_MSG->{InboxMessage};
		} else {
		    $message_status = $C_MSG->{ReceivedMessage};
		}
	    } else {
		# Es gibt mehrere Nachrichten
		if ($status == 0) {
		    $message_status = sprintf($C_MSG->{InboxMessages},$#received+1);
		} else {
		    $message_status = sprintf($C_MSG->{ReceivedMessages},$#received+1); 
		}
	    }
	} else {
	    # Es gibt keine Nachricht
	    if ($status == 0) {
		$message_status = $C_MSG->{InboxEmpty};
	    } else {
		$message_status = $C_MSG->{ReceivedEmpty};
	    }
	}

	$mgr->{TmplData}{MESSAGE_STATUS} = $message_status;
	
	$self->fill_nav();

        $mgr->fill; 

	return 1;
}


#====================================================================================================#
# SYNOPSIS: view_send_messages();
# PURPOSE:  Uebersicht der empfangenen Nachrichten ($status=0 Inbox, $status=1 Received)
# RETURN:   1
#====================================================================================================#
sub view_send_messages {

        my $self = shift;
	my $status = shift || 0;

        my $mgr = $self->{MGR};

	# Alle abgesandten Nachrichten holen
	# Jede der Nachrichten besteht aus (id,date,subject)
	my @send = $self->{BASE}->fetch_send();

	# Message-Template vorbereiten
	$mgr->{Template} = $C_TMPL->{MessageSend};

	my $message_status;

	# Es wurden Nachrichten gefunden
	if (@send) {
	    my @message_loop;
	    my $link = $mgr->my_url;
	    $link .= "&method=%s&mid=%s";

	    for (my $i = 0; $i <= $#send; $i++) {
		# Alle Empfaenger bestimmen
		my @uid = $self->{BASE}->fetch_receiver($send[$i][0]);
		# Name des ersten Empfaengers ermitteln
		my @user = $self->{BASE}->get_user($uid[0]);
		$message_loop[$i]{MESSAGE_1ST_RECEIVER}  =
		    $mgr->decode_all(sprintf("%s %s (%s)", $user[0], $user[1], $user[2]));

		if($#uid > 0) {
		    $message_loop[$i]{MESSAGE_RECEIVER_COUNT} = $mgr->decode_all(sprintf("[1/%d]",$#uid+1));
		}
		$message_loop[$i]{MESSAGE_LINK}    = $mgr->decode_all(sprintf($link, "show_send_message",$send[$i][0]));
		$message_loop[$i]{MESSAGE_SUBJECT} = $mgr->decode_all($send[$i][2]);
		$message_loop[$i]{MESSAGE_DATE}    = $mgr->decode_all($mgr->format_date($send[$i][1]));
	    }

	    $mgr->{TmplData}{MESSAGE_LOOP} = \@message_loop;
	    
	    # Es gibt genau eine Nachricht
	    if ($#send == 0) {
		$message_status = $C_MSG->{SendMessage};
	    } else {
		# Es gibt mehrere Nachrichten
		$message_status = sprintf($C_MSG->{SendMessages},$#send+1);
		
	    }
	} else {
	    # Es gibt keine Nachricht
	    $message_status = $C_MSG->{SendEmpty};
	}
	
	$mgr->{TmplData}{MESSAGE_STATUS} = $message_status;
	
	$self->fill_nav();

        $mgr->fill; 

	return 1;
}


#====================================================================================================#
# SYNOPSIS: show_message();
# PURPOSE:  Detailansicht einer empfangenen Nachricht
# RETURN:   1
#====================================================================================================#
sub show_message {

    my $self = shift;

    my $mgr = $self->{MGR};

    my $cgi = $mgr->{CGI};
    my $mid = $cgi->param('mid');

    my $link = $mgr->my_url;
    
    # gewuenschte Messages holen
    # Die Nachricht besteht aus (mid,from_uid,to_uid,parent_mid,status,date,subject,content)
    my @message = $self->{BASE}->get_message($mid);
    if ($message[4] eq '0') {
	$self->{BASE}->set_message_status($mid,1);
    }
    # MessageShow-Template vorbereiten
    $mgr->{Template} = $C_TMPL->{MessageShow};
    
    # Message bezieht sich auf eine Parent-Message
    unless ($message[3] == 0) {
	$link .= "&method=%s&mid=%s";
	my @parent_send = $self->{BASE}->get_send_message($message[3]);
	my @parent = $self->{BASE}->get_message($message[3]);
	if (@parent_send) {
	    $mgr->{TmplData}{PARENT_LINK} = sprintf($link, "show_send_message", $message[3]);
	    $mgr->{TmplData}{PARENT_SUBJECT} =  $mgr->decode_all($parent_send[3]);
	} elsif (@parent) {
	    $mgr->{TmplData}{PARENT_LINK} = sprintf($link, "show_message", $message[3]);
	    $mgr->{TmplData}{PARENT_SUBJECT} =  $mgr->decode_all($parent[6]);
	} 
    }

    $mgr->{TmplData}{MESSAGE_DATE} = $mgr->format_date($message[5]);

    # Namen des Absenders bestimmen
    my @user = $self->{BASE}->get_user($message[1]);
    $mgr->{TmplData}{MESSAGE_SENDER} =
	$mgr->decode_all(sprintf("%s %s (%s)", $user[0], $user[1], $user[2]));

    $mgr->{TmplData}{MESSAGE_SUBJECT} = $mgr->decode_all($message[6]);
    $mgr->{TmplData}{MESSAGE_CONTENT} = $mgr->decode_all($message[7]);
    $link = $mgr->my_url;
    $link .= "&method=%s&parent_mid=%s";
    $mgr->{TmplData}{MESSAGE_REPLY} = sprintf($link, "compose_message", $message[0]);

    $self->fill_nav;

    $mgr->fill;

    return 1;
}

#====================================================================================================#
# SYNOPSIS: show_send_message([$mid]);
# PURPOSE:  Detailansicht einer versandten Nachricht, $mid optional
# RETURN:   1
#====================================================================================================#
sub show_send_message {

    my $self = shift;
    my $mgr = $self->{MGR};

    my $cgi = $mgr->{CGI};
 
    my $mid = $cgi->param('mid') || shift;

    my $link = $mgr->my_url;
    
    # gewuenschte Messages holen
    # Die Nachricht besteht aus (id,parent_mid,date,subject,content)
    my @message = $self->{BASE}->get_send_message($mid);

    # MessageShow-Template vorbereiten
    $mgr->{Template} = $C_TMPL->{MessageShow};
    
    # Message bezieht sich auf eine Parent-Message

    # Message bezieht sich auf eine Parent-Message
    unless ($message[1] == 0) {
	$link .= "&method=%s&mid=%s";
	my @parent_send = $self->{BASE}->get_send_message($message[1]);
	my @parent = $self->{BASE}->get_message($message[1]);
	if (@parent_send) {
	    $mgr->{TmplData}{PARENT_LINK} = sprintf($link, "show_send_message", $message[3]);
	    $mgr->{TmplData}{PARENT_SUBJECT} =  $mgr->decode_all($parent_send[3]);
	} elsif (@parent) {
	    $mgr->{TmplData}{PARENT_LINK} = sprintf($link, "show_message", $message[3]);
	    $mgr->{TmplData}{PARENT_SUBJECT} =  $mgr->decode_all($parent[6]);
	} 
    }

    $mgr->{TmplData}{MESSAGE_DATE} = $mgr->format_date($message[2]);

    # Alle Empfaenger bestimmen
    my @uid = $self->{BASE}->fetch_receiver($message[0]);
    # ...HIER FEHLT NOCH WAS


    $mgr->{TmplData}{MESSAGE_SUBJECT} = $mgr->decode_all($message[3]);
    $mgr->{TmplData}{MESSAGE_CONTENT} = $mgr->decode_all($message[4]);
    $link = $mgr->my_url;
    $link .= "&method=%s&parent_mid=%s";
    $mgr->{TmplData}{MESSAGE_REPLY} = sprintf($link, "compose_message", $message[0]);

    $self->fill_nav;

    $mgr->fill;

    return 1;
}


#====================================================================================================#
# SYNOPSIS: compose_message();
# PURPOSE:  Neue Nachrichten verfassen, d.h. Formular erzeugen
# RETURN:   ---
#====================================================================================================#
sub compose_message {
    
    my $self = shift;
    
    my $mgr = $self->{MGR};
    my $cgi = $self->{MGR}->{CGI};
 
    my $uid = $cgi->param('uid');
    my $parent_mid = $mgr->{Session}->get("ParentMid") || $cgi->param('parent_mid') || 0;
    my $to_usernames = $cgi->param('to_usernames') || "";
    my $subject = $mgr->{Session}->get("Subject") || $cgi->param('subject') || "";
    my $content = $mgr->{Session}->get("Content") || $cgi->param('content') || "";

    # MessageNew-Template (Formular) vorbereiten
    $mgr->{Template} = $C_TMPL->{MessageForm};

    $mgr->{TmplData}{FORM} = $mgr->my_url;
    $mgr->{TmplData}{TO_USERNAMES} = $mgr->decode_some($to_usernames);
    $mgr->{TmplData}{MESSAGE_SUBJECT} = $mgr->decode_some($subject);
    $mgr->{TmplData}{MESSAGE_CONTENT} = $mgr->decode_some($content);
    $mgr->{TmplData}{PARENT_MID} = $mgr->decode_some($parent_mid);
    if ($parent_mid != 0) {
	$mgr->{TmplData}{ANSWERMODE} = 1;
    }

    $self->fill_nav;

    $mgr->fill;

    return 1;

}


#====================================================================================================#
# SYNOPSIS: choose_receivers();
# PURPOSE:  Auswahl der Empfaenger
# RETURN:   ---
#====================================================================================================#
sub choose_receivers {
    my $self = shift;

    my $mgr = $self->{MGR};
    my $cgi = $self->{MGR}->{CGI};

    my $grp = $cgi->param('grp') || 'textfield';
    my $parent_mid = $cgi->param('parent_mid') || 0;
    my $subject = $cgi->param('subject') || "";
    my $content = $cgi->param('content') || "";

    # Message in die Session schreiben
    $mgr->{Session}->set(ParentMid => $parent_mid,
			 Subject => $subject,
			 Content => $content);

    # MessageChooseRecv-Template vorbereiten
    $mgr->{Template} = $C_TMPL->{MessageChooseRecv};

    my @group_loop;
    my @members_loop;

    my $link = $mgr->my_url;
    $link .= "&%s=&grp=%s";

    # statische Gruppen, z.B. Textfield, Alle User, ... etc.
    my @default_groups;
    $default_groups[0] = ['textfield','Textfield'];
    $default_groups[1] = ['all','All Users'];

    foreach my $group (@default_groups) {
	my %tmp;
	$tmp{GROUP_LINK} = $mgr->decode_all(sprintf($link, "choose_receivers",$group->[0]));
	$tmp{GROUP_NAME} = $mgr->decode_all($group->[1]);
	push(@group_loop,\%tmp);
	# diese Gruppe wurde angewaehlt
	if ($grp eq $group->[0]) {
	    $mgr->{TmplData}{GROUP} = $group->[1];
	}
    }	

    # Projektgruppen kommen dazu
    my @groups = $self->{BASE}->fetch_projects();
    # Es wurden Projekte gefunden
    if (@groups) {	
	foreach my $group (@groups) {
	    my %tmp;
	    $tmp{GROUP_LINK} = $mgr->decode_all(sprintf($link, "choose_receivers",$group->[0]));
	    $tmp{GROUP_NAME} = $mgr->decode_all($group->[1]);
	    push(@group_loop,\%tmp);
	    # diese Gruppe wurde angewaehlt
	    if ($grp eq $group->[0]) {
		$mgr->{TmplData}{GROUP} = $group->[1];
	    }
	}

    }

    # Gruppen zur Auswahl anbieten
    $mgr->{TmplData}{GROUPS_LOOP} = \@group_loop;

    # IDs der Gruppenmitglieder bestimmen
    my $members = undef;

    if ($grp eq 'textfield') {
	# User aus dem Textfeld
	my $to_usernames = $cgi->param('to_usernames') || "";
	# Whitespaces entfernen, Kommaliste trennen
	$to_usernames =~ s/\s+//gs;
	my @usernames = split /,+/, $to_usernames;
	$members = $self->{BASE}->fetch_uids(\@usernames);
    } elsif ($grp eq 'all') {
	$members = $self->{BASE}->fetch_users(1);
    } else {
	$members = $self->{BASE}->fetch_project_members($grp);
    }

    # Jedes Mitglied kommt in den Loop
    if (@$members) {
	foreach my $member (@$members) {
	    my %tmp;
	    # Namen des Mitglieds bestimmen
	    my @user = $self->{BASE}->get_user($member);
	    $tmp{MEMBER_NAME} =
		$mgr->decode_all(sprintf("%s %s (%s)", $user[0], $user[1], $user[2]));
	    $tmp{MEMBER_LINK} = $mgr->decode_all(sprintf($link, "add_receivers",$member));

	    push(@members_loop,\%tmp);
	}

	# Gruppenmitglieder anzeigen
	$mgr->{TmplData}{MEMBERS_LOOP} = \@members_loop;
    }

    $self->fill_nav;
    
    $mgr->fill;
    
    return 1;
}





#====================================================================================================#
# SYNOPSIS: send_message();
# PURPOSE:  Neue Nachricht in den Tables ablegen
# RETURN:   ---
#====================================================================================================#
sub send_message {
 
        my $self = shift;

        my $mgr = $self->{MGR};
        my $cgi = $self->{MGR}->{CGI};

        my @uid = $cgi->param('uid') || undef;
	my $to_usernames = $cgi->param('to_usernames') || "";
	my $parent_mid = $cgi->param('parent_mid') || 0;
        my $subject = $cgi->param('subject') || "no subject";
        my $content = $cgi->param('content') || "no content";

	# Whitespaces entfernen, Kommaliste trennen
	$to_usernames =~ s/\s+//gs;
	my @usernames = split /,+/, $to_usernames;
	my $id = $self->{BASE}->fetch_uids(\@usernames);
	my $mid = $self->{BASE}->insert_new_messages($id, $parent_mid, $subject, $content);

	# gleich ansehen
	show_send_message($self,$mid);

	return 1;
}



#====================================================================================================#
# SYNOPSIS: fill_nav;
# PURPOSE:  Navigation des Message-Systems vorbereiten
# RETURN:   ---
#====================================================================================================#
sub fill_nav {
    my $self = shift;
    
    my $mgr = $self->{MGR};
    my $link = $mgr->my_url;

    # Message-Navigation vorbereiten
    $link .= "&method=%s";
    $mgr->{TmplData}{NAV_INBOX}    = sprintf($link,"inbox");
    $mgr->{TmplData}{NAV_RECEIVED} = sprintf($link,"received");
    $mgr->{TmplData}{NAV_SEND}     = sprintf($link,"send");
    $mgr->{TmplData}{NAV_COMPOSE}  = sprintf($link,"compose_message");
    return;
}

1;
# end of file
