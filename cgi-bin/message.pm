package message;

use Class::Date qw(date);
use Class::Singleton;
use base 'Class::Singleton';
use message_base;
use message_config;
use vars qw($VERSION $C_MSG $C_TMPL);
use strict;

$VERSION = sprintf "%d.%03d", q$Revision: 1.12 $ =~ /(\d+)\.(\d+)/;

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
	} elsif (defined $cgi->param('delete_message')) {
	    $self->delete_message();
	    return 1;
	} elsif (defined $cgi->param('reply')) {
	    $self->compose_message();
	    return 1;
	} elsif (defined $cgi->param('choose_receivers')) {
	    $self->choose_receivers();
	    return 1;
	} elsif (defined $cgi->param('back')) {
	    $self->compose_message();
	    return 1;
	} elsif (defined $cgi->param('add_recv_users')) {
	    $self->add_recv_users();
	    return 1;
	} elsif (defined $cgi->param('add_recv_project')) {
	    $self->add_recv_project();
	    return 1;
	} elsif (defined $cgi->param('remove_recv_users')) {
	    $self->remove_recv_users();
	    return 1;
	}
    }

    # default
    $self->view_messages(0); # Uebersicht der Inbox-Messages anzeigen
}


#====================================================================================================#
# SYNOPSIS: view_messages($status,$msg);
# PURPOSE:  Uebersicht der empfangenen Nachrichten ($status=0 Inbox, $status=1 Received)
# RETURN:   1
#====================================================================================================#
sub view_messages {

        my $self = shift;
	my $status = shift || 0;
	my $msg = shift || undef;
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

	if (defined $msg) {
	    $mgr->fill($msg);
	} else {
	    $mgr->fill();
	}

	return 1;
}


#====================================================================================================#
# SYNOPSIS: view_send_messages($msg);
# PURPOSE:  Uebersicht der abgesandten Nachrichten
# RETURN:   1
#====================================================================================================#
sub view_send_messages {

        my $self = shift;
	my $msg = shift || undef;

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

	if (defined $msg) {
	    $mgr->fill($msg);
	} else {
	    $mgr->fill();
	}

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
    my $modus = 'received';
    # gewuenschte Messages holen
    # Die Nachricht besteht aus (mid,from_uid,to_uid,parent_mid,status,date,subject,content)
    my @message = $self->{BASE}->get_message($mid);
    if ($message[4] eq '0') {
	$self->{BASE}->set_message_status($mid,1);
	$modus = 'inbox';
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


    # Alle Empfaenger anzeigen
    my @receiver_loop;
    my @receivers = $self->{BASE}->fetch_receiver($mid);
    if (@receivers) {
	foreach my $uid (@receivers) {
	    my %tmp;
	    # Namen des Mitglieds bestimmen
	    my @user = $self->{BASE}->get_user($uid);
	    $tmp{RECEIVER_NAME} =
		$mgr->decode_all(sprintf("%s %s (%s)", $user[0], $user[1], $user[2]));
	    push(@receiver_loop,\%tmp);
	}
	$mgr->{TmplData}{MESSAGE_RECEIVERS_LOOP} = \@receiver_loop;
    }

    # Namen des Absenders bestimmen
    my @user = $self->{BASE}->get_user($message[1]);
    $mgr->{TmplData}{MESSAGE_SENDER} =
	$mgr->decode_all(sprintf("%s %s (%s)", $user[0], $user[1], $user[2]));
    
    $mgr->{TmplData}{MESSAGE_SUBJECT} = $mgr->decode_all($message[6]);
    $mgr->{TmplData}{MESSAGE_CONTENT} = $mgr->decode_all($message[7]);
    $mgr->{TmplData}{FORM} = $mgr->my_url;
    $mgr->{TmplData}{PARENT_MID} = $message[0];
    $mgr->{TmplData}{MID} = $mid;

    # Unterscheidung zwischen empfangenen und gelesenen Nachrichten
    $mgr->{TmplData}{MODUS} = $modus;

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
     my $modus = 'send';
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
	    $mgr->{TmplData}{PARENT_LINK} = sprintf($link, "show_send_message", $message[1]);
	    $mgr->{TmplData}{PARENT_SUBJECT} =  $mgr->decode_all($parent_send[3]);
	} elsif (@parent) {
	    $mgr->{TmplData}{PARENT_LINK} = sprintf($link, "show_message", $message[1]);
	    $mgr->{TmplData}{PARENT_SUBJECT} =  $mgr->decode_all($parent[6]);
	} 
    }

    $mgr->{TmplData}{MESSAGE_DATE} = $mgr->format_date($message[2]);

    # Alle Empfaenger anzeigen
    my @receiver_loop;
    my @receivers = $self->{BASE}->fetch_receiver($mid);
    if (@receivers) {
	foreach my $uid (@receivers) {
	    my %tmp;
	    # Namen des Mitglieds bestimmen
	    my @user = $self->{BASE}->get_user($uid);
	    $tmp{RECEIVER_NAME} =
		$mgr->decode_all(sprintf("%s %s (%s)", $user[0], $user[1], $user[2]));
	    push(@receiver_loop,\%tmp);
	}
	$mgr->{TmplData}{MESSAGE_RECEIVERS_LOOP} = \@receiver_loop;
    }


    $mgr->{TmplData}{MESSAGE_SUBJECT} = $mgr->decode_all($message[3]);
    $mgr->{TmplData}{MESSAGE_CONTENT} = $mgr->decode_all($message[4]);
    $mgr->{TmplData}{FORM} = $mgr->my_url;
    $mgr->{TmplData}{PARENT_MID} = $message[0];
    $mgr->{TmplData}{MID} = $mid;
    # Unterscheidung zwischen empfangenen und gelesenen Nachrichten
    $mgr->{TmplData}{MODUS} = $modus;

    $self->fill_nav;

    $mgr->fill;

    return 1;
}


