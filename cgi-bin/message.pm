package message;

use Class::Singleton;
use base 'Class::Singleton';
use message_base;
use message_config;
use vars qw($VERSION $C_MSG $C_TMPL);
use strict;

$VERSION = sprintf "%d.%03d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/;

$C_MSG  = $message_config::MSG;
$C_TMPL = $message_config::TMPL;

sub parameter {

	my $self = shift;
	my $mgr  = shift;


	# Global for this package here.
	$self->{MGR} = $mgr;

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
		if ($method eq "read_messages") {
		    $self->read_messages();
		} elsif ($method eq "new_message") {
		    $self->new_message();
		} elsif ($method eq "send_message") {
		    $self->send_message();
		}
	    }
	else {
	    $self->menue();
	}
    }

# --- Ausgabe des Message-Menues ---
sub menue {
 
        my $self = shift;
        my $msg  = shift || undef;
 
        my $mgr = $self->{MGR};

 	my $link = $mgr->{ScriptName}."?action=%s&sid=".$mgr->{Sid};

        $mgr->{Template}       = $C_TMPL->{Message};
	$link .= "&method=%s";
	$mgr->{TmplData}{NAV_MSG_READ} = sprintf($link, "message","read_messages");
	$mgr->{TmplData}{NAV_MSG_NEW} = sprintf($link, "message","new_message");

        $mgr->fill; 

	return;
}


# --- Neue Nachricht: Formular ausgaben ---
sub new_message {
 
        my $self = shift;
	my $msg  = shift || undef;

        my $mgr = $self->{MGR};
        my $cgi = $self->{MGR}->{CGI};
 

        my $uid = $cgi->param('uid');
	my $pid = $cgi->param('pid');
        my $subject = $cgi->param('subject') || "";
        my $content = $cgi->param('content') || "";


	$mgr->{Template} = $C_TMPL->{MessageNew};

	# Liste von (uid, firstname, lastname, username) aus User-Table
	my @users = $self->{BASE}->fetch_users;	

	if (@users) {
	    my @tmp;
	    
	    for (my $i = 0; $i <= $#users; $i++) {
		$tmp[$i]{UID}   = $users[$i][0];
		$tmp[$i]{UNAME} = sprintf("%s %s (%s)",
					  $mgr->decode_all($users[$i][1]),
					  $mgr->decode_all($users[$i][2]),
					  $mgr->decode_all($users[$i][3])
					  );
	    }
	    
	    $mgr->{TmplData}{USER_LOOP} = \@tmp;
	}

	# Liste von (uid, name) aus Project-Table
	my @projects = $self->{BASE}->fetch_projects;

	if (@projects) {
	    my @tmp;
	    
	    for (my $i = 0; $i <= $#projects; $i++) {
		$tmp[$i]{PID}   = $projects[$i][0];
		$tmp[$i]{PNAME} = $mgr->decode_all($projects[$i][1]);
	    }
	    
	    $mgr->{TmplData}{PROJECT_LOOP} = \@tmp;
	}

	$mgr->{TmplData}{FORM} = $mgr->my_url();
	$mgr->{TmplData}{METHOD}    = "send_message";
	$mgr->{TmplData}{SUBJECT} = $mgr->decode_all($subject);
	$mgr->{TmplData}{CONTENT} = $mgr->decode_all($content);
     
	$mgr->fill;

	return;
}


# --- Neue Nachricht: Message "absenden" ---
sub send_message {
 
        my $self = shift;
	my $msg  = shift || undef;

        my $mgr = $self->{MGR};
        my $cgi = $self->{MGR}->{CGI};
 

        my @uid = $cgi->param('uid');
	my @pid = $cgi->param('pid');
        my $subject = $cgi->param('subject') || "";
        my $content = $cgi->param('content') || "";


	$mgr->{Template} = $C_TMPL->{TestOut};

	my $project_members = $self->{BASE}->fetch_project_members(\@pid);
	foreach (@$project_members) {
	    push(@uid, $_);
	}
	
	$self->{BASE}->insert_new_messages(\@uid,$subject,$content);

	$mgr->{TmplData}{TEST_OUT_A} = join($",@uid);
	$mgr->{TmplData}{TEST_OUT_B} = "---";
	$mgr->{TmplData}{TEST_OUT_C} = $mgr->decode_all($subject);
	$mgr->{TmplData}{TEST_OUT_D} = $mgr->decode_all($content);
     
	$mgr->fill;

	return;
}


# --- Nachrichten lesen ---
# --- ersteinmal alle Nachrichten die den User betreffen, dumb dump
sub read_messages {
 
        my $self = shift;
	my $msg  = shift || undef;
	
        my $mgr = $self->{MGR};
        my $cgi = $self->{MGR}->{CGI};

	$mgr->{Template} = $C_TMPL->{MessagesRead};

	# (mid, from_uid, parent_mid, date, subject, content)
	my @messages = $self->{BASE}->fetch_received_messages;

	if (@messages) {
	    my @tmp;
	    
	    for (my $i = 0; $i <= $#messages; $i++) {
		$tmp[$i]{UNAME} = $mgr->decode_all($messages[$i][1]);
		$tmp[$i]{PARENT_MID} = $mgr->decode_all($messages[$i][2]);
		$tmp[$i]{DATE} = $mgr->decode_all($messages[$i][3]);
		$tmp[$i]{SUBJECT} = $mgr->decode_all($messages[$i][4]);
		$tmp[$i]{CONTENT} = $mgr->decode_all($messages[$i][5]);
	    }
	    
	    $mgr->{TmplData}{RECV_LOOP} = \@tmp;
	}


	$mgr->fill;

	return;
}

1;
