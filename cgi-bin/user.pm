package user;

use Class::Singleton;
use base 'Class::Singleton';
use user_config;
use vars qw($VERSION $C_MSG $C_TMPL);
use strict;
# use Email::Valid;

$VERSION = sprintf "%d.%03d", q$Revision: 1.11 $ =~ /(\d+)\.(\d+)/;

$C_MSG = $user_config::MSG;
$C_TMPL = $user_config::TMPL;

sub parameter {

	my $self = shift;
	my $mgr  = shift;
	my $cgi  = $mgr->{CGI};
	
	# um zu einer Suchliste zurueckkehren zu koennen
	my $flag = $mgr->{Session}->get("edit") || "0";
	
	# D-Benutzer werden rausgeschmissen
	if ($mgr->{UserType} eq 'D') {
	    1;
	} else {
	
            # Post-Parameter ============================================
	    # Benutzer in der Datenbank suchen
	    if (defined($cgi->param('search'))) {
    		$self->user_search($mgr, 1);
    	    }
	    # Aenderungen bestaetigen
	    elsif (defined($cgi->param('ok'))) {
		$self->user_ok($mgr);
	    }
	    # neue Benutzer anlegen
	    elsif (defined($cgi->param('add0'))) {
		$self->user_add0($mgr);
	    }
	    elsif (defined($cgi->param('add'))) {
		$self->user_add($mgr);
	    }
	    
	    # GET-Parameter =============================================
	    elsif (defined($cgi->param('method'))) {
	
		my $method = $cgi->param('method');
	
		# Benutzerdaten editieren
		if ($method eq 'edit') {
		    $self->user_edit($mgr);
		}
		# Benutzerstatus wechseln
		elsif ($method eq 'aktiv') {
		    $self->user_aktiv($mgr);
		}
	        elsif ($method eq 'inaktiv') {
		    $self->user_inaktiv($mgr);
		}
	    }	
	    # zurueckkehren zu einer Suchliste
	    elsif ($flag eq '1') {
		$self->user_search($mgr, 0);
	    }
	    # Benutzerstartseite
	    else {
		$self->user_start($mgr);
	    }
	}
	return 1;
}

#=============================================================================
# SYNOPSIS: user_start($mgr, $type);
# PURPOSE:  Startseite mit Such und Anlegen Option
# RETURN: 1;
#=============================================================================
sub user_start {

    my $self = shift;
    my $mgr  = shift;    
    my $type = $mgr->{UserType};
    
    # Unterscheidung der Benutzerrechte
    if ($type eq 'A') {
	$mgr->{TmplData}{A_USER} = "A";
    } elsif ($type eq 'B') {
	$mgr->{TmplData}{A_USER} = "B";
    }

    $mgr->{Template} = $C_TMPL->{UserStartTmpl};
    $mgr->{TmplData} {FORM} = $mgr->my_url;
    
    $mgr->fill;
    
    # eventl. vorhandene Suchoptionen zuruecksetzen
    if ($mgr->{Session}->get("SearchName")) {
	$mgr->{Session}->del("SearchName");
    }
    if ($mgr->{Session}->get("SearchId")) {
	$mgr->{Session}->del("SearchId");
    }
    1;
    
}

