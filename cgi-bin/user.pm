package user;

use Class::Singleton;
use base 'Class::Singleton';
use user_config;
use vars qw($VERSION $C_MSG $C_TMPL);
use strict;

$VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/;

$C_MSG = $user_config::MSG;
$C_TMPL = $user_config::TMPL;

sub parameter {

	my $self = shift;
	my $mgr  = shift;
	my $cgi  = $mgr->{CGI};
	
	if ($mgr->{UserType} eq 'D') {
	    $mgr->{Template} = $C_TMPL->{WeiterZmpl};
	    $mgr->{TmplData}{OUTPUT} = "Leider kein Zutritt f&uuml;r Sie";
	} else {
	
            if (defined($cgi->param('search'))) {
    		$self->user_search($mgr);
    	    }
	    elsif (defined($cgi->param('ok'))) {
		$self->user_ok($mgr);
	    }
	    elsif (defined($cgi->param('add'))) {
		$self->user_add($mgr);
	    }
	    elsif (defined($cgi->param('method'))) {
	
		my $method = $cgi->param('method');
	
		if ($method eq 'edit') {
		    $self->user_edit($mgr);
		}
		elsif ($method eq 'aktiv') {
		    $self->user_aktiv($mgr);
		}
	        elsif ($method eq 'inaktiv') {
		    $self->user_inaktiv($mgr);
		}
	        elsif ($method eq 'edit') {
		$self->user_edit($mgr);
		}
	    }	
	    else {
		$self->user_start($mgr);
	    }
	}
	return 1;
}

sub user_start {

    my $self = shift;
    my $mgr  = shift;    
    
    if ($mgr->{UserType} eq 'A') {
	$mgr->{TmplData}{A_USER} = "A";
    } elsif ($mgr->{UserType} eq 'B') {
	$mgr->{TmplData}{A_USER} = "B";
    }

#    $mgr->{TmplData}{USERTYPE} = $mgr->{UserType};

    $mgr->{Template} = $C_TMPL->{UserStartTmpl};
    $mgr->{TmplData} {FORM} = $mgr->my_url;
    
    $mgr->fill;
    1;
    
}

sub user_search {

    my $self = shift;
    my $mgr  = shift;
    my $cgi  = $mgr->{CGI};
    my $type = $mgr->{UserType};
    my $search = " ";
    
    if (defined($cgi->param('username'))) {
	$search = $cgi->param('username');
    }
    
    my $dbh = $mgr->connect;
    my $sth = $dbh->prepare(qq{SELECT * FROM $mgr->{UserTable}});
    
    unless ($sth->execute()) {
    }
    
    my $loopdata;
    my $href;
    my $name;
    my $ref;
    my $flag = 0;

    while ($ref = $sth->fetchrow_arrayref()) {
        
	if ($ref->[1] =~ /\L$search\E/) {
	    $flag = 1;
	    if ($ref->[7] eq '1') {
		$href = {
		    ID		=> $ref->[0],
		    USERNAME	=> $ref->[1],
		    FIRSTNAME   => $ref->[3],
		    LASTNAME	=> $ref->[4],
		    TYPE	=> $ref->[6],
		    AKTIV	=> sprintf(" "),
		    FORM	=> $mgr->my_url
		};
	    } else {
		$href = {
		    ID		=> $ref->[0],
		    USERNAME	=> $ref->[1],
		    FIRSTNAME   => $ref->[3],
		    LASTNAME	=> $ref->[4],
		    TYPE	=> $ref->[6],
		    INAKTIV	=> sprintf(" "),
		    FORM	=> $mgr->my_url
		};
	    }
	    if ($type eq "A") {
		# Admin sieht alle
		push @$loopdata, $href;
	    } elsif ($type eq "B") {
		if ($type gt $ref->[6]) {
		    # Usertyp liegt hoeher als eigener
		} else {
		    # Usertyp liegt tiefer
		    push @$loopdata, $href;
		}
	    } else {
		if ($type lt $ref->[6]) {
		    # Type sieht alle Typ D
		    push @$loopdata, $href;
		}
	    }
	}
    }
    if ($flag == 1) {
	$mgr->{TmplData} {USERLOOP} = $loopdata;
        $mgr->{Template} = $C_TMPL->{UserListTmpl};
    } else {
	$mgr->{TmplData}{OUTPUT} = "keine Entsprechungen gefunden";
	$mgr->{Template} = $C_TMPL->{WeiterTmpl};
    }	
	
    $mgr->{TmplData} {FORM} = $mgr->my_url;    
    $mgr->fill;
    1;
}

sub user_aktiv {
    
    my $self = shift;
    my $mgr  = shift;
    my $id   = $mgr->{CGI}->param('user');
    
    my $dbh = $mgr->connect;
    my $sth = $dbh->prepare(qq{UPDATE $mgr->{UserTable} SET STATUS = '1' WHERE id = $id});
    
    unless ($sth->execute()) {
    }
    
    $mgr->{Template} = $C_TMPL->{WeiterTmpl};
    $mgr->{TmplData} {OUTPUT} = "Benutzer wurde aktiviert";
    $mgr->{TmplData} {FORM} = $mgr->my_url;
    
    $mgr->fill;

    1;
    
}

