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
# SYNOPSIS: get_user($uid);
# PURPOSE:  Realname und Username des Benutzers mit der ID $uid bestimmen
# RETURN:   @(firstname,lastname,username)
#====================================================================================================#
sub get_user {

        my $self = shift;
	my $uid = shift;

        my $mgr = $self->{MGR};
	
 	# ### connect ###
        my $dbh = $mgr->connect;
	unless ($dbh->do(qq{LOCK TABLES $mgr->{UserTable} READ})) {
	    warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
			 $mgr->{UserTable}, $dbh->ersstr);
        }
	
        my $sth = $dbh->prepare(qq{SELECT firstname,lastname,username
				       FROM $mgr->{UserTable} WHERE id = ?});
	
        unless ($sth->execute($uid)) {
	    warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
			 $mgr->{UserTable}, $dbh->errstr);
	    $dbh->do("UNLOCK TABLES");
	    $mgr->fatal_error($self->{C_MSG}->{DbError});
        }
	
	my @user = $sth->fetchrow_array();
	
	$sth->finish;
	$dbh->do("UNLOCK TABLES");
	# ### disconnect ###

	# Falls es keinen User gibt
	unless (@user) {
	    $user[0] = 'unbekannt';
	    $user[1] = '';
	    $user[2] = '?';
	}

        return @user;
    }


#====================================================================================================#
# SYNOPSIS: fetch_received($status);
# PURPOSE:  ruft die empfangenen Nachrichten ab ($status=0 Inbox, $status=1 Received)
# RETURN:   @[](mid,from_uid,date,subject)
#====================================================================================================#
sub fetch_received {
    
    my $self = shift;
    my $status = shift || 0;
    
    my $mgr = $self->{MGR};
    
    my @received;
    
    # ### connect ###
    my $dbh = $mgr->connect;
    unless ($dbh->do(qq{LOCK TABLES $mgr->{MReceiveTable} READ})) {
	warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
		     $mgr->{MReceiveTable}, $dbh->ersstr);
    }
    
    my $sth = $dbh->prepare(qq{SELECT mid,from_uid,date,subject FROM $mgr->{MReceiveTable}
			       WHERE to_uid = ? AND status = ?});
    
    unless ($sth->execute($mgr->{UserId},"$status")) {
	warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
		     $mgr->{MReceiveTable}, $dbh->errstr);
	$dbh->do("UNLOCK TABLES");
	$mgr->fatal_error($self->{C_MSG}->{DbError});
    }
    
    while (my @message = $sth->fetchrow_array()) {
	push (@received, \@message);
    }
    
    $sth->finish;
    $dbh->do("UNLOCK TABLES");
    # ### disconnect ###
    
    return @received;
}


#====================================================================================================#
# SYNOPSIS: get_message($mid);
# PURPOSE:  holt die empfangene Nachricht mit der ID $mid
# RETURN:   (mid,from_uid,to_uid,parent_mid,status,date,subject,content)
#====================================================================================================#
sub get_message {
    
    my $self = shift;
    my $mid = shift;
    
    my $mgr = $self->{MGR};
    
    # ### connect ###
    my $dbh = $mgr->connect;
    
    unless ($dbh->do(qq{LOCK TABLES $mgr->{MReceiveTable} READ})) {
	warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
		     $mgr->{MReceiveTable}, $dbh->ersstr);
    }
    
    my $sth = $dbh->prepare(qq{SELECT mid,from_uid,to_uid,parent_mid,status,date,subject,content
				   FROM $mgr->{MReceiveTable} WHERE to_uid = ? AND mid = ?});
    
    unless ($sth->execute($mgr->{UserId},$mid)) {
	warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
		     $mgr->{MReceiveTable}, $dbh->errstr);
	$dbh->do("UNLOCK TABLES");
	$mgr->fatal_error($self->{C_MSG}->{DbError});
    }
    
    my @message = $sth->fetchrow_array();
    
    $sth->finish;
    $dbh->do("UNLOCK TABLES");
    # ### disconnect ###
    
    return @message;
}


