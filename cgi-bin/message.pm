package message;

use Class::Singleton;
use base 'Class::Singleton';
use message_base;
use message_config;
use vars qw($VERSION $C_MSG $C_TMPL);

use strict;

$VERSION = sprintf "%d.%03d", q$Revision: 1.15 $ =~ /(\d+)\.(\d+)/;

$C_MSG  = $message_config::MSG;
$C_TMPL = $message_config::TMPL;

#====================================================================================================#
# SYNOPSIS: parameter
# PURPOSE:  Manager des Nachrichtenmoduls, angelehnt an 'parameter' in 'project.pm'
# RETURN:   1
#====================================================================================================#
sub parameter {
    
    my $self = shift;
    my $mgr  = shift;
    
    $self->{MGR} = $mgr;
    $mgr->{MyUrl} = $mgr->my_url;   

    my $cgi    = $mgr->{CGI};

    # Methode bestimmen
    my $method = $cgi->param('method') || undef;

    # Instanz von message_base erzeugen
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


    # existiert eine Methode?
    if (defined $method) {

	if ($method eq 'inbox') {
	    # Uebersicht der neuen empfangenen Nachrichten
	    $self->view_messages(0);
	    return 1;

	} elsif ($method eq 'received') {
	    # Uebersicht der bereits bekannten empfangenen Nachrichten
	    $self->view_messages(1);
	    return 1;

	} elsif ($method eq "send") {
	    # Uebersicht der versandten Nachrichten
	    $self->view_send_messages();
	    return 1;

	} elsif ($method eq "compose_message") {
	    # Eingabeformular zum Verfassen einer neuen Nachricht
	    $self->compose_message();
	    return 1;

	} elsif ($method eq "show_message") {
	    # Ausfuehrliche Einzelansicht einer empfangenen Nachricht
	    $self->show_message();
	    return 1;

	} elsif ($method eq "show_send_message") {
	    # Ausfuehrliche Einzelansicht einer versandten Nachricht
	    $self->show_send_message();
	    return 1;
	}
    }

    # Kommandos ohne eigene Methode
    else {

	if (defined $cgi->param('send_message')) {
	    # Nachricht versenden, Daten in die mySQL-Datenbank eintragen
	    $self->send_message();
	    return 1;

	} elsif (defined $cgi->param('delete_message')) {
	    # Nachricht loeschen
	    $self->delete_message();
	    return 1;

	} elsif (defined $cgi->param('reply')) {
	    # Eine Antwort auf die gerade gelesene Nachricht verfassen
	    $self->compose_message();
	    return 1;

	} elsif (defined $cgi->param('choose_receivers')) {
	    # Auswahl der Empfaenger beim Verfassen einer Nachricht
	    $self->choose_receivers();
	    return 1;

	} elsif (defined $cgi->param('back')) {
	    # Auswahl der Empfaenger beendet, zurueck zum Formular
	    $self->compose_message();
	    return 1;

	} elsif (defined $cgi->param('add_recv_users')) {
	    # Auswahl der Empfaenger, Benutzer hinzufuegen
	    $self->add_recv_users();
	    return 1;

	} elsif (defined $cgi->param('add_recv_project')) {
	    # Auswahl der Empfaenger, Projektmitglieder hinuzufuegen
	    $self->add_recv_project();
	    return 1;

	} elsif (defined $cgi->param('remove_recv_users')) {
	    # Auswahl der Empfaenger
	    $self->remove_recv_users();
	    return 1;
	}
    }
    
    # Startseite des Nachrichtensystems,
    # wie oben: $method eq 'inbox'

    # Uebersicht der neuen empfangenen Nachrichten
    $self->view_messages(0);

    return 1;
}


