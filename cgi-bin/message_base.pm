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


# --- fetcht (id, firstname, lastname, username) aller User ---
# TODO Nach aktiv und inaktiv unterscheiden
sub fetch_users {
 
        my $self = shift;
 
        my $mgr = $self->{MGR};
	my @users;


 	# ### connect ###
        my $dbh = $mgr->connect;
        my $sth = $dbh->prepare(qq{SELECT id, firstname, lastname, username FROM $mgr->{UserTable}});
 
        unless ($sth->execute()) {
                warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
                        $mgr->{UserTable}, $dbh->errstr);
                $mgr->fatal_error($self->{C_MSG}->{DbError});
        }

	while (my ($id, $firstname, $lastname, $username) = $sth->fetchrow_array()) {
		push (@users, [$id, $firstname, $lastname, $username]);
	}

	$sth->finish;
	# ### disconnect ###


        return @users;
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


# --- Neue Messages in die Send-Table des Empfaengers, in die Receive-Table fuer alle
# --- Empfaenger, sowie die Verknuepfung ind die ToUser-Table einfuegen 
# --- insert_new_messages(\@uid,$subject,$content);
# TODO parent-id, datum
sub insert_new_messages {

        my $self = shift;
	my $uids = shift;
	my $subject = shift;
	my $content = shift;

        my $mgr = $self->{MGR};

	my $to_uid;
	my $from_uid = $mgr->{UserId};
	my $parent_mid = 0; # TODO
	my $date = "1001-01-01 01:01:01"; # TODO
	my $mid = 0; # ist auto_increment, daher 'mysql_insertid'


	# ### connect ###
        my $dbh = $mgr->connect;

	# Message in Send-Table einfuegen
        my $sth = $dbh->prepare(qq{INSERT INTO $mgr->{MSendTable}
				   (from_uid, parent_mid, date, subject, content) values
				       ($from_uid, $parent_mid, "$date", "$subject", "$content");});

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
				       (mid, from_uid, to_uid, parent_mid, date, subject, content) values
					   ($mid, $from_uid, $to_uid, $parent_mid, "$date", "$subject", "$content");});

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




# --- fetcht (mid, from_uid, parent_mid, date, subject, content) aller erhaltenen Messages ---
sub fetch_received_messages{
 
        my $self = shift;
 
        my $mgr = $self->{MGR};

	my @messages;
	my $my_uid = $mgr->{UserId};
	
	# ### connect ###
        my $dbh = $mgr->connect;
        my $sth = $dbh->prepare(qq{SELECT mid, from_uid, parent_mid, date, subject, content FROM $mgr->{MReceiveTable} WHERE to_uid = $my_uid});
 
        unless ($sth->execute()) {
                warn sprintf("[Error]: Trouble selecting from [%s]. Reason: [%s].",
                        $mgr->{MReceiveTable}, $dbh->errstr);
                $mgr->fatal_error($self->{C_MSG}->{DbError});
        }

	while (my ($mid, $from_uid, $parent_mid, $date, $subject, $content) = $sth->fetchrow_array()) {
		push (@messages, [$mid, $from_uid, $parent_mid, $date, $subject, $content]);
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