#====================================================================================================#
# SYNOPSIS: delete_message();
# PURPOSE:  Nachricht loeschen, dann wieder zur Uebersicht
# RETURN:   ---
#====================================================================================================#
sub delete_message {
    
    my $self = shift;
    
    my $mgr = $self->{MGR};
    my $cgi = $self->{MGR}->{CGI};
    my $modus = $cgi->param('modus') || undef;
    my $mid = $cgi->param('mid') || undef;
    unless (defined $modus) {
	$self->view_messages(0);
    }
    if ($modus eq 'received') {
	$self->{BASE}->delete_received_message($mid);
	$self->view_messages(1,$C_MSG->{MessageDeleted});
    } elsif ($modus eq 'inbox') {
	$self->{BASE}->delete_received_message($mid);
	$self->view_messages(0,$C_MSG->{MessageDeleted});
    } else {
	# $modus eq 'send'
	$self->{BASE}->delete_send_message($mid);
	$self->view_send_messages($C_MSG->{MessageDeleted});
    }
    
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
 
    my $parent_mid = $mgr->{Session}->get("ParentMid") || $cgi->param('parent_mid') || 0;
    my $to_usernames = $mgr->{Session}->get("ToUsernames") || "";
    my $subject = $mgr->{Session}->get("Subject") || $cgi->param('subject') || "";
    my $content = $mgr->{Session}->get("Content") || $cgi->param('content') || "";
    my $answermode_sender = $mgr->{Session}->get("AnswerModeSender") || 0;
    my $answermode_all = $mgr->{Session}->get("AnswerModeAll") || 0;
    $mgr->{Session}->del("AnswerModeSender");
    $mgr->{Session}->del("AnswerModeAll");


    my @recv = $cgi->param('recv');
    if (@recv) {
	my @usernames;
	foreach my $uid (@recv) {
	    my @user = $self->{BASE}->get_user($uid);
	    push(@usernames, $user[2]);
	}
	$to_usernames = join(',',@usernames);
    }

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

    if ($answermode_sender == 1) {
	$mgr->{TmplData}{SENDER_CHECKED} = 1;
    }
    if ($answermode_all == 1) {
	$mgr->{TmplData}{ALL_CHECKED} = 1;
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

    my $msg = shift || undef;
    my $recv_ids = shift || undef;

    my $mgr = $self->{MGR};
    my $cgi = $self->{MGR}->{CGI};
    
    my $parent_mid = $cgi->param('parent_mid') || 0;
    my $subject = $cgi->param('subject') || "";
    my $content = $cgi->param('content') || "";
    my $to_usernames = $cgi->param('to_usernames') || "";
    my $answermode_all = $cgi->param('answermode_all') || 0;
    my $answermode_sender = $cgi->param('answermode_sender') || 0;

    # Whitespaces entfernen, Kommaliste trennen
    $to_usernames =~ s/\s+//gs;
    my @usernames = split /,+/, $to_usernames;
    my $id = $self->{BASE}->fetch_uids(\@usernames) || undef;

    # Message in die Session schreiben
    $mgr->{Session}->set('ParentMid' => $parent_mid,
			 'ToUsernames' => $to_usernames,
			 'Subject' => $subject,
			 'Content' => $content,
			 'AnswerModeAll' => $answermode_all,
			 'AnswerModeSender' => $answermode_sender);

    my $check = $self->{BASE}->check_usernames(\@usernames) || undef;
    my @check_loop;
    foreach my $username (@$check) {
	my %tmp;
	$tmp{USERNAME} = $mgr->decode_all($username);
	push(@check_loop,\%tmp);
    }
    if (@$check) {
	$mgr->{TmplData}{CHECK_USERNAME} = \@check_loop;
	$self->compose_message();
	return;
    }


    # MessageChooseRecv-Template vorbereiten
    $mgr->{Template} = $C_TMPL->{MessageChooseRecv};
   
    my $link = $mgr->my_url;
    
    # Anzeige der Empfaenger
    my @recv_loop;
    my @recv;

    if (defined $id) {
	push(@recv, @$id);
    }
    if (defined $recv_ids) {
	push(@recv, @$recv_ids);
    }

    my @recv_new;
    my $count;
    foreach my $uid (@recv) {
	$count = grep { $uid == $_} @recv_new;
	if ($count == 0) {
	    push (@recv_new,$uid);
	}
    }

    # Jedes Mitglied kommt in den Loop
    if (@recv_new) {
	foreach my $uid (@recv_new) {
	    my %tmp;
	    # Namen des Mitglieds bestimmen
	    my @user = $self->{BASE}->get_user($uid);
	    $tmp{RECV_NAME} =
		$mgr->decode_all(sprintf("%s %s (%s)", $user[0], $user[1], $user[2]));
	    $tmp{RECV_UID} = $mgr->decode_all($uid);

	    push(@recv_loop,\%tmp);
	}
    }

    $mgr->{TmplData}{RECV_LOOP} = \@recv_loop;


    # Auswahl der Benutzer
    my @type_ab_loop;
    my @type_c_loop;
    my @type_d_loop;

    # Auswahl des A_User
    # fetcht aktive Typ-A Benutzer
    my $a_user = $self->{BASE}->fetch_users(1,'A');
    if (@$a_user) {
	foreach my $uid (@$a_user) {
	    my $count = grep { $uid == $_} @recv_new;
	    if ($count == 0) {
		my %tmp;
		# Namen des A bestimmen
		my @user = $self->{BASE}->get_user($uid);
		$tmp{RECV_NAME} =
		    $mgr->decode_all(sprintf("%s %s (%s)", $user[0], $user[1], $user[2]));
		$tmp{RECV_UID} = $mgr->decode_all($uid);

		push(@type_ab_loop,\%tmp);
	    }
	}
    }

    # Auswahl der B_User
    # fetcht aktive Typ-B Benutzer
    my $b_users = $self->{BASE}->fetch_users(1,'B');
    # Jedes Mitglied kommt in den Loop
    if (@$b_users) {
	foreach my $uid (@$b_users) {
	    my $count = grep { $uid == $_} @recv_new;
	    if ($count == 0) {
		my %tmp;
		# Namen des Benutzers bestimmen
		my @user = $self->{BASE}->get_user($uid);
		$tmp{RECV_NAME} =
		    $mgr->decode_all(sprintf("%s %s (%s)", $user[0], $user[1], $user[2]));
		$tmp{RECV_UID} = $mgr->decode_all($uid);

		push(@type_ab_loop,\%tmp);
	    }
	}

	# Gruppenmitglieder anzeigen
	$mgr->{TmplData}{TYPE_AB_LOOP} = \@type_ab_loop;
    }

    # Auswahl der C_User
    # fetcht aktive Typ-C Benutzer
    my $c_users = $self->{BASE}->fetch_users(1,'C');
    # Jedes Mitglied kommt in den Loop
    if (@$c_users) {
	foreach my $uid (@$c_users) {
	    my $count = grep { $uid == $_} @recv_new;
	    if ($count == 0) {
		my %tmp;
		# Namen des Benutzers bestimmen
		my @user = $self->{BASE}->get_user($uid);
		$tmp{RECV_NAME} =
		    $mgr->decode_all(sprintf("%s %s (%s)", $user[0], $user[1], $user[2]));
		$tmp{RECV_UID} = $mgr->decode_all($uid);
		
		push(@type_c_loop,\%tmp);
	    }
	}

	# Gruppenmitglieder anzeigen
	$mgr->{TmplData}{TYPE_C_LOOP} = \@type_c_loop;
    }


    # Auswahl der D_User
    # fetcht aktive Typ-D Benutzer
    my $d_users = $self->{BASE}->fetch_users(1,'D');
    # Jedes Mitglied kommt in den Loop
    if (@$d_users) {
	foreach my $uid (@$d_users) {
	    my $count = grep { $uid == $_} @recv_new;
	    if ($count == 0) {
		my %tmp;
		# Namen des Benutzers bestimmen
		my @user = $self->{BASE}->get_user($uid);
		$tmp{RECV_NAME} =
		    $mgr->decode_all(sprintf("%s %s (%s)", $user[0], $user[1], $user[2]));
		$tmp{RECV_UID} = $mgr->decode_all($uid);
		
		push(@type_d_loop,\%tmp);
	    }
	}

	# Gruppenmitglieder anzeigen
	$mgr->{TmplData}{TYPE_D_LOOP} = \@type_d_loop;
    }

    # Auswahl der Projekte
    my @project_loop;

    my @projects = $self->{BASE}->fetch_projects();
    # Es wurden Projekte gefunden
    if (@projects) {	
	foreach my $project (@projects) {
	    my %tmp;
	    $tmp{PROJECT_ID} = $project->[0];
	    $tmp{PROJECT_NAME} = $mgr->decode_all($project->[1]);
	    $tmp{CATEGORY} = $mgr->decode_all($project->[2]);
	    push(@project_loop,\%tmp);
	}
    }

    $mgr->{TmplData}{PROJECT_LOOP} = \@project_loop;



    $mgr->{TmplData}{FORM} = $mgr->my_url();

    if (defined $msg) {
	$mgr->fill($msg);
    } else {
	$mgr->fill();
    }

    return;
}



#====================================================================================================#
# SYNOPSIS: add_recv_users();
# PURPOSE:  Hinzufuegen der Empfaenger
# RETURN:   ---
#====================================================================================================#
sub add_recv_users {
    my $self = shift;

    my $mgr = $self->{MGR};
    my $cgi = $self->{MGR}->{CGI};

    my @uid = $cgi->param('user');
    my @recv = $cgi->param('recv');
    my $users = undef;
    foreach my $id (@uid) {
	unless ($id == 0) {
	    push(@$users,$id);
	}
    }
  if (defined $users) {
	push(@recv, @$users);
	my @u = @$users;
	$self->choose_receivers(sprintf($C_MSG->{UsersAdded},1 + $#u),\@recv);
    } else {
	$self->choose_receivers($C_MSG->{NoSelection},\@recv);
    }
}

#====================================================================================================#
# SYNOPSIS: add_recv_project();
# PURPOSE:  Hinzufuegen eines Projektes
# RETURN:   ---
#====================================================================================================#
sub add_recv_project {
    my $self = shift;

    my $mgr = $self->{MGR};
    my $cgi = $self->{MGR}->{CGI};

    my $pid = $cgi->param('project') || 0;
    my @recv = $cgi->param('recv');
    if ($pid == 0) {
	$self->choose_receivers($C_MSG->{NoSelection},\@recv);
    } else {
	my $members = $self->{BASE}->fetch_project_members($pid);
	my $name = $self->{BASE}->get_project_name($pid);
	$members = [1,2,3,4];
	push(@recv, @$members);
	$self->choose_receivers(sprintf($C_MSG->{ProjectAdded},$name),\@recv);
    }
}



#====================================================================================================#
# SYNOPSIS: remove_recv_users();
# PURPOSE:  Entfernen von Empfaengern
# RETURN:   ---
#====================================================================================================#
sub remove_recv_users {
    my $self = shift;

    my $mgr = $self->{MGR};
    my $cgi = $self->{MGR}->{CGI};
    my @remove = $cgi->param('remove_receivers');
    my @recv = $cgi->param('recv');
    if (@remove) {
	my @recv_new;
	my $count;
	foreach my $uid (@recv) {
	    $count = grep { $uid == $_} @remove;
	    if ($count == 0) {
		push (@recv_new,$uid);
	    }
	}
	$self->choose_receivers(sprintf($C_MSG->{UsersRemoved},1+$#remove),\@recv_new);
    } else {
	$self->choose_receivers($C_MSG->{NoSelection},\@recv);
    }
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

	my $parent_mid        = $cgi->param('parent_mid')   || 0;
	my $to_usernames      = $cgi->param('to_usernames') || "";
	my $subject           = $cgi->param('subject')      || "kein Betreff";
	my $content           = $cgi->param('content')        || "kein Text";
	my $answermode_all    = $cgi->param('answermode_all') || 0;
	my $answermode_sender = $cgi->param('answermode_sender') || 0;

	if ($answermode_all == 0 && $answermode_sender == 0 && $to_usernames eq "") {
	    $mgr->{TmplData}{NO_RECEIVER} = $mgr->decode_all($C_MSG->{NoReceiver});
	    # Message in die Session schreiben
	    $mgr->{Session}->set('ParentMid' => $parent_mid,
				 'ToUsernames' => $to_usernames,
				 'Subject' => $subject,
				 'Content' => $content,
				 'AnswerModeAll' => $answermode_all,
				 'AnswerModeSender' => $answermode_sender);
	    $self->compose_message();
	    return 1;
	}


	# Whitespaces entfernen, Kommaliste trennen
	$to_usernames =~ s/\s+//gs;
	my @usernames = split /,+/, $to_usernames;
	my $id = $self->{BASE}->fetch_uids(\@usernames);

	my $check = $self->{BASE}->check_usernames(\@usernames) || undef;
	my @check_loop;
	foreach my $username (@$check) {
	    my %tmp;
	    $tmp{USERNAME} = $mgr->decode_all($username);
	    push(@check_loop,\%tmp);
	}
	if (@$check) {
	    $mgr->{TmplData}{CHECK_USERNAME} = \@check_loop;

	    # Message in die Session schreiben
	    $mgr->{Session}->set('ParentMid' => $parent_mid,
				 'ToUsernames' => $to_usernames,
				 'Subject' => $subject,
				 'Content' => $content,
				 'AnswerModeAll' => $answermode_all,
				 'AnswerModeSender' => $answermode_sender);

	    $self->compose_message();
	    return;
	}



	if ($answermode_sender == 1) {
	    # empfangene Parent-Message holen
	    my @message = $self->{BASE}->get_message($parent_mid);
	    # Es existiert eine Message
	    if (@message) {
		# Sender ermitteln
		my $sender_id = $message[1];
		my $count = grep { $sender_id == $_} @$id;
		# Sender ist noch nicht in der Liste der Empfaenger
		if ($count == 0) {
		    push(@$id, $sender_id);
		}
	    }
	}

	if ($answermode_all == 1) {
	    # Alle Empfaenger bestimmen
	    my @all = $self->{BASE}->fetch_receiver($parent_mid);
	    # Es gibt Empfaenger
	    if (@all) {
		foreach my $uid (@all) {
		    my $count = grep { $uid == $_} @$id;
		    # Empfaenger der Parent_message ist noch nicht in der Liste der Empfaenger
		    if ($count == 0) {
			push(@$id, $uid);
		    }
		}
	    }
	}

	my $mid = $self->{BASE}->insert_new_messages($id, $parent_mid, $subject, $content);


	$mgr->{Session}->del("ParentMid");
	$mgr->{Session}->del("ToUsernames");
	$mgr->{Session}->del("Subject");
	$mgr->{Session}->del("Content");
	$mgr->{Session}->del("AnswerModeSender");
	$mgr->{Session}->del("AnswerModeAll");

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





