#=============================================================================
# SYNOPSIS: user_search($mgr, $flag)
# PURPOSE:  sucht Benutzer nach Username oder ID und listet das Ergebniss
# RETURN: 1;
#=============================================================================
sub user_search {

    my $self = shift;
    my $mgr  = shift;
    my $flag = shift;
    my $type = $mgr->{UserType};
    my $loopdata;
    my $href;
    my $name;
    my $ref;
    my $search_name;
    my $search_id;

    # nachdem auf den Suchbutton geklickt wurde
    if ($flag == 1) {
	my $cgi = $mgr->{CGI};
	$search_name = $cgi->param('search_username') || "";
	$search_id = $cgi->param('search_id') || 0;
	
	# loesche alte Suchparameter aus der Session
	$mgr->{Session}->del("SearchName");
	$mgr->{Session}->del("SearchId");
    }
    # Rueckkehr zur Liste nach editieren
    if ($flag == 0) {
	$search_name = $mgr->{Session}->get("SearchName") || "";
	$search_id = $mgr->{Session}->get("SearchId") || "0";	
    }
        
    # sichere aktuelle Suchparameter in der Session
    $mgr->{Session}->set(SearchName => $search_name);
    $mgr->{Session}->set(SearchId => $search_id);

    my $sql = qq{SELECT * FROM $mgr->{UserTable}};
    if (length($search_name)>0) {
	$sql .= qq{ WHERE};
    } else {
	if ($search_id > 0) {
	    $sql .= qq{ WHERE};
	}
    }
    $flag = 0; # um spaeter ein AND zu setzen in der Datenbankanfrage
    if (length($search_name) > 0) {
        $sql .= qq{ username like '%$search_name%'};
	$flag = 1;
    }
    if ($search_id > 0) {
	if ($flag == 1) {
    	    $sql .= qq{ AND id = '$search_id'};
	    $flag = 1;
	} else {
	    $sql .= qq{ id = '$search_id'};
	    $flag = 1;
	}
    }
    
    my $dbh = $mgr->connect;
    unless ($dbh->do(qq{LOCK TABLES $mgr->{UserTable} READ})) {
    	warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
		     $mgr->{UserTable}, $dbh->ersstr);
    }
    my $sth = $dbh->prepare($sql);
    unless ($sth->execute()) {
    }
    
    # wenn das Flag veraendert wurde dann gibt es was zum anzeigen
    my $flag_search = 0; 

    while ($ref = $sth->fetchrow_arrayref()) {
        
	    my $date = $ref->[11];
	    $date = $mgr->format_date($date);
	    
	    if ($ref->[7] eq '1') {
	    # if user-state is active
	      if ($ref->[1] eq 'admin') {
	        $href = {
		    ID		=> $ref->[0],
		    USERNAME	=> $ref->[1],
		    FIRSTNAME   => $ref->[3],
		    LASTNAME	=> $ref->[4],
		    TYPE	=> $ref->[6],
		#    UPD_DT	=> $date,
		#    UPD_ID	=> $ref->[12],
		    FORM	=> $mgr->my_url,
		    ADMIN	=> sprintf(" ")
		};
	      } else {	# if not admin
		$href = {
		    ID		=> $ref->[0],
		    USERNAME	=> $ref->[1],
		    FIRSTNAME   => $ref->[3],
		    LASTNAME	=> $ref->[4],
		    TYPE	=> $ref->[6],
		    AKTIV	=> sprintf(" "),
		#    UPD_DT	=> $date,
		#    UPD_ID	=> $ref->[12],
		    FORM	=> $mgr->my_url
	        };
	    } # end if admin
	  } else {
	        $href = {
	    	ID		=> $ref->[0],
	    	USERNAME	=> $ref->[1],
	    	FIRSTNAME   	=> $ref->[3],
	    	LASTNAME	=> $ref->[4],
	    	TYPE		=> $ref->[6],
        	INAKTIV		=> sprintf(" "),
	    #	UPD_DT		=> $date,
	    #	UPD_ID		=> $ref->[12],
	    	FORM		=> $mgr->my_url
	        };
	    }
	
	    
	    if ($type eq "A") {
		# der Admin darf alle gefunden Benutzer sehen
	        push @$loopdata, $href;
		$flag_search = 1;
	    } elsif ($type eq "B") {
		# B sieht alle ausser den admin
	        if ($type gt $ref->[6]) {
		    # Beispiel:   B ist gt A -> nicht zeigen
	        } else {
		    push @$loopdata, $href;
		    $flag_search = 1;
		}
	    } else {
		if ($type lt $ref->[6]) {
		    # C-Benutzer sehen nur D-User -> C lt D
		    push @$loopdata, $href;
		    $flag_search = 1;
		}
	    }
    } # while 
    
    if ($flag_search == 1) {
	# es wurden Benutzer zum anzeigen gefunden
	
	$mgr->{TmplData} {FORM} = $mgr->my_url;    
	$mgr->{TmplData} {USERLOOP} = $loopdata;
        $mgr->{Template} = $C_TMPL->{UserListTmpl};
	if (defined($mgr->{Session}->get("edit"))) {
	    $mgr->{Session}->del("edit");
    	    $mgr->fill($C_MSG->{geaendert});
	} else {
	    $mgr->fill;
	}
    } else {
	# keine Daten zum anzeigen
	# also zurueck zum Startbildschirm
	
	$mgr->{TmplData} {FORM} = $mgr->my_url;
	$mgr->{Template} = $C_TMPL->{UserStartTmpl};
 	
	# Unterscheidung der Userrechte
	if ($type eq 'A') {
	    $mgr->{TmplData}{A_USER} = "A";
	} elsif ($type eq 'B') {
	    $mgr->{TmplData}{A_USER} = "B";
	}
	$mgr->fill($C_MSG->{nix_gefunden});
    }	
	
    $sth->finish;
    $dbh->do("UNLOCK TABLES");
    
    1;
}