#====================================================================================================#
# SYNOPSIS: get_send_message($mid);
# PURPOSE:  holt die versandte Nachricht mit der ID $mid
# RETURN:   (id,parent_mid,date,subject,content)
#====================================================================================================#
sub get_send_message {
    
    my $self = shift;
    my $mid = shift;
    
    my $mgr = $self->{MGR};
    
    # ### connect ###
    my $dbh = $mgr->connect;
    
    unless ($dbh->do(qq{LOCK TABLES $mgr->{MSendTable} READ})) {
	warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
		     $mgr->{MSendTable}, $dbh->ersstr);
    }
    
    my $sth = $dbh->prepare(qq{SELECT id,parent_mid,date,subject,content
				   FROM $mgr->{MSendTable} WHERE from_uid = ? AND id = ?});
    
    unless ($sth->execute($mgr->{UserId},$mid)) {
	warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
		     $mgr->{MSendTable}, $dbh->errstr);
	$dbh->do("UNLOCK TABLES");
	$mgr->fatal_error($self->{C_MSG}->{DbError});
    }
    
    my @message = $sth->fetchrow_array();
    
    $sth->finish;
    $dbh->do("UNLOCK TABLES");
    # ### disconnect ###
    
    return @message;
} 


#====================================================================================================#
# SYNOPSIS: set_message_status($mid,$status);
# PURPOSE:  setzt den Status der betreffenden Nachricht ($status=0 Inbox, $status=1 Received)
# RETURN:   1
#====================================================================================================#
sub set_message_status {

	my $self = shift;
	my $mid  = shift;
	my $status  = shift;

	my $mgr = $self->{MGR};

	# ### connect ###
	my $dbh = $mgr->connect;
	
	unless ($dbh->do("LOCK TABLES $mgr->{MReceiveTable} WRITE")) {
	    warn srpintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
			 $mgr->{MReceiveTable}, $dbh->ersstr);
        }
	
	my $sth = $dbh->prepare(qq{UPDATE $mgr->{MReceiveTable} SET status = ?
				       WHERE to_uid = ? AND mid = ?});
	
	unless ($sth->execute("$status", $mgr->{UserId}, $mid)) {
	    warn sprintf("[Error]: Trouble updating status in [%s]. Reason: [%s].",
			 $mgr->{MReceiveTable}, $dbh->errstr);
	    $dbh->do("UNLOCK TABLES");
	    $mgr->fatal_error($self->{C_MSG}->{DbError});
	}
	
	$sth->finish;
	$dbh->do("UNLOCK TABLES");
	
	return 1;
}


#====================================================================================================#
# SYNOPSIS: fetch_send();
# PURPOSE:  ruft die versandten Nachrichten ab
# RETURN:   @[](id,date,subject)
#====================================================================================================#
sub fetch_send {
    
    my $self = shift;

    my $mgr = $self->{MGR};
    
    my @send;
    
    # ### connect ###
    my $dbh = $mgr->connect;
    unless ($dbh->do(qq{LOCK TABLES $mgr->{MSendTable} READ})) {
	warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
		     $mgr->{MSendTable}, $dbh->ersstr);
    }

    my $sth = $dbh->prepare(qq{SELECT id,date,subject FROM $mgr->{MSendTable}
			       WHERE from_uid = ?});
    
    unless ($sth->execute($mgr->{UserId})) {
	warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
		     $mgr->{MSendTable}, $dbh->errstr);
	$dbh->do("UNLOCK TABLES");
	$mgr->fatal_error($self->{C_MSG}->{DbError});
    }
    
    while (my @message = $sth->fetchrow_array()) {
	push (@send, \@message);
    }
    
    $sth->finish;
    $dbh->do("UNLOCK TABLES");
    # ### disconnect ###
    
    return @send;
}