sub user_inaktiv {
    
    my $self = shift;
    my $mgr  = shift;
    my $id   = $mgr->{CGI}->param('user');
    
    my $dbh = $mgr->connect;
    my $sth = $dbh->prepare(qq{UPDATE $mgr->{UserTable} SET STATUS = '0' WHERE id = $id});
    
    unless ($sth->execute()) {
    }
     
    $mgr->{Template} = $C_TMPL->{WeiterTmpl};
    $mgr->{TmplData} {OUTPUT} = "Benutzer wurde deaktiviert";
    $mgr->{TmplData} {FORM} = $mgr->my_url;
    
    $mgr->fill;

    1;
    
}

sub user_edit {

    my $self = shift;
    my $mgr  = shift;
    my $id   = $mgr->{CGI}->param('user');
    
    my $dbh = $mgr->connect;
    my $sth = $dbh->prepare(qq{SELECT * FROM $mgr->{UserTable} WHERE id = '$id'});
    
    unless ($sth->execute()) {
    }
        
    my $ref = $sth->fetchrow_arrayref();
    
    $mgr->{TmplData} {ID} = $ref->[0];
    $mgr->{TmplData} {USERNAME}	= $ref->[1];
    $mgr->{TmplData} {PASSWORD}	= $ref->[2];
    $mgr->{TmplData} {FIRST_NAME} = $ref->[3];
    $mgr->{TmplData} {LAST_NAME} = $ref->[4];
    $mgr->{TmplData} {EMAIL} = $ref->[5];
    $mgr->{TmplData} {DESC} = $ref->[8];
    $mgr->{TmplData} {OUTPUT} = "User editieren: ID = ";
    
    my $type = $mgr->{UserType};
    
    if ($type eq "A") {
	if ($ref->[6] eq 'B') {
	    $mgr->{TmplData}{A_USER_B} = " ";
	}
	if ($ref->[6] eq "C") {
	    $mgr->{TmplData}{A_USER_C} = " ";
	}
	if ($ref->[6] eq 'D') {
	    $mgr->{TmplData}{A_USER_D} = " ";
	}
    } elsif ($type eq 'B') {
	if ($ref->[6] eq "B") {
	    $mgr->{TmplData}{A_USER_B} = " ";
	}
	if ($ref->[6] eq "C") {
	    $mgr->{TmplData}{A_USER_C} = " ";
	}
	if ($ref->[6] eq "D") {
	    $mgr->{TmplData}{A_USER_D} = " ";
	}
    } elsif ($type eq 'C') {
	    $mgr->{TmplData}{C_USER} = " ";
    }
            
    
    $mgr->{Template} = $C_TMPL->{UserEditTmpl};
    $mgr->{TmplData} {FORM} = $mgr->my_url;
    
    $mgr->fill;
    
    1;
    
}


sub user_ok {
    
    my $self = shift;
    my $mgr  = shift;
    my $cgi  = $mgr->{CGI};
    my $error = 0;
    
    $mgr->{TmplData}{FORM} = $mgr->my_url;
    
    my $username = $cgi->param('username');
    my $id = $cgi->param('id');
    
    my $dbh = $mgr->connect;
    my $sth = $dbh->prepare(qq{SELECT * FROM  $mgr->{UserTable} WHERE username = '$username'});
    
    unless ($sth->execute()) {
    }
    
    while (my $ref = $sth->fetchrow_arrayref()) {
	if ($ref->[0] < $id) {
	    $error = 1;
	    $mgr->{TmplData}{USER_ERROR} = $username;
	} elsif ($ref->[0] > $id) {
	    $error = 1;
	    $mgr->{TmplData}{USER_ERROR} = $username; 
	}
    }
    
    if ($cgi->param('username') lt " ") {
	$error = 1;
    }
    if ($cgi->param('password') lt " ") {
	$error = 1;
    } elsif ($cgi->param('password') ne $cgi->param('password2')) {
	$error = 1;
	$mgr->{TmplData}{PASS_ERROR} = " ";
    } 
    
    if ($cgi->param('first_name') lt " ") {
	$error = 1;
    }
    if ($cgi->param('last_name') lt " ") {
	$error = 1;
    }
    if ($cgi->param('email') lt " ") {
	$error = 1;
    }
    
    if ($error == 1) {
     	$mgr->{TmplData}{ID} = $id;
	$mgr->{TmplData}{USERNAME} = $cgi->param('username');
	$mgr->{TmplData}{PASSWORD} = $cgi->param('password');
	$mgr->{TmplData}{PASSWORD2} = $cgi->param('password2');
	$mgr->{TmplData}{FIRST_NAME} = $cgi->param('first_name');
	$mgr->{TmplData}{LAST_NAME} = $cgi->param('last_name');
	$mgr->{TmplData}{EMAIL} = $cgi->param('email');
	$mgr->{TmplData}{DESC} = $cgi->param('desc');
	$mgr->{TmplData} {OUTPUT} = "User editieren: ID = ";
	$mgr->{Template} = $C_TMPL->{UserEditTmpl};

	$mgr->fill;
    
    } else {
	
	my $password = $cgi->param('password');
	my $firstname = $cgi->param('first_name');
	my $lastname = $cgi->param('last_name');
	my $email = $cgi->param('email');
	my $desc = $cgi->param('desc');
	my $type = $cgi->param('type');
    
	$sth = $dbh->prepare(qq{UPDATE $mgr->{UserTable} SET username = '$username' WHERE id = $id});
        unless ($sth->execute()) {}
	$sth = $dbh->prepare(qq{UPDATE $mgr->{UserTable} SET password = '$password' WHERE id = $id});
        unless ($sth->execute()) {}
	$sth = $dbh->prepare(qq{UPDATE $mgr->{UserTable} SET firstname = '$firstname' WHERE id = $id});
        unless ($sth->execute()) {}
	$sth = $dbh->prepare(qq{UPDATE $mgr->{UserTable} SET lastname = '$lastname' WHERE id = $id});
        unless ($sth->execute()) {}
	$sth = $dbh->prepare(qq{UPDATE $mgr->{UserTable} SET email = '$email' WHERE id = $id});
        unless ($sth->execute()) {}
	$sth = $dbh->prepare(qq{UPDATE $mgr->{UserTable} SET desc_user = '$desc' WHERE id = $id});
        unless ($sth->execute()) {}
	$sth = $dbh->prepare(qq{UPDATE $mgr->{UserTable} SET type = '$type' WHERE id = $id});
	unless ($sth->execute()) {}
	
	$mgr->{TmplData}{OUTPUT} = "neue Userdaten &uuml;bernommen";
	$mgr->{Template} = $C_TMPL->{WeiterTmpl};

	$mgr->fill;
    }
    
    
    1;
}