#====================================================================================================#
# SYNOPSIS: view_messages($status,$msg);
# PURPOSE:  Uebersicht der empfangenen Nachrichten anzeigen
# RETURN:   1
#====================================================================================================#
sub view_messages {

        my $self   = shift;

	# status 0: neue Nachrichten (inbox) , status 1: bekannte Nachrichten (received)
	my $status = shift || 0;
	# Meldung im Header-Template
	my $msg    = shift || undef;

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

	    # Verlinkung mit URL, Methode und Message-ID
	    my $link = $mgr->my_url;
	    $link .= "&method=%s&mid=%s";

	    # Fuer jede Nachricht Absender, Betreff, Datum und Verlinkung darstellen
	    for (my $i = 0; $i <= $#received; $i++) {

		# Namen des Absenders mittels uid bestimmen (firstname,lastname,username)
		@user = $self->{BASE}->get_user($received[$i][1]);

		# Vor-, Nach- und  Benutzername des Absenders
		$message_loop[$i]{MESSAGE_SENDER}  =
		    $mgr->decode_all(sprintf("%s %s (%s)", $user[0], $user[1], $user[2]));

		# Verlinkung der Einzelansicht ueber Message-ID
		$message_loop[$i]{MESSAGE_LINK}    =
		    $mgr->decode_all(sprintf($link, "show_message", $received[$i][0]));

		# Betreff der Nachricht
		$message_loop[$i]{MESSAGE_SUBJECT} = $mgr->decode_all($received[$i][3]);

		# Absendedatum der Nachricht
		$message_loop[$i]{MESSAGE_DATE}    = $mgr->decode_all($mgr->format_date($received[$i][2]));
	    }

	    # Alle Empfangenen Nachrichten in Kurzdarstellung fuer das Template
	    $mgr->{TmplData}{MESSAGE_LOOP} = \@message_loop;


	    # Statusmeldung erzeugen, je nach Status und Anzahl der Nachrichten

	    # Es gibt genau eine Nachricht
	    if ($#received == 0) {
		if ($status == 0) {
		    $message_status = $C_MSG->{InboxMessage};    # neu
		} else {
		    $message_status = $C_MSG->{ReceivedMessage}; # gelesen
		}
	    } else {
		# Es gibt mehrere Nachrichten
		if ($status == 0) {
		    $message_status = sprintf($C_MSG->{InboxMessages},$#received+1);    # neu
		} else {
		    $message_status = sprintf($C_MSG->{ReceivedMessages},$#received+1); # gelesen
		}
	    }
	} else {
	    # Es gibt keine Nachricht
	    if ($status == 0) {
		$message_status = $C_MSG->{InboxEmpty};    # neu
	    } else {
		$message_status = $C_MSG->{ReceivedEmpty}; # gelesen
	    }
	}

	# Template mit Statusmeldung fuellen
	$mgr->{TmplData}{MESSAGE_STATUS} = $message_status;

	# Nachrichtennavigation
	$self->fill_nav();

	# Template-Header ggf. mit Meldung fuellen (hat nichts zu tun mit Statusmeldung)
	if (defined $msg) {
	    $mgr->fill($msg);
	} else {
	    $mgr->fill();
	}

	return 1;
}



#====================================================================================================#
# SYNOPSIS: view_send_messages($msg);
# PURPOSE:  Uebersicht der versandten Nachrichten anzeigen
# RETURN:   1
#====================================================================================================#
sub view_send_messages {

        my $self = shift;
	# Meldungen im Header-Template
	my $msg  = shift || undef;

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

	    # Verlinkung mit URL, Methode und Message-ID
	    my $link = $mgr->my_url;
	    $link .= "&method=%s&mid=%s";

            # Fuer jede Nachricht Absender, Betreff, Datum und Verlinkung darstellen
	    for (my $i = 0; $i <= $#send; $i++) {

		# Alle Empfaenger bestimmen
		my @uid = $self->{BASE}->fetch_receiver($send[$i][0]);
		
		# Die Darstellung der Empfaenger ist auf die Anzahl beschraenkt.
		# Nur der erste Empfaenger wird namentlich dargestellt.
		# z.B. Homer Simpson (doh) [1/7], bedeutet insgesamt 7 Empfaenger

		# Name des ersten Empfaengers ermitteln
		my @user = $self->{BASE}->get_user($uid[0]);

		# Vor-, Nach- und Benutzername des 1.Empfaengers 
		$message_loop[$i]{MESSAGE_1ST_RECEIVER}  =
		    $mgr->decode_all(sprintf("%s %s (%s)", $user[0], $user[1], $user[2]));

		# Anzahl der Empfaenger
		if($#uid > 0) {
		    $message_loop[$i]{MESSAGE_RECEIVER_COUNT} =
			$mgr->decode_all(sprintf("[1/%d]",$#uid+1));
		}

		# Verlinkung zur Einzelanssicht ueber Message-ID
		$message_loop[$i]{MESSAGE_LINK} =
		    $mgr->decode_all(sprintf($link, "show_send_message",$send[$i][0]));

		# Betreff der Nachricht
		$message_loop[$i]{MESSAGE_SUBJECT} =
		    $mgr->decode_all($send[$i][2]);

		# Absendedatum der Nachricht
		$message_loop[$i]{MESSAGE_DATE} =
		    $mgr->decode_all($mgr->format_date($send[$i][1]));
	    }

	    # Alle Versandten Nachrichten in Kurzdarstellung fuer das Template
	    $mgr->{TmplData}{MESSAGE_LOOP} = \@message_loop;
	    

	    # Statusmeldung erzeugen, je nach Anzahl der Nachrichten

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
	
	# Template mit Statusmeldung fuellen
	$mgr->{TmplData}{MESSAGE_STATUS} = $message_status;
	
	# Nachrichtennavigation
	$self->fill_nav();

	# Template-Header ggf. mit Meldung fuellen (hat nichts zu tun mit Statusmeldung)
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

    # Message-ID der anzuzeigenden Nachricht ermitteln
    my $mid = $cgi->param('mid');

    my $link = $mgr->my_url;

    # Der Modus ist ersteinmal 'received', also Ansicht einer bekannten empfangenen Nachricht
    my $modus = 'received';

    # Gewuenschte Nachricht holen
    # Die Nachricht besteht aus (mid,from_uid,to_uid,parent_mid,status,date,subject,content)
    my @message = $self->{BASE}->get_message($mid);

    # Nachricht existiert nicht
    unless (@message) {
	# Error-Template vorbereiten
	$mgr->{Template} = $C_TMPL->{Error};
	$mgr->{TmplData}{MSG} = $C_MSG->{NoSuchMsgError};
	return 1;
    }

    # empfangene Nachricht ist neu, d.h. status 0 
    if ($message[4] eq '0') {
	# Nachricht als gelesen Markieren, d.h. status auf 1 setzen
	$self->{BASE}->set_message_status($mid,1);
	# modus ist folglich doch 'inbox'
	$modus = 'inbox';
    }
    # MessageShow-Template vorbereiten
    $mgr->{Template} = $C_TMPL->{MessageShow};
    
    # Sofern nicht die Message-ID der Parent-Message gleich 0 ist,
    # bezieht sich die Nachricht als Antwort auf eine andere Nachricht (Parent-Message)
    unless ($message[3] == 0) {
	# Verlinkung der Parent-Message mit Methode und Message-ID
	$link .= "&method=%s&mid=%s";

	# Parent-Message ueber parent_mid holen...
	# ...entweder bei den versandten Nachrichten,
	my @parent_send = $self->{BASE}->get_send_message($message[3]);
	# ...oder bei den empfangenen Nachrichten
	my @parent = $self->{BASE}->get_message($message[3]);

	# Verlinkung im Template fuellen
	if (@parent_send) {
            # Parent-Message ist eine versandte Nachricht
	    $mgr->{TmplData}{PARENT_LINK} = sprintf($link, "show_send_message", $message[3]);
	    $mgr->{TmplData}{PARENT_SUBJECT} =  $mgr->decode_all($parent_send[3]);
	} elsif (@parent) {
	    # Parent-Message ist eine empfangene Nachricht
	    $mgr->{TmplData}{PARENT_LINK} = sprintf($link, "show_message", $message[3]);
	    $mgr->{TmplData}{PARENT_SUBJECT} =  $mgr->decode_all($parent[6]);
	} 
	# Existiert keine Parent-Message mehr, wird nix angezeigt
    }

    # Absendedatum im Template fuellen
    $mgr->{TmplData}{MESSAGE_DATE} = $mgr->format_date($message[5]);

    # Liste der Empfaenger erzeugen
    my @receiver_loop;
    # Alle Empfaenger-UIDs der Nachricht holen
    my @receivers = $self->{BASE}->fetch_receiver($mid);
    if (@receivers) {
	foreach my $uid (@receivers) {
	    my %tmp;
	    # Namen des Mitglieds bestimmen (Vor-,Nach- und Benutzername)
	    my @user = $self->{BASE}->get_user($uid);
	    $tmp{RECEIVER_NAME} =
		$mgr->decode_all(sprintf("%s %s (%s)", $user[0], $user[1], $user[2]));
	    push(@receiver_loop,\%tmp);
	}

	# Empfaenger-Loop im Template fuellen
	$mgr->{TmplData}{MESSAGE_RECEIVERS_LOOP} = \@receiver_loop;
    }


    # Namen des Absenders ueber from_uid bestimmen
    my @user = $self->{BASE}->get_user($message[1]);
    # Template fuellen mit Absender (Vor-, Nach- und Benutzername)
    $mgr->{TmplData}{MESSAGE_SENDER} =
	$mgr->decode_all(sprintf("%s %s (%s)", $user[0], $user[1], $user[2]));

    # Betreff der Nachricht
    $mgr->{TmplData}{MESSAGE_SUBJECT} = $mgr->decode_all($message[6]);
    # Textinhalt der Nachricht
    $mgr->{TmplData}{MESSAGE_CONTENT} = $mgr->decode_all($message[7]);

    # Notwendige Informationen zum Loeschen/Antworten
    $mgr->{TmplData}{FORM} = $mgr->my_url;
    # Im Falle einer Antwort wird Message-ID zur Parent-MID
    $mgr->{TmplData}{PARENT_MID} = $message[0];
    # Im Falle des Loeschens muss die Message-ID uebertragen werden
    $mgr->{TmplData}{MID} = $mid;

    # Unterscheidung zwischen empfangenen und gelesenen Nachrichten,
    # damit nach dem Loeschen in den richtigen Kontext zurueckgesprungen wird
    $mgr->{TmplData}{MODUS} = $modus;

    # Nachrichtennavigation
    $self->fill_nav;

    # Header-Template fuellen
    $mgr->fill;

    return 1;
}


#====================================================================================================#
# SYNOPSIS: show_send_message($mid);
# PURPOSE:  Detailansicht einer versandten Nachricht
# RETURN:   1
#====================================================================================================#
sub show_send_message {

    my $self = shift;
    my $mgr = $self->{MGR};

    my $cgi = $mgr->{CGI};
 
    # Message-ID der anzuzeigenden Nachricht
    # Falls eine Nachricht verfasst wurde, wird sie nach dem
    # Verschicken sofort angezeigt, dann erfolgt der Aufruf
    # mit der Message-ID nicht mit ueber CGI, sondern als Argument 
    my $mid = $cgi->param('mid') || shift;

    # Verlinkung
    my $link = $mgr->my_url;

    # Der Modus ist ersteinmal versandte Nachrichten
    my $modus = 'send';

    # Gewuenschte Nachricht holen
    # Die Nachricht besteht aus (id,parent_mid,date,subject,content)
    my @message = $self->{BASE}->get_send_message($mid);

    # Es konnte Keine Nachricht gefunden werden
    unless (@message) {
	# Error-Template vorbereiten
	$mgr->{Template} = $C_TMPL->{Error};
	$mgr->{TmplData}{MSG} = $C_MSG->{NoSuchMsgError};
	return 1;
    }

    # MessageShow-Template vorbereiten
    $mgr->{Template} = $C_TMPL->{MessageShow};

    # Message bezieht sich auf eine Parent-Message
    # Parent-Verlinkung erzeugen
    unless ($message[1] == 0) {
	$link .= "&method=%s&mid=%s";
	# Parent-Message holen, entweder aus den versandten oder den empfangenen Nachrichten
	my @parent_send = $self->{BASE}->get_send_message($message[1]);
	my @parent = $self->{BASE}->get_message($message[1]);

	if (@parent_send) {
	    # Nachricht bezieht sich auf versandte Nachricht
	    $mgr->{TmplData}{PARENT_LINK} = sprintf($link, "show_send_message", $message[1]);
	    # Betreffzeile anzeigen
	    $mgr->{TmplData}{PARENT_SUBJECT} =  $mgr->decode_all($parent_send[3]);
	} elsif (@parent) {
	    # Nachricht bezieht sich auf empfangene Nachricht
	    $mgr->{TmplData}{PARENT_LINK} = sprintf($link, "show_message", $message[1]);
	    # Betreffzeile anzeigen
	    $mgr->{TmplData}{PARENT_SUBJECT} =  $mgr->decode_all($parent[6]);
	} 
	# Existiert keine Parent-Message mehr, wird nix angezeigt
    }

    # Versanddatum anzeigen
    $mgr->{TmplData}{MESSAGE_DATE} = $mgr->format_date($message[2]);

    # Alle Empfaenger anzeigen
    my @receiver_loop;
    # Empfaenger-UIDs ermitteln
    my @receivers = $self->{BASE}->fetch_receiver($mid);
    if (@receivers) {
	foreach my $uid (@receivers) {
	    my %tmp;
	    # Namen des Mitglieds bestimmen
	    my @user = $self->{BASE}->get_user($uid);
	    # Vor-, Nach- und Benutzername
	    $tmp{RECEIVER_NAME} =
		$mgr->decode_all(sprintf("%s %s (%s)", $user[0], $user[1], $user[2]));
	    push(@receiver_loop,\%tmp);
	}
	# Empfanger-Loop im Template fuellen
	$mgr->{TmplData}{MESSAGE_RECEIVERS_LOOP} = \@receiver_loop;
    }

    # Betreff der Nachricht
    $mgr->{TmplData}{MESSAGE_SUBJECT} = $mgr->decode_all($message[3]);
    # Textinhalt der Nachricht
    $mgr->{TmplData}{MESSAGE_CONTENT} = $mgr->decode_all($message[4]);

    # Notwendige Informationen zum Loeschen/Antworten
    $mgr->{TmplData}{FORM} = $mgr->my_url;
    # Im Falle des Antwortens wird Message-ID zur Parent-MID
    $mgr->{TmplData}{PARENT_MID} = $message[0];
    # Im Falle des Loeschens muss Message-ID uebermittelt werden
    $mgr->{TmplData}{MID} = $mid;
    # Unterscheidung zwischen empfangenen und gelesenen Nachrichten,
    # damit nach dem Leoschen in den richtigen Kontext zurueckgesprungen wird
    $mgr->{TmplData}{MODUS} = $modus;

    # Nachrichtennavigation
    $self->fill_nav;

    # Header-Template fuellen
    $mgr->fill;

    return 1;
}


#====================================================================================================#
# SYNOPSIS: delete_message();
# PURPOSE:  Nachricht loeschen, dann wieder zur Uebersicht
# RETURN:   1
#====================================================================================================#
sub delete_message {
    
    my $self = shift;
    
    my $mgr = $self->{MGR};
    my $cgi = $self->{MGR}->{CGI};

    # Woher kam dieser Aufruf? modus war empfangene oder versandte Nachrichten
    my $modus = $cgi->param('modus') || undef;
    # Welche Nachricht soll geloescht werden
    my $mid = $cgi->param('mid') || undef;

    # zurueck zur Uebersicht der neuen empfangenen Nachrichten,
    # TODO: Wann tritt das ein, ist das wirklich noetig?
    unless (defined $modus) {
	$self->view_messages(0);
    }

    if ($modus eq 'received') {
    # Nachricht loeschen, zurueck zur Uebersicht der bekannten empfangenen Nachrichten
	$self->{BASE}->delete_received_message($mid);
	$self->view_messages(1,$C_MSG->{MessageDeleted});
    } elsif ($modus eq 'inbox') {
    # Nachricht loeschen, zurueck zur Uebersicht der neuen empfangenen Nachrichten
	$self->{BASE}->delete_received_message($mid);
	$self->view_messages(0,$C_MSG->{MessageDeleted});
    } else {
	# $modus eq 'send'
        # Nachricht loeschen, zurueck zur Uebersicht der versandten Nachrichten
	$self->{BASE}->delete_send_message($mid);
	$self->view_send_messages($C_MSG->{MessageDeleted});
    }
    
    return 1;
}

#====================================================================================================#
# SYNOPSIS: compose_message();
# PURPOSE:  Neue Nachrichten verfassen, d.h. Formular erzeugen
# RETURN:   1
#====================================================================================================#
sub compose_message {
    
    my $self = shift;
    
    my $mgr = $self->{MGR};
    my $cgi = $self->{MGR}->{CGI};

    # Informationen aus der Session lesen
    my $parent_mid   = $mgr->{Session}->get("ParentMid")   || $cgi->param('parent_mid') || 0;
    my $to_usernames = $mgr->{Session}->get("ToUsernames")                              || "";
    my $subject      = $mgr->{Session}->get("Subject")     || $cgi->param('subject')    || "";
    my $content      = $mgr->{Session}->get("Content")     || $cgi->param('content')    || "";
    # Antwort Modus: an den Sender/an alle Mitempfaenger
    my $answermode_sender = $mgr->{Session}->get("AnswerModeSender") || 0;
    my $answermode_all    = $mgr->{Session}->get("AnswerModeAll")    || 0;
    # Session diesbezueglich aufraeumen, Antwortmodus ist in Skalarvariablen gerettet
    $mgr->{Session}->del("AnswerModeSender");
    $mgr->{Session}->del("AnswerModeAll");

    # Alle Empfaenger der Auswahl (choose_receivers)
    my @recv = $cgi->param('recv');
    if (@recv) {
	my @usernames;
	foreach my $uid (@recv) {
	    # Benutzer anhand der UID ermitteln und Benutzername merken
	    my @user = $self->{BASE}->get_user($uid);
	    push(@usernames, $user[2]);
	}
	# Die Benutzernamen des To-Textfeldes werden bei der Auswahl uebernommen,
	# Jetzt wandert alle Empfaengerernamen wieder zurueck ins To-Textfeld
	$to_usernames = join(',',@usernames);
    }

    # MessageNew-Template (Formular) vorbereiten
    $mgr->{Template} = $C_TMPL->{MessageForm};

    $mgr->{TmplData}{FORM} = $mgr->my_url;

    # Formular ggf. mit frueheren Werten belegen
    $mgr->{TmplData}{TO_USERNAMES} = $mgr->decode_some($to_usernames);
    $mgr->{TmplData}{MESSAGE_SUBJECT} = $mgr->decode_some($subject);
    $mgr->{TmplData}{MESSAGE_CONTENT} = $mgr->decode_some($content);
    $mgr->{TmplData}{PARENT_MID} = $mgr->decode_some($parent_mid);

    # Es soll eine Antwort auf eine Nachricht werden, Antwortemodus aktivieren,
    # d.h. Auswahlmenu des Antwortmodus wird angezeigt
    if ($parent_mid != 0) {
	$mgr->{TmplData}{ANSWERMODE} = 1;
    }

    # Antwortmodus mit frueheren Werten belegen
    # Antwort an den Sender
    if ($answermode_sender == 1) {
	$mgr->{TmplData}{SENDER_CHECKED} = 1;
    }
    # Antwort an alle Mitempfaenger
    if ($answermode_all == 1) {
	$mgr->{TmplData}{ALL_CHECKED} = 1;
    }

    # Nachrichtennavigation
    $self->fill_nav;

    # Header-Template fuellen
    $mgr->fill;

    return 1;

}


#====================================================================================================#
# SYNOPSIS: choose_receivers();
# PURPOSE:  Auswahl der Empfaenger
# RETURN:   1
#====================================================================================================#
sub choose_receivers {
    my $self = shift;

    # Ausgabemeldung fuer Header-Template
    my $msg = shift || undef;
    # Benutzer-IDs der Empfaenger
    my $recv_ids = shift || undef;

    my $mgr = $self->{MGR};
    my $cgi = $self->{MGR}->{CGI};

    # Eigene Benutzer-ID, wird stets herausgefiltert
    my $myUserId = $mgr->{UserId};
    
    # Formulareingaben uebernehmen, 1. aus dem Formular per CGI, 2. aus der Session
    my $parent_mid   = $cgi->param('parent_mid')   || $mgr->{Session}->get("ParentMid") || 0;
    my $subject      = $cgi->param('subject')      || $mgr->{Session}->get("Subject")   || "";
    my $content      = $cgi->param('content')      || $mgr->{Session}->get("Content")   || "";
    my $to_usernames = $cgi->param('to_usernames')                                      || "";
    my $answermode_all =
	$cgi->param('answermode_all') || $mgr->{Session}->get("AnswerModeAll") || 0;
    my $answermode_sender =
	$cgi->param('answermode_sender') || $mgr->{Session}->get("AnswerModeSender") || 0;

    # Benutzer-IDs aus der Liste der Benutzernamen ermitteln
    # Whitespaces entfernen, Kommaliste trennen
    $to_usernames =~ s/\s+//gs;
    my @usernames = split /,+/, $to_usernames;
    # Benutzer-IDs (Mehrzahl moeglich)
    my $id = $self->{BASE}->fetch_uids(\@usernames) || undef;

    # Werte der Session aktualisieren, erstmal loeschen
    $mgr->{Session}->del("ParentMid");
    $mgr->{Session}->del("ToUsernames");
    $mgr->{Session}->del("Subject");
    $mgr->{Session}->del("Content");
    $mgr->{Session}->del("AnswerModeSender");
    $mgr->{Session}->del("AnswerModeAll");

    # Daten der Nachricht in die Session schreiben
    $mgr->{Session}->set('ParentMid' => $parent_mid,
			 'ToUsernames' => $to_usernames,
			 'Subject' => $subject,
			 'Content' => $content,
			 'AnswerModeAll' => $answermode_all,
			 'AnswerModeSender' => $answermode_sender);

    # Benutzernamen ueberpruefen
    # Zurueckgegeben werden alle unzulaessigen oder inaktiven Benutzernamen
    my $check = $self->{BASE}->check_usernames(\@usernames) || undef;
    my @check_loop;
    foreach my $username (@$check) {
	my %tmp;
	$tmp{USERNAME} = $mgr->decode_all($username);
	push(@check_loop,\%tmp);
    }
    # Es gibt unzulaessige Benutzernamen, zurueck zum Formular und diese melden
    if (@check_loop) {
	$mgr->{TmplData}{CHECK_USERNAME} = \@check_loop;
	$self->compose_message();
	return;
    }


    # MessageChooseRecv-Template vorbereiten
    $mgr->{Template} = $C_TMPL->{MessageChooseRecv};
   
    # Verlinkung
    my $link = $mgr->my_url;
    
    # Anzeige der Empfaenger
    my @recv_loop;
    my @recv;

    # Empfaenger aus den Benutzenamen des Textfeldes
    if (defined $id) {
	push(@recv, @$id);
    }
    # Fruehere Empfaenger der Auswahl
    if (defined $recv_ids) {
	push(@recv, @$recv_ids);
    }

    my @recv_new;
    my $count;

    # Doppelte und eigener Benutzername herausfiltern
    foreach my $uid (@recv) {
	$count = grep { $uid == $_} @recv_new;
	if ($count == 0) {
	    unless ($uid eq $myUserId) {
		push (@recv_new,$uid);
	    }
	}
    }


    # Jeder Empfaenger kommt in den Empfaenger-Loop im Template
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


    # Auswahl der Benutzer nach Benutzergruppen, Typ-D ist dokumentiert
    my @type_ab_loop;
    my @type_c_loop;
    my @type_d_loop;

    # Auswahl der Typ A/B-Benutzer, beide Typen landen in derselben Gruppe

    # Auswahl des A_User
    # fetcht aktive Typ-A Benutzer, es gibt zwar nur einen, aber trotzdem...
    my $a_user = $self->{BASE}->fetch_users(1,'A');
    if (@$a_user) {
	foreach my $uid (@$a_user) {
	    unless ($uid eq $myUserId) {
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
    }

    # Auswahl der B_User
    # fetcht aktive Typ-B Benutzer
    my $b_users = $self->{BASE}->fetch_users(1,'B');
    # Jedes Mitglied kommt in den Loop
    if (@$b_users) {
	foreach my $uid (@$b_users) {
	    unless ($uid eq $myUserId) {
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
	    unless ($uid eq $myUserId) {
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
	    # Eigene Benutzer-ID herausfiltern
	    unless ($uid eq $myUserId) {
		# Benutzer, die bereits Empfaenger auch herausfiltern
		# Wie oft ist dieser Benutzer schon als Empfaenger vertreten?
		my $count = grep { $uid == $_} @recv_new;
		# Noch gar nicht? Dann aber ab in die Auswahl
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

    # Header-Template fuellen, ggf. mit Meldung
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

    # Benutzer die dazukommen sollen
    my @uid = $cgi->param('user');
    # Empfaenger retten
    my @recv = $cgi->param('recv');
    my $users = undef;
    # Benutzer-IDs hinzufuegen
    foreach my $id (@uid) {
	unless ($id == 0) {
	    push(@$users,$id);
	}
    }
    
    # Es wurden neue Empfaenger ausgewaehlt
    if (defined $users) {
	# Diese hinzufuegen, Doppelte werden von choose_receivers rausgefiltert
	push(@recv, @$users);
	my @u = @$users;
	# Zurueck zur Auwahl mit mehreren Empfaengern
	$self->choose_receivers(sprintf($C_MSG->{UsersAdded},1 + $#u),\@recv);
    } else {
	# Hoppla, doch keine neuen Emofaenger gewaehlt
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

    # Projekt-ID ermitteln
    my $pid = $cgi->param('project') || 0;
    # Empfaenger retten
    my @recv = $cgi->param('recv');
    if ($pid == 0) {
	# Hoppla, doch kein Projekt gewaehlt
	$self->choose_receivers($C_MSG->{NoSelection},\@recv);
    } else {
	# Projektmitglieder holen
	my $members = $self->{BASE}->fetch_project_members($pid);
	# Projektname (fuer die Ausgabemeldung) holen
	my $name = $self->{BASE}->get_project_name($pid);
	# Mitglieder zu den Empfaengern hinzufuegen, doppelte werden in choose_receivers aussortiert
	push(@recv, @$members);
	# Zurueck zur Auswahl
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

    # die Leute die entfernt werden sollen
    my @remove = $cgi->param('remove_receivers');

    # die Empfaenger retten
    my @recv = $cgi->param('recv');

    # Leute herausfiltern
    if (@remove) {
	my @recv_new;
	my $count;
	foreach my $uid (@recv) {
	    $count = grep { $uid == $_} @remove;
	    if ($count == 0) {
		push (@recv_new,$uid);
	    }
	}
	# Zurueck zur Auswahl mit weniger Empfaengern
	$self->choose_receivers(sprintf($C_MSG->{UsersRemoved},1+$#remove),\@recv_new);
    } else {
	# Hoppla, doch nicht Empfaenger entfernen
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

	# Wir kommen direkt vom Eingabeformular, also Eintraege (ggf. Defaultwerte) ermitteln
	my $parent_mid        = $cgi->param('parent_mid')        || 0;
	my $to_usernames      = $cgi->param('to_usernames')      || "";
	my $subject           = $cgi->param('subject')           || "kein Betreff";
	my $content           = $cgi->param('content')           || "kein Text";
	my $answermode_all    = $cgi->param('answermode_all')    || 0;
	my $answermode_sender = $cgi->param('answermode_sender') || 0;

	# Session aufraeumen, d.h. erstmal loeschen
	$mgr->{Session}->del("ParentMid");
	$mgr->{Session}->del("ToUsernames");
	$mgr->{Session}->del("Subject");
	$mgr->{Session}->del("Content");
	$mgr->{Session}->del("AnswerModeSender");
	$mgr->{Session}->del("AnswerModeAll");

	# Oh je, da hat doch jemand keinen Empfaenger angegeben
	if ($answermode_all == 0 && $answermode_sender == 0 && $to_usernames eq "") {
	    # Fehlermeldung soll erscheinen
	    $mgr->{TmplData}{NO_RECEIVER} = $mgr->decode_all($C_MSG->{NoReceiver});
	    # Message in die Session schreiben
	    $mgr->{Session}->set('ParentMid' => $parent_mid,
				 'ToUsernames' => $to_usernames,
				 'Subject' => $subject,
				 'Content' => $content,
				 'AnswerModeAll' => $answermode_all,
				 'AnswerModeSender' => $answermode_sender);
	    # Zureuck zum Eingabeformular und kraeftig meckern
	    $self->compose_message();
	    return 1;
	}

	# Empfaenger-IDs aus der Liste der Benutzernamen ermitteln
	# Whitespaces entfernen, Kommaliste trennen
	$to_usernames =~ s/\s+//gs;
	my @usernames = split /,+/, $to_usernames;
	# Benutzer-IDs holen
	my $id = $self->{BASE}->fetch_uids(\@usernames);

	# Benutzernamen ueberpruefen
	my $check = $self->{BASE}->check_usernames(\@usernames) || undef;
	my @check_loop;
	# Es gab unbekannte/inaktive Benutzernamen im Textfeld, diese sollen angezeigt werden
	foreach my $username (@$check) {
	    my %tmp;
	    $tmp{USERNAME} = $mgr->decode_all($username);
	    push(@check_loop,\%tmp);
	}
	if (@check_loop) {
	    # Es gab unbekannte/inaktive Benutzernamen, diese anuzeigen
	    $mgr->{TmplData}{CHECK_USERNAME} = \@check_loop;

	    # Message in die Session schreiben
	    $mgr->{Session}->set('ParentMid' => $parent_mid,
				 'ToUsernames' => $to_usernames,
				 'Subject' => $subject,
				 'Content' => $content,
				 'AnswerModeAll' => $answermode_all,
				 'AnswerModeSender' => $answermode_sender);
	    # Zurueck zum Formular und jammern
	    $self->compose_message();
	    return;
	}

	# Sender der Parent-Message kommt zu den Empfaengern hinzu
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
	    } else {
		# es existiert keine empfangene Parent-Nachricht
		# das ist dann der Fall, wenn der Benutzer auf eine
		# selbst abgesandte Nachricht antwortet,
		# andere Faelle fallen mir nicht ein
		my $sender_id = $mgr->{UserId};
		push(@$id, $sender_id);
	    }
	}

	# Mitempfaenger der Parent-Message kommen zu den Empfaengern hinzu
	if ($answermode_all == 1) {
	    # Alle Empfaenger bestimmen
	    my @all = $self->{BASE}->fetch_receiver($parent_mid);
	    # Es gibt Empfaenger
	    if (@all) {
		my $myUserId = $mgr->{UserId};
		foreach my $uid (@all) {
		    my $count = grep { $uid == $_} @$id;
		    # Empfaenger der Parent_message ist noch nicht in der Liste der Empfaenger
		    if ($count == 0) {
			unless ($uid eq $myUserId) {
			    push(@$id, $uid);
			}
		    }
		}
	    }
	}

	# Sicherstellen, dass keine empfaengerlose Nachricht abgelegt wird
	# Sollte bei konsistenten Ablauf nicht auftreten
	my $mid;
	if (@$id) {
	    $mid = $self->{BASE}->insert_new_messages($id, $parent_mid, $subject, $content);
	} else {
	    # Irgendetwas ist schief gelaufen
	    # Error-Template vorbereiten
	    $mgr->{Template} = $C_TMPL->{Error};
	    $mgr->{TmplData}{MSG} = $C_MSG->{NoRecvError};
	    return 1;
	}

	# Versandte Nachricht sofort anzeigen
	$self->show_send_message($mid);

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





