#====================================================================================================#
# SYNOPSIS: fetch_receiver($mid);
# PURPOSE:  liefert die uids aller Empfaenger der angegebenen Message
# RETURN:   @(id)
#====================================================================================================#
sub fetch_receiver {
    
    my $self = shift;
    my $mid = shift;
    my $mgr = $self->{MGR};
    
    my @uid;
    
    # ### connect ###
    my $dbh = $mgr->connect;
    unless ($dbh->do(qq{LOCK TABLES $mgr->{MToUserTable} READ})) {
	warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
		     $mgr->{MToUserTable}, $dbh->ersstr);
    }

    my $sth = $dbh->prepare(qq{SELECT uid FROM $mgr->{MToUserTable}
			       WHERE mid = ?});
    
    unless ($sth->execute($mid)) {
	warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
		     $mgr->{MToUserTable}, $dbh->errstr);
	$dbh->do("UNLOCK TABLES");
	$mgr->fatal_error($self->{C_MSG}->{DbError});
    }
    
    while (my $id = $sth->fetchrow_array()) {
	push (@uid, $id);
    }
    
    $sth->finish;
    $dbh->do("UNLOCK TABLES");
    # ### disconnect ###
    
    return @uid;
}


#====================================================================================================#
# SYNOPSIS: fetch_uids(\@usernames);
# PURPOSE:  liefert die uids der angegebenen Usernamen
# RETURN:   \@uid
#====================================================================================================#
sub fetch_uids {
    
    my $self = shift;
    my $usernames = shift;
    my $mgr = $self->{MGR};

    my @uid = ();
    
    # ### connect ###
    my $dbh = $mgr->connect;
    unless ($dbh->do(qq{LOCK TABLES $mgr->{UserTable} READ})) {
	warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
		     $mgr->{UserTable}, $dbh->ersstr);
    }

    my $sth = $dbh->prepare(qq{SELECT id FROM $mgr->{UserTable} WHERE username = ? AND status = ?});

    foreach my $uname (@$usernames) {
	unless ($sth->execute($uname,'1')) {
	    warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
			 $mgr->{UserTable}, $dbh->errstr);
	    $dbh->do("UNLOCK TABLES");
	    $mgr->fatal_error($self->{C_MSG}->{DbError});
	}
	
	my @id = $sth->fetchrow_array();
	# push (@uid,\@id);
	push (@uid, @id);
    }
    
    $sth->finish;
    $dbh->do("UNLOCK TABLES");
    # ### disconnect ###
    
    return \@uid;
}

#====================================================================================================#
# SYNOPSIS: check_projectnames(\@projectnames);
# PURPOSE:  liefert die unbekannten Benutzernamen, 5.7.2001: wird nicht mehr benoetigt
# RETURN:   \@falsenames
#====================================================================================================#
sub check_projectnames {
    
    my $self = shift;
    my $projectnames = shift;
    my $mgr = $self->{MGR};

    my @falsenames = ();
    
    # ### connect ###
    my $dbh = $mgr->connect;
    unless ($dbh->do(qq{LOCK TABLES $mgr->{ProTable} READ})) {
	warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
		     $mgr->{ProTable}, $dbh->ersstr);
    }

    my $sth = $dbh->prepare(qq{SELECT name FROM $mgr->{ProTable} WHERE name = ? AND status = ?});

    foreach my $pname (@$projectnames) {
	unless ($sth->execute($pname,1)) {
	    warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
			 $mgr->{ProTable}, $dbh->errstr);
	    $dbh->do("UNLOCK TABLES");
	    $mgr->fatal_error($self->{C_MSG}->{DbError});
	}
	
	my @id = $sth->fetchrow_array();
	unless (@id) {
	    push (@falsenames, $pname);
	}
    }
    
    $sth->finish;
    $dbh->do("UNLOCK TABLES");
    # ### disconnect ###
    
    return \@falsenames;
}