#=============================================================================
# SYNOPSIS: user_aktiv($mgr);
# PURPOSE:  aendert den Status eines Benutzer nach aktiv 
# RETURN: 1;
#=============================================================================
sub user_aktiv {
    
    my $self = shift;
    my $mgr  = shift;
    my $id   = $mgr->{CGI}->param('user');
    
    my $dbh = $mgr->connect;
    unless ($dbh->do(qq{LOCK TABLES $mgr->{UserTable} WRITE})) {
	    warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
			 $mgr->{UserTable}, $dbh->ersstr);
    }
    
    my $sth = $dbh->prepare(qq{SELECT * FROM $mgr->{UserTable} WHERE id = '$id'});
    unless ($sth->execute()) {
    }
    
    my $ref = $sth->fetchrow_arrayref();
    
    if ($mgr->{UserType} eq "A") {
	# der Admin darf jeden Benutzer aktivieren
    
	$sth = $dbh->prepare(qq{UPDATE $mgr->{UserTable} SET STATUS = '1' WHERE id = '$id'});
	unless ($sth->execute()) {
	}
	$sth->finish;
	$dbh->do("UNLOCK TABLES");
    
        # zurueck zur Liste
	$self -> user_search($mgr, 0);
	
    } elsif ($mgr->{UserType} eq "B") {
	# alle ausser der Admin duerfen aktiviert werden
    
	if ($ref->[6] gt "A") {
	    $sth = $dbh->prepare(qq{UPDATE $mgr->{UserTable} SET STATUS = '1' WHERE id = '$id'});
	    unless ($sth->execute()) {
	    }
	    $sth->finish;
	    $dbh->do("UNLOCK TABLES");
    
    	    # zurueck zur Liste
	    $self -> user_search($mgr, 0);
	    
	} else {
	    # groessere Benutzertypen duerfen nicht veraendert werden
	    # hier kommt man normalerweise nicht hin
	    # ist aber fuer URL-Hacker noetig
	    
	    $sth->finish;
    	    $dbh->do("UNLOCK TABLES");
    	    $mgr->{Template} = $C_TMPL->{UserStartTmpl};
    	    $mgr->{TmplData} {FORM} = $mgr->my_url;
    	    $mgr->fill($C_MSG->{nicht_erlaubt});
	}
    } elsif ($mgr->{UserType} eq "C") {
	# C-Benutzer duerfen nur D-Benutzer veraendern
    
	if ($ref->[6] eq "D") {
	    $sth = $dbh->prepare(qq{UPDATE $mgr->{UserTable} SET STATUS = '1' WHERE id = '$id'});
	    unless ($sth->execute()) {
	    }
	    $sth->finish;
	    $dbh->do("UNLOCK TABLES");
	    
	    $self -> user_search($mgr, 0);
	} else {
	    # groessere Benutzertypen duerfen nicht veraendert werden
	    # hier kommt man normalerweise nicht hin
	    # ist aber fuer URL-Hacker noetig
	     
	    $sth->finish;
    	    $dbh->do("UNLOCK TABLES");
    	    $mgr->{Template} = $C_TMPL->{UserStartTmpl};
    	    $mgr->{TmplData} {FORM} = $mgr->my_url;
    	    $mgr->fill($C_MSG->{nicht_erlaubt});
	}    
    } else {}
    
    1;    
}

