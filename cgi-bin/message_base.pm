package message_base;

use vars qw($VERSION);
use strict;

sub new {

	my $proto = shift;
	my $args  = shift;

	my $class = ref($proto) || $proto;
	my $self  = {};

	foreach (keys %$args) {
		$self->{$_} = $args->{$_};
	}

	bless ($self, $class);
	
	$self;
}


#====================================================================================================#
# SYNOPSIS: fetch_users($status);
# PURPOSE:  ermittelt alle existierenden User (status: 0=inaktiv, 1=aktiv)
# RETURN:   array von hashref
#====================================================================================================#
sub fetch_users {
 
        my $self = shift;
	my $status = shift || 1;

        my $mgr = $self->{MGR};

	my @users;

 	# ### connect ###
        my $dbh = $mgr->connect;
        my $sth = $dbh->prepare(qq{SELECT * FROM $mgr->{UserTable} WHERE status='$status'});

        unless ($sth->execute()) {
                warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
                        $mgr->{UserTable}, $dbh->errstr);
                $mgr->fatal_error($self->{C_MSG}->{DbError});
        }

	my $user;
	while ($user = $sth->fetchrow_hashref()) {
		push (@users, $user);
	}

	$sth->finish;
	# ### disconnect ###

        return @users;
} 





# --- get_user ---
# holt infos ueber user mit uid
sub get_user {
 
        my $self = shift;
	my $uid = shift;

        my $mgr = $self->{MGR};

 	# ### connect ###
        my $dbh = $mgr->connect;
        my $sth = $dbh->prepare(qq{SELECT * FROM $mgr->{UserTable} WHERE id = $uid});
 
        unless ($sth->execute()) {
                warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
                        $mgr->{UserTable}, $dbh->errstr);
                $mgr->fatal_error($self->{C_MSG}->{DbError});
        }

	my $user = $sth->fetchrow_hashref();

	$sth->finish;
	# ### disconnect ###

        return $user;
} 

#====================================================================================================#
# SYNOPSIS: get_message($mid);
# PURPOSE:  liefert die Message mit mid
# RETURN:   hashref
#====================================================================================================#
# --- get_messge ---
# holt message mit mid
sub get_message {
 
        my $self = shift;
	my $mid = shift;

        my $mgr = $self->{MGR};

 	# ### connect ###
        my $dbh = $mgr->connect;
        my $sth = $dbh->prepare(qq{SELECT * FROM $mgr->{MReceiveTable} WHERE mid=$mid});
 
        unless ($sth->execute()) {
                warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
                        $mgr->{MReceiveTable}, $dbh->errstr);
                $mgr->fatal_error($self->{C_MSG}->{DbError});
        }

	my $message = $sth->fetchrow_hashref();

	$sth->finish;
	# ### disconnect ###

        return $message;
} 




# --- fetcht (id, name) aller existierenden Projekte ---
# TODO Nach aktiv und inaktiv unterscheiden?
sub fetch_projects{
 
        my $self = shift;
 
        my $mgr = $self->{MGR};
	my @projects;
 

	# ### connect ###
        my $dbh = $mgr->connect;
        my $sth = $dbh->prepare(qq{SELECT id, name FROM $mgr->{ProTable}});
 
        unless ($sth->execute()) {
                warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
                        $mgr->{ProTable}, $dbh->errstr);
                $mgr->fatal_error($self->{C_MSG}->{DbError});
        }

	while (my ($id, $name) = $sth->fetchrow_array()) {
		push (@projects, [$id, $name]);
	}

	$sth->finish;
	# ### disconnect ###


        return @projects;
} 








# --- fetcht (user_id) aller User aus den Projekten @pid ---
# TODO Nach aktiv und inaktiv unterscheiden
# fetch_project_members(\@pid)
sub fetch_project_members {

        my $self = shift;
	my $pid = shift;

        my $mgr = $self->{MGR};

	my @users;
	my @fetched_ids;


	# ### connect ###
        my $dbh = $mgr->connect;
        my $sth = $dbh->prepare(qq{SELECT user_id, project_id FROM $mgr->{ProUserTable}});
 
        unless ($sth->execute()) {
                warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
                        $mgr->{ProUserTable}, $dbh->errstr);
                $mgr->fatal_error($self->{C_MSG}->{DbError});
        }

	# Alle (user_id, project_id) nach fetched_ids fetchen
	while (my ($user_id, $project_id) = $sth->fetchrow_array()) {
		push (@fetched_ids, [$user_id, $project_id]);
	}

	$sth->finish;
	# ### disonnect ###


	# Alle zu den Projekten passenden (uid) aus fetched_ids filtern
	my $project_id;
	my $ids;
	foreach $project_id (@{$pid}) {
	    foreach $ids (@fetched_ids) {
		if ($ids->[1] eq $project_id) {
		    push (@users, $ids->[0]);
		}
	    }
	}

        return \@users;
}