#====================================================================================================#
# SYNOPSIS: check_usernames(\@usernames);
# PURPOSE:  liefert die unbekannten Benutzernamen
# RETURN:   \@falsenames
#====================================================================================================#
sub check_usernames {
    
    my $self = shift;
    my $usernames = shift;
    my $mgr = $self->{MGR};

    my @falsenames = ();
    
    # ### connect ###
    my $dbh = $mgr->connect;
    unless ($dbh->do(qq{LOCK TABLES $mgr->{UserTable} READ})) {
	warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
		     $mgr->{UserTable}, $dbh->ersstr);
    }

    my $sth = $dbh->prepare(qq{SELECT username FROM $mgr->{UserTable} WHERE username = ?});

    foreach my $uname (@$usernames) {
	unless ($sth->execute($uname)) {
	    warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
			 $mgr->{UserTable}, $dbh->errstr);
	    $dbh->do("UNLOCK TABLES");
	    $mgr->fatal_error($self->{C_MSG}->{DbError});
	}
	
	my @id = $sth->fetchrow_array();
	unless (@id) {
	    push (@falsenames, $uname);
	}
    }
    
    $sth->finish;
    $dbh->do("UNLOCK TABLES");
    # ### disconnect ###
    
    return \@falsenames;
}
#====================================================================================================#
# SYNOPSIS: insert_new_messages(\@uids,$parent_mid,$subject,$content);
# PURPOSE:  Neue Messages in die entsprechenden Tables eintragen
# RETURN:   $mid, Message-ID
#====================================================================================================#
sub insert_new_messages {

        my $self = shift;

	my $uids = shift;
	my $parent_mid = shift;
	my $subject = shift;
	my $content = shift;

        my $mgr = $self->{MGR};

	my $from_uid = $mgr->{UserId};
	my $date = $mgr->now();
	my $mid = 0; # ist auto_increment, daher 'mysql_insertid'

	# ### connect ###
        my $dbh = $mgr->connect;
	unless ($dbh->do(qq{LOCK TABLES $mgr->{MSendTable} WRITE, $mgr->{MReceiveTable} WRITE, $mgr->{MToUserTable} WRITE})) {
	    warn sprintf("[Error]: Trouble locking tables [%s,%s and %s]. Reason: [%s].",
			 $mgr->{MSendTable},$mgr->{MReceiveTable},$mgr->{MToUserTable},$dbh->ersstr);
	}

	# Message in Send-Table einfuegen
        my $sth = $dbh->prepare(qq{INSERT INTO $mgr->{MSendTable}
				   (from_uid,parent_mid,date,subject,content) values (?,?,?,?,?);});
	
        unless ($sth->execute($from_uid,$parent_mid,$date,$subject,$content)) {
	    warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
			 $mgr->{MSendTable}, $dbh->errstr);
	    $dbh->do("UNLOCK TABLES");
	    $mgr->fatal_error($self->{C_MSG}->{DbError});
	}

	# MessageID ermitteln (autoincrement)
	$mid = $dbh->{'mysql_insertid'};

	$sth->finish;

	# Message in Receive-Table einfuegen
	$sth = $dbh->prepare(qq{INSERT INTO $mgr->{MReceiveTable} (mid,from_uid,to_uid,parent_mid,status,date,subject,content) values (?,?,?,?,?,?,?,?);});

	# An alle Empfaenger
	foreach my $to_uid (@$uids) {
	    unless ($sth->execute($mid,$from_uid,$to_uid,$parent_mid,'0',$date, $subject,$content)) {
                warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
			     $mgr->{MReceiveTable}, $dbh->errstr);
		$dbh->do("UNLOCK TABLES");
                $mgr->fatal_error($self->{C_MSG}->{DbError});
	    }
	}
	
	$sth->finish;

	# MessageID/UserID-Verknuepfung anlegen in ToUser-Table
	$sth = $dbh->prepare(qq{INSERT INTO $mgr->{MToUserTable} (mid, uid) values (?,?);});
	foreach my $to_uid (@$uids) {
	    unless ($sth->execute($mid, $to_uid)) {
                warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
			     $mgr->{MToUserTable}, $dbh->errstr);
		$dbh->do("UNLOCK TABLES");
                $mgr->fatal_error($self->{C_MSG}->{DbError});
	    }   
	}

	$sth->finish;
	$dbh->do("UNLOCK TABLES");
	# ### disonnect ###

	return $mid;
}
#====================================================================================================#
# SYNOPSIS: delete_received_message($mid);
# PURPOSE:  Loeschen einer Nachricht
# RETURN:   -
#====================================================================================================#
sub delete_received_message {

        my $self = shift;
	my $mid = shift;

        my $mgr = $self->{MGR};

	my $to_uid = $mgr->{UserId};

	# ### connect ###
        my $dbh = $mgr->connect;
	unless ($dbh->do(qq{LOCK TABLES $mgr->{MReceiveTable} WRITE})) {
	    warn sprintf("[Error]: Trouble locking tables [%s,%s and %s]. Reason: [%s].",
			 $mgr->{MReceiveTable},$dbh->ersstr);
	}

	# Message loeschen
        my $sth = $dbh->prepare(qq{DELETE FROM $mgr->{MReceiveTable} WHERE mid = ? AND to_uid  = ?});
	
        unless ($sth->execute($mid,$to_uid)) {
	    warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
			 $mgr->{MReceiveTable}, $dbh->errstr);
	    $dbh->do("UNLOCK TABLES");
	    $mgr->fatal_error($self->{C_MSG}->{DbError});
	}

	$sth->finish;

	$dbh->do("UNLOCK TABLES");
	# ### disonnect ###

	return 1;
}