#=============================================================================
# SYNOPSIS: user_inaktiv($mgr);
# PURPOSE:  aendert den Status eines Benutzer nach inaktiv             
# RETURN: 1;
#=============================================================================
sub user_inaktiv {
    
    my $self = shift;
    my $mgr  = shift;
    my $id   = $mgr->{CGI}->param('user');
    
    my $dbh = $mgr->connect;
    unless ($dbh->do(qq{LOCK TABLES $mgr->{UserTable} WRITE})) {
	    warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
			 $mgr->{UserTable}, $dbh->ersstr);
    }
    
    my $sth = $dbh->prepare(qq{SELECT * FROM $mgr->{UserTable} WHERE id = '$id'});
    unless ($sth->execute()) {
    }
    
    my $ref = $sth->fetchrow_arrayref();
    
    if ($ref->[1] eq 'admin') {
	# der Admin darf nicht deaktiviert werden
	# wieder fuer Hacker
	
	$sth->finish;
	$dbh->do("UNLOCK TABLES");
	$mgr->{Template} = $C_TMPL->{UserStartTmpl};
	$mgr->{TmplData} {FORM} = $mgr->my_url;
	$mgr->fill($C_MSG->{admin_aktiv});

    } else {
    
    if ($mgr->{UserType} eq "A") {
	# der Admin darf jeden Benutzer aktivieren
	$sth = $dbh->prepare(qq{UPDATE $mgr->{UserTable} SET STATUS = '0' WHERE id = '$id'});
	unless ($sth->execute()) {
	}
	$sth->finish;
	$dbh->do("UNLOCK TABLES");
	
	# zurueck zur Liste
        $self -> user_search($mgr, 0);
	
    } elsif ($mgr->{UserType} eq "B") {
	# alle ausser Admin duerfen veraendert werden
	
	if ($ref->[6] gt "A") {
	    $sth = $dbh->prepare(qq{UPDATE $mgr->{UserTable} SET STATUS = '0' WHERE id = '$id'});
	    unless ($sth->execute()) {
	    }
	    $sth->finish;
	    $dbh->do("UNLOCK TABLES");
    
    	    #zurueck zur Liste
	    $self -> user_search($mgr, 0);
	    
	} else {
	    # groessere Benutzertypen duerfen nicht veraendert werden
	    # hier kommt man normalerweise nicht hin
	    # ist aber fuer URL-Hacker noetig
	    
	    $sth->finish;
    	    $dbh->do("UNLOCK TABLES");
    	    $mgr->{Template} = $C_TMPL->{UserStartTmpl};
    	    $mgr->{TmplData} {FORM} = $mgr->my_url;
    	    $mgr->fill($C_MSG->{nicht_erlaubt});
	}
    } elsif ($mgr->{UserType} eq "C") {
	# hier duerfen nur D-Benutzer veraendert werden
    
	if ($ref->[6] eq "D") {
	    $sth = $dbh->prepare(qq{UPDATE $mgr->{UserTable} SET STATUS = '0' WHERE id = '$id'});
	    unless ($sth->execute()) {
	    }
	    $sth->finish;
	    $dbh->do("UNLOCK TABLES");
	    
	    # zurueck zur Liste
	    $self -> user_search($mgr, 0);
	    
	} else {
	    # groessere Benutzertypen duerfen nicht veraendert werden
	    # hier kommt man normalerweise nicht hin
	    # ist aber fuer URL-Hacker noetig
	    
	    $sth->finish;
    	    $dbh->do("UNLOCK TABLES");
    	    $mgr->{Template} = $C_TMPL->{UserStartTmpl};
    	    $mgr->{TmplData} {FORM} = $mgr->my_url;
    	    $mgr->fill($C_MSG->{nicht_erlaubt});
	}    
    } else {
    }
    
    }
        
    1;
    
}