sub user_add {
    
    my $self = shift;
    my $mgr  = shift;
    my $cgi  = $mgr->{CGI};
    my $error = 0;
    my $username;
    my $dbh;
    my $sth;
    
    my $type = $mgr->{CGI}->param('type');
    
    $mgr->{TmplData}{FORM} = $mgr->my_url;
    
    if (defined($cgi->param('username'))) {
	$username = $cgi->param('username');
    
        $dbh = $mgr->connect;
	$sth = $dbh->prepare(qq{SELECT * FROM  $mgr->{UserTable} WHERE username = '$username'});
    
	unless ($sth->execute()) {
	}
    
	while (my $ref = $sth->fetchrow_arrayref()) {
	    $error = 1;
	    $mgr->{TmplData}{USER_ERROR} = $username;
	}
    }
    
    my $dummy = " ";
    
    if ($cgi->param('username') lt $dummy) {
	$error = 1;
    }
    if ($cgi->param('password') lt $dummy) {
	$error = 1;
    } elsif ($cgi->param('password') ne $cgi->param('password2')) {
	$error = 1;
	$mgr->{TmplData}{PASS_ERROR} = " ";
    }    
    if ($cgi->param('first_name') lt $dummy) {
	$error = 1;
    }
    if ($cgi->param('last_name') lt $dummy) {
	$error = 1;
    }
    if ($cgi->param('email') lt $dummy) {
	$error = 1;
    }
    
    if ($error == 1) {
	$mgr->{TmplData}{USERNAME} = $cgi->param('username');
	$mgr->{TmplData}{PASSWORD} = $cgi->param('password');
	$mgr->{TmplData}{PASSWORD2} = $cgi->param('password2');
	$mgr->{TmplData}{FIRST_NAME} = $cgi->param('first_name');
	$mgr->{TmplData}{LAST_NAME} = $cgi->param('last_name');
	$mgr->{TmplData}{EMAIL} = $cgi->param('email');
	$mgr->{TmplData}{TYPE} = $cgi->param('type');
	$mgr->{TmplData}{DESC} = $cgi->param('desc');
	$mgr->{TmplData}{OUTPUT} = sprintf("neuen User vom Typ %s hinzuf&uuml;gen", $type);
	$mgr->{Template} = $C_TMPL->{UserAddTmpl};

	$mgr->fill;
    
    } else {
	
	my $password = $cgi->param('password');
	my $firstname = $cgi->param('first_name');
	my $lastname = $cgi->param('last_name');
	my $email = $cgi->param('email');
	my $desc = $cgi->param('desc');
	my $type = $cgi->param('type');
    
	my $dbh = $mgr->connect;
	my $sth;	
	
	$sth = $dbh->prepare(qq{INSERT INTO $mgr->{UserTable}
		     (username, password, firstname, lastname, email, type, desc_user, status) values
		     ('$username', '$password', '$firstname', '$lastname', '$email', '$type', '$desc', '1')});
	unless ($sth->execute()) {}
	
	$mgr->{TmplData}{OUTPUT} = "neuen User angelegt";
	$mgr->{Template} = $C_TMPL->{WeiterTmpl};

	$mgr->fill;
    }
    
    
    1;
}


1;