#====================================================================================================#
# SYNOPSIS: delete_send_message($mid);
# PURPOSE:  Loeschen einer Nachricht
# RETURN:   -
#====================================================================================================#
sub delete_send_message {

        my $self = shift;
	my $mid = shift;

        my $mgr = $self->{MGR};

	my $from_uid = $mgr->{UserId};

	# ### connect ###
        my $dbh = $mgr->connect;
	unless ($dbh->do(qq{LOCK TABLES $mgr->{MSendTable} WRITE})) {
	    warn sprintf("[Error]: Trouble locking tables [%s,%s and %s]. Reason: [%s].",
			 $mgr->{MSendTable},$dbh->ersstr);
	}

	# Message loeschen
        my $sth = $dbh->prepare(qq{DELETE FROM $mgr->{MSendTable} WHERE id = ? AND from_uid  = ?});
	
        unless ($sth->execute($mid,$from_uid)) {
	    warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
			 $mgr->{MSendTable}, $dbh->errstr);
	    $dbh->do("UNLOCK TABLES");
	    $mgr->fatal_error($self->{C_MSG}->{DbError});
	}

	$sth->finish;

	$dbh->do("UNLOCK TABLES");
	# ### disonnect ###

	return 1;
}


#====================================================================================================#
# SYNOPSIS: fetch_projects();
# PURPOSE:  holt alle Prokekte
# RETURN:   @(id,name,cat_id)
#====================================================================================================#
sub fetch_projects{
 
    my $self = shift;
    
    my $mgr = $self->{MGR};
    my @projects;

    # Projekt-id, -name, -cat
    my @projects_cat;
    
    # ### connect ###
    my $dbh = $mgr->connect;
    
    unless ($dbh->do(qq{LOCK TABLES $mgr->{ProTable} READ})) {
	warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
		     $mgr->{ProTable}, $dbh->ersstr);
    }
    my $sth = $dbh->prepare(qq{SELECT id, name, cat_id FROM $mgr->{ProTable} WHERE status = ?});
    
    # status
    unless ($sth->execute('0')) {
	warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
		     $mgr->{ProTable}, $dbh->errstr);
	$dbh->do("UNLOCK TABLES");
	$mgr->fatal_error($self->{C_MSG}->{DbError});
    }
    
    while (my @project = $sth->fetchrow_array()) {
	push (@projects, \@project);
    }
    
    $sth->finish;
    $dbh->do("UNLOCK TABLES");
    # ### disconnect ###
    

    # ### connect ###
    $dbh = $mgr->connect;
    
    unless ($dbh->do(qq{LOCK TABLES $mgr->{CatTable} READ})) {
	warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
		     $mgr->{CatTable}, $dbh->ersstr);
    }
    $sth = $dbh->prepare(qq{SELECT name FROM $mgr->{CatTable} WHERE id = ?});
    

    foreach my $project (@projects) {
	unless ($sth->execute($project->[2])) {
	    warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
			 $mgr->{CatTable}, $dbh->errstr);
	    $dbh->do("UNLOCK TABLES");
	    $mgr->fatal_error($self->{C_MSG}->{DbError});
	}
    
	while (my @cat = $sth->fetchrow_array()) {
	    push (@projects_cat, [$project->[0],$project->[1],$cat[0]]);
	}
    }
	
    $sth->finish;
    $dbh->do("UNLOCK TABLES");
    # ### disconnect ###
    

    return @projects_cat;
}