#=============================================================================
# SYNOPSIS: user_edit($mgr);
# PURPOSE:  gibt die Benutzerdaten zum editieren aus
# RETURN: 1;
#=============================================================================
sub user_edit {

    my $self = shift;
    my $mgr  = shift;
    my $id   = $mgr->{CGI}->param('user');
    my $type = $mgr->{UserType};
    
    my $dbh = $mgr->connect;
    unless ($dbh->do(qq{LOCK TABLES $mgr->{UserTable} READ})) {
	    warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
			 $mgr->{UserTable}, $dbh->ersstr);
    }
    
    my $sth = $dbh->prepare(qq{SELECT * FROM $mgr->{UserTable} WHERE id = '$id'});
    
    unless ($sth->execute()) {
    }
        
    my $ref = $sth->fetchrow_arrayref();
    
    $sth->finish;
    $dbh->do("UNLOCK TABLES");
    
    if ($ref->[6] lt $type) {
    # es duerfen keine hoeheren Benutzertypen editiert werden
    # wieder nur fuer URL-Hacker
    
	$mgr->{Template} = $C_TMPL->{UserStartTmpl};
    	$mgr->{TmplData} {FORM} = $mgr->my_url;
    	$mgr->fill($C_MSG->{nicht_erlaubt});
	return 1;
    }
    
    # alte Daten ins Formular    
    $mgr->{TmplData} {ID} = $ref->[0];
    $mgr->{TmplData} {USERNAME}	= $ref->[1];
    $mgr->{TmplData} {PASSWORD}	= $ref->[2];
    $mgr->{TmplData} {PASSWORD2} = $ref->[2];
    $mgr->{TmplData} {FIRST_NAME} = $ref->[3];
    $mgr->{TmplData} {LAST_NAME} = $ref->[4];
    $mgr->{TmplData} {EMAIL} = $ref->[5];
    $mgr->{TmplData} {DESC} = $ref->[8];
    $mgr->{TmplData} {OUTPUT} = $C_MSG->{edit_id};
    
    # Unterscheiden der Benutzertypen -> Auswahl angepasst
    if ($type eq "A") {
	if ($ref->[6] eq 'A') {
	    $mgr->{TmplData}{A_USER_A} = " ";
	}
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


#=============================================================================
# SYNOPSIS: user_ok($mgr);
# PURPOSE:  ueberprueft neue Benutzerdaten und uebernimmt sie gegebenenfalls
# RETURN: 1;
#=============================================================================
sub user_ok {
    
    my $self = shift;
    my $mgr  = shift;
    my $cgi  = $mgr->{CGI};
    my $error = 0;
    
    $mgr->{TmplData}{FORM} = $mgr->my_url;
    
    my $username = $cgi->param('username');
    my $id = $cgi->param('id');
    
    my $dbh = $mgr->connect;
    unless ($dbh->do(qq{LOCK TABLES $mgr->{UserTable} READ})) {
	    warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
			 $mgr->{UserTable}, $dbh->ersstr);
    }
    my $sth = $dbh->prepare(qq{SELECT * FROM  $mgr->{UserTable} WHERE username = '$username'});
    
    unless ($sth->execute()) {
    }
    
    # ueberprueft ob neuer Username nicht schon existiert
    while (my $ref = $sth->fetchrow_arrayref()) {
	if ($ref->[0] < $id) {
	    $error = 1;
	    $mgr->{TmplData}{USER_ERROR} = $username;
	} elsif ($ref->[0] > $id) {
	    $error = 1;
	    $mgr->{TmplData}{USER_ERROR} = $username; 
	}
    }
    
    $sth->finish;
    $dbh->do("UNLOCK TABLES");
    
    # ab hier werden die neue Angaben ueberprueft
    
    if (length($cgi->param('username')) == 0) {
	$error = 1;
    } elsif (length($cgi->param('username')) > 8) {
	$error = 1;
	$mgr->{TmplData}{USER_LANG} = " ";
    }
    
    if (length($cgi->param('password')) == 0) {
	$error = 1;
    } elsif (length($cgi->param('password')) > 8) {
	$error = 1;
	$mgr->{TmplData}{PASS_LANG} = " ";
    } elsif ($cgi->param('password') ne $cgi->param('password2')) {
	$error = 1;
	$mgr->{TmplData}{PASS_ERROR} = " ";
    } 
    
    if (length($cgi->param('first_name')) == 0) {
	$error = 1;
    } elsif (length($cgi->param('first_name')) > 30) {
	$error = 1;
	$mgr->{TmplData}{FIRST_LANG} = " ";
    }
    
    if (length($cgi->param('last_name')) == 0) {
	$error = 1;
    } if (length($cgi->param('last_name')) > 30) {
	$error = 1;
	$mgr->{TmplData}{LAST_LANG} = " ";
    }
    
    my $email = $cgi->param('email');
    if (length($cgi->param('email')) == 0) {
	$error = 1;
    } elsif (length($cgi->param('email')) > 100) {
	$error = 1;
	$mgr->{TmplData}{MAIL_LANG} = " ";
#    } elsif (Email::Valid->address($email)) {
#    } else {
#	$error = 1;
#	$mgr->{TmplData}{BAD_MAIL} = " ";
    }
    
    if (length($cgi->param('desc')) > 500) {
	$error = 1;
	$mgr->{TmplData}{DESC_LANG} = " ";
    }
    
    # wenn Fehler aufgetreten sind dann fuelle die Textfelder 
    # mit den restl Daten wieder auf
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

	my $type = $mgr->{UserType};
	my $edit_type = $cgi->param('type');
    
	# hier wieder die Auswahl der angeboten Usertypen
	if ($type eq "A") {
	    if ($edit_type eq 'A') {
		$mgr->{TmplData}{A_USER_A} = " ";
	    }
	    if ($edit_type eq 'B') {
		$mgr->{TmplData}{A_USER_B} = " ";
	    }
	    if ($edit_type eq "C") {
		$mgr->{TmplData}{A_USER_C} = " ";
	    }
	    if ($edit_type eq 'D') {
		$mgr->{TmplData}{A_USER_D} = " ";
	    }
	} elsif ($type eq 'B') {
	    if ($edit_type eq "B") {
		$mgr->{TmplData}{A_USER_B} = " ";
	    }
	    if ($edit_type eq "C") {
		$mgr->{TmplData}{A_USER_C} = " ";
    	    }
	    if ($edit_type eq "D") {
		$mgr->{TmplData}{A_USER_D} = " ";
	    }
        } elsif ($type eq 'C') {
	    $mgr->{TmplData}{C_USER} = " ";
	}

	$mgr->fill;
    
    } else {
	
	# alles Felder waren ordnungsgemaess gefuellt, also
	# werden die neuen Daten in die Datenbank uebernommen
    
	my $password = $cgi->param('password');
	my $firstname = $cgi->param('first_name');
	my $lastname = $cgi->param('last_name');
	my $email = $cgi->param('email');
	my $desc = $cgi->param('desc') || "";
	my $type = $cgi->param('type');
	my $upd_dt = $mgr->now();
	my $upd_id = $mgr->{UserId};
	
	my $dbh = $mgr->connect;
	unless ($dbh->do(qq{LOCK TABLES $mgr->{UserTable} WRITE})) {
	    warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
			 $mgr->{UserTable}, $dbh->ersstr);
	}
    
	$sth = $dbh->prepare(qq{UPDATE $mgr->{UserTable} 
		    SET username = "$username", password = "$password", firstname = "$firstname", lastname = "$lastname", email = "$email",
    		        desc_user = "$desc", type = "$type", upd_dt = "$upd_dt", upd_id = "$upd_id"
		    WHERE id = "$id"});
        unless ($sth->execute()) {}
	
	$sth->finish;
	$dbh->do("UNLOCK TABLES");
	
	# das Script soll wissen, dass es wieder die alte Suchliste
	# anzeigen soll
	$mgr->{Session}->set("edit" => "1");
	
	# zurueck zur Liste
	$self -> user_search($mgr, 0);
	
    }
    
    
    1;
}