#====================================================================================================#
# SYNOPSIS: insert_new_messages($uids,$parent_id,$subject,$content);
# PURPOSE:  Neue Messages in die entsprechenden Tables eintragen
# RETURN:   ---
#====================================================================================================#
sub insert_new_messages {

        my $self = shift;

	my $uids = shift;
	my $parent_mid = shift;
	my $subject = shift;
	my $content = shift;

        my $mgr = $self->{MGR};

	my $to_uid;
	my $from_uid = $mgr->{UserId};
	my $date = "2001-06-11 14:16:32"; # TODO
	my $mid = 0; # ist auto_increment, daher 'mysql_insertid'


	# ### connect ###
        my $dbh = $mgr->connect;

	# Message in Send-Table einfuegen
        my $sth = $dbh->prepare(qq{INSERT INTO $mgr->{MSendTable}
				   (from_uid, parent_mid, date, subject, content) values
				       ($from_uid, $parent_mid, '$date', '$subject', '$content');});

        unless ($sth->execute()) {
                warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
                        $mgr->{MSendTable}, $dbh->errstr);
                $mgr->fatal_error($self->{C_MSG}->{DbError});
        }

	# MessageID ermitteln (autoincrement)
	$mid = $dbh->{'mysql_insertid'};


	# An alle Empfaenger
	foreach $to_uid (@$uids) {

	# Message in Receive-Table einfuegen
	    $sth = $dbh->prepare(qq{INSERT INTO $mgr->{MReceiveTable}
				       (mid, from_uid, to_uid, parent_mid, status, date, subject, content) values
					   ($mid, $from_uid, $to_uid, $parent_mid, '0','$date', '$subject', '$content');});

	    unless ($sth->execute()) {
                warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
			     $mgr->{MReceiveTable}, $dbh->errstr);
                $mgr->fatal_error($self->{C_MSG}->{DbError});
	    }

	    # MessageID/UserID-Verknuepfung anlegen in ToUser-Table
	    $sth = $dbh->prepare(qq{INSERT INTO $mgr->{MToUserTable }
				       (mid, uid) values ($mid, $to_uid);});

	    unless ($sth->execute()) {
                warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
			     $mgr->{MToUserTable}, $dbh->errstr);
                $mgr->fatal_error($self->{C_MSG}->{DbError});
	    }

	}

	$sth->finish;
	# ### disonnect ###

	return;
}



#====================================================================================================#
# SYNOPSIS: fetch_received_messages($status);
# PURPOSE:  ruft die empfangenen Nachrichten ab (status: 0=ungelesen, 1=gelesen)
# RETURN:   array von hashref
#====================================================================================================#
sub fetch_received_messages{
 
        my $self = shift;
	my $status = shift || 0;

        my $mgr = $self->{MGR};

	my @messages;
	my $my_uid = $mgr->{UserId};

	# ### connect ###
        my $dbh = $mgr->connect;
	my $sth;
	$sth = $dbh->prepare(qq{SELECT * FROM $mgr->{MReceiveTable} WHERE to_uid=$my_uid AND status='$status'});

        unless ($sth->execute()) {
                warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
                        $mgr->{MReceiveTable}, $dbh->errstr);
                $mgr->fatal_error($self->{C_MSG}->{DbError});
        }

	while (my $message = $sth->fetchrow_hashref()) {
		push (@messages, $message);
	}

	$sth->finish;
	# ### disconnect ###

        return @messages;
} 












# --- count_element($elem, \@aref) liefert Anzahl der $elem in \@aref ---
sub count_element {

        my $self = shift;
	my $element = shift;
	my $aref = shift;

	my $count = 0;
	foreach (@$aref) {
	    if ($element eq $_) {
		$count = $count+1;
	    }
	}

        return $count;
}











# --- filtert Doubletten eines Arrays ---
# filter(\@aref)
sub filter {

        my $self = shift;
	my $aref = shift;

	my $aref_new;
	my $element;
	foreach $element (@$aref) {
	    if (count_element($element,$aref_new) == 0) {
		push(@$aref_new, $element);
	    }
	}

        return $aref_new;
}



















1;