#====================================================================================================#
# SYNOPSIS: fetch_project_members($pid);
# PURPOSE:  holt die uid aller Projektmitglieder
# RETURN:   \@(id)
#====================================================================================================#
sub fetch_project_members {
    
    my $self = shift;
    my $pid = shift;
    
    my $mgr = $self->{MGR};
    
    my @fetched_ids;
    
    # ### connect ###
    my $dbh = $mgr->connect;
    unless ($dbh->do(qq{LOCK TABLES $mgr->{ProUserTable} READ})) {
	warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
		     $mgr->{ProUserTable}, $dbh->ersstr);
    }
    
    my $sth = $dbh->prepare(qq{SELECT user_id FROM $mgr->{ProUserTable} WHERE project_id = ?});
    
    unless ($sth->execute($pid)) {
	warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
		     $mgr->{ProUserTable}, $dbh->errstr);
	$dbh->do("UNLOCK TABLES");
	$mgr->fatal_error($self->{C_MSG}->{DbError});
    }
    
    # Alle (user_id, project_id) nach fetched_ids fetchen
    while (my $user_id = $sth->fetchrow_array()) {
	push (@fetched_ids, $user_id);
    }
    
    $sth->finish;
    $dbh->do("UNLOCK TABLES");
    # ### disonnect ###
    
    return \@fetched_ids;
}


#====================================================================================================#
# SYNOPSIS: get_project_name($pid);
# PURPOSE:  ermittelt den Namen eines Projektes
# RETURN:   $name
#====================================================================================================#
sub get_project_name {
    
    my $self = shift;
    my $pid = shift;
    
    my $mgr = $self->{MGR};
    
    my @fetched_ids;
    
    # ### connect ###
    my $dbh = $mgr->connect;
    unless ($dbh->do(qq{LOCK TABLES $mgr->{ProTable} READ})) {
	warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
		     $mgr->{ProTable}, $dbh->ersstr);
    }
    
    my $sth = $dbh->prepare(qq{SELECT name FROM $mgr->{ProTable} WHERE id = ?});
    
    unless ($sth->execute($pid)) {
	warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
		     $mgr->{ProTable}, $dbh->errstr);
	$dbh->do("UNLOCK TABLES");
	$mgr->fatal_error($self->{C_MSG}->{DbError});
    }
    
    my $name = $sth->fetchrow_array();
    
    $sth->finish;
    $dbh->do("UNLOCK TABLES");
    # ### disonnect ###
    
    return $name;
}



#====================================================================================================#
# SYNOPSIS: fetch_users($status,$type);
# PURPOSE:  ermittelt Ids aller existierenden User (status: 0=inaktiv, 1=aktiv)
# RETURN:   \@(id)
#====================================================================================================#
sub fetch_users {
    
    my $self = shift;
    my $status = shift || 1;
    my $type = shift || undef;
    my $mgr = $self->{MGR};
    
    my @uids;
    
    # ### connect ###
    my $dbh = $mgr->connect;
    unless ($dbh->do(qq{LOCK TABLES $mgr->{UserTable} READ})) {
	warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
		     $mgr->{UserTable}, $dbh->ersstr);
    }
    my $sth;
    if (defined $type) {
	$sth = $dbh->prepare(qq{SELECT id FROM $mgr->{UserTable} WHERE status = ? AND type = ?});
	unless ($sth->execute("$status","$type")) {
	    warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
			 $mgr->{UserTable}, $dbh->errstr);
	    $dbh->do("UNLOCK TABLES");
	    $mgr->fatal_error($self->{C_MSG}->{DbError});
	}
    } else {
	$sth = $dbh->prepare(qq{SELECT id FROM $mgr->{UserTable} WHERE status = ?});
	unless ($sth->execute("$status")) {
	    warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
			 $mgr->{UserTable}, $dbh->errstr);
	    $dbh->do("UNLOCK TABLES");
	    $mgr->fatal_error($self->{C_MSG}->{DbError});
	}
    }
    
    while (my $id = $sth->fetchrow_array()) {
	push (@uids, $id);
    }
    
    $sth->finish;
    $dbh->do("UNLOCK TABLES");
    # ### disconnect ###
    
    return \@uids;
} 

1;
# end of file