#=============================================================================
# SYNOPSIS: user_add0($mgr);
# PURPOSE:  zeigt leeres Formular fuer neue Benutzerdaten
# RETURN: 1;
#=============================================================================
sub user_add0 {
    
    my $self = shift;
    my $mgr  = shift;
    
    # der neue Benutzertyp steht hier schon fest
    # die ID ist autoinkrement
    my $type = $mgr->{CGI}->param('type');
    
    $mgr->{TmplData}{FORM} = $mgr->my_url;
    $mgr->{TmplData}{TYPE} = $mgr->{CGI}->param('type');
    $mgr->{TmplData}{OUTPUT} = $C_MSG->{anlegen1}.$type.$C_MSG->{anlegen2};
    $mgr->{Template} = $C_TMPL->{UserAdd0Tmpl};
    
    $mgr->fill();
    1;
}

#=============================================================================
# SYNOPSIS: user_add($mgr);
# PURPOSE:  Ueberpruefung der neuen Benutzerdaten und gegebenenfalls Uebernahme
# RETURN: 1;
#=============================================================================
sub user_add {
    
    my $self = shift;
    my $mgr  = shift;
    my $cgi  = $mgr->{CGI};
    my $error = 0;         # Error-Flag
    my $username;
    my $dbh;
    my $sth;
    
    my $type = $mgr->{CGI}->param('type');
    
    $mgr->{TmplData}{FORM} = $mgr->my_url;
    
    if (defined($cgi->param('username'))) {
    # wenn ein neuer Username angegeben ist ...
    
	$username = $cgi->param('username');
    
        $dbh = $mgr->connect;
	unless ($dbh->do(qq{LOCK TABLES $mgr->{UserTable} READ})) {
	    warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
			 $mgr->{UserTable}, $dbh->ersstr);
	}
	$sth = $dbh->prepare(qq{SELECT * FROM  $mgr->{UserTable} WHERE username = '$username'});
    
	unless ($sth->execute()) {
	}
    
	# ... sehe nach ob er schon existiert
	while (my $ref = $sth->fetchrow_arrayref()) {
	    $error = 1;
	    $mgr->{TmplData}{USER_ERROR} = $username;
	}
	$sth->finish;
	$dbh->do("UNLOCK TABLES");
    }
    
    # Ueberpruefe die restl. Angaben
    
    if (length($cgi->param('username')) == 0) {
	$error = 1;
    } elsif (length($cgi->param('username')) > 8) {
	$error = 1;
	$mgr->{TmplData}{USER_LANG} = " ";
    }
    
    if (length($cgi->param('password')) == 0) {
	$error = 1;
    } elsif (length($cgi->param('password')) > 8) {
	$error = 1;
	$mgr->{TmplData}{PASS_LANG} = " ";
    } elsif ($cgi->param('password') ne $cgi->param('password2')) {
	$error = 1;
	$mgr->{TmplData}{PASS_ERROR} = " ";
    } 
    
    if (length($cgi->param('first_name')) == 0) {
	$error = 1;
    } elsif (length($cgi->param('first_name')) > 30) {
	$error = 1;
	$mgr->{TmplData}{FIRST_LANG} = " ";
    }
    
    if (length($cgi->param('last_name')) == 0) {
	$error = 1;
    } if (length($cgi->param('last_name')) > 30) {
	$error = 1;
	$mgr->{TmplData}{LAST_LANG} = " ";
    }
    
    my $email = $cgi->param('email');
    if (length($cgi->param('email')) == 0) {
	$error = 1;
    } elsif (length($cgi->param('email')) > 100) {
	$error = 1;
	$mgr->{TmplData}{MAIL_LANG} = " ";
#    } elsif (Email::Valid->address($email)) {
#    } else {
#	$error = 1;
#	$mgr->{TmplData}{BAD_MAIL} = " ";
    }
    
    if (length($cgi->param('desc')) > 500) {
	$error = 1;
	$mgr->{TmplData}{DESC_LANG} = " ";
    }
    
    if ($error == 1) {
	
	# es gab Fehlerhafte Angaben, also wieder die
	# Textfelder fuellen
    
	$mgr->{TmplData}{USERNAME} = $cgi->param('username');
	$mgr->{TmplData}{PASSWORD} = $cgi->param('password');
	$mgr->{TmplData}{PASSWORD2} = $cgi->param('password2');
	$mgr->{TmplData}{FIRST_NAME} = $cgi->param('first_name');
	$mgr->{TmplData}{LAST_NAME} = $cgi->param('last_name');
	$mgr->{TmplData}{EMAIL} = $cgi->param('email');
	$mgr->{TmplData}{TYPE} = $cgi->param('type');
	$mgr->{TmplData}{DESC} = $cgi->param('desc');
	$mgr->{TmplData}{OUTPUT} = $C_MSG->{anlegen1}.$type.$C_MSG->{anlegen2};
	$mgr->{Template} = $C_TMPL->{UserAddTmpl};

	$mgr->fill;
    
    } else {
    
	# alle Angaben sind brauchbar, also wird der neue
	# Benutzer angelegt
	
	my $password = $cgi->param('password');
	my $firstname = $cgi->param('first_name');
	my $lastname = $cgi->param('last_name');
	my $email = $cgi->param('email');
	my $desc = $cgi->param('desc') || " ";
	my $upd_dt = $mgr->now();
	my $upd_id = $mgr->{UserId};
    
	my $dbh = $mgr->connect;
	unless ($dbh->do(qq{LOCK TABLES $mgr->{UserTable} WRITE})) {
	    warn sprintf("[Error]: Trouble locking table [%s]. Reason: [%s].",
			 $mgr->{UserTable}, $dbh->ersstr);
	}

	my $sth;	
	
	$sth = $dbh->prepare(qq{INSERT INTO $mgr->{UserTable}
		     (username, password, firstname, lastname, email, type, desc_user, status, upd_dt, upd_id, ins_dt, ins_id) values
		     ('$username', '$password', '$firstname', '$lastname', '$email', '$type', '$desc', '1', '$upd_dt', '$upd_id', '$upd_dt', '$upd_id')});
	unless ($sth->execute()) {}
	
	$sth->finish;
	$dbh->do("UNLOCK TABLES");
	
        # jetzt geht es zurueck zum Startbildschirm, also muss noch
	# der Benutzertyp festgestellt werden
	# ( wegen der Auswahl bei "neuen User anlegen" )
	if ($mgr->{UserType} eq 'A') {
	    $mgr->{TmplData}{A_USER} = "A";
        } elsif ($mgr->{UserType} eq 'B') {
    	    $mgr->{TmplData}{A_USER} = "B";
	}

	$mgr->{Template} = $C_TMPL->{UserStartTmpl};
	
	$mgr->fill($C_MSG->{angelegt});
    }
    
    
    1;
}


1;
