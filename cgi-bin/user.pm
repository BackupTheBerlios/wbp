package user;

use Class::Singleton;
use base 'Class::Singleton';
use user_config;
use vars qw($VERSION $C_MSG $C_TMPL);
use strict;

$VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/;

$C_MSG = $user_config::MSG;
$C_TMPL = $user_config::TMPL;

sub parameter {

	my $self = shift;
	my $mgr  = shift;
	
	if (defined $mgr->{CGI}->param('method')) {
	    if ($mgr->{CGI}->param('method') eq "edit") {
		if (defined $mgr->{CGI}->param('user')) {
		    $self->user_edit($mgr, $mgr->{CGI}->param('user'));
		}
	    }
	    if ($mgr->{CGI}->param('method') eq "aktiv") {
		if (defined $mgr->{CGI}->param('user')) {
		    $self->user_aktiv($mgr, $mgr->{CGI}->param('user'));
		}
	    }
	    if ($mgr->{CGI}->param('method') eq "inaktiv") {
		if (defined $mgr->{CGI}->param('user')) {
		    $self->user_inaktiv($mgr, $mgr->{CGI}->param('user'));
		}
	    }
	    if ($mgr->{CGI}->param('method') eq "ok") {
		if (defined $mgr->{CGI}->param('user')) {
		    $self->user_ok($mgr, $mgr->{CGI}->param('user'));
		}
	    }
	}  else {
	    $self->user_menu($mgr);
	}
	
	return 1;
}

sub user_menu {

	my $self = shift;
	my $mgr	 = shift;
	
	$mgr->{TmplData} {FORM} = $mgr->my_url;
	$mgr->{Template} = $C_TMPL->{UserTmpl};	
	
	my $usertype = $mgr->{UserType};
	$mgr->{TmplData} {USER_TYPE} = sprintf($usertype);	

	my $dbh = $mgr->connect;
	my $sth = $dbh->prepare(qq{SELECT * FROM $mgr->{UserTable}});
        
	unless ($sth->execute()) {
	    warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{UserTable}, $dbh->{DbError});
	    $mgr->fatal_error($message_config::MSG->{DbError});
	}
	
	my $loop_data;
	my $href;
	while (my $ref = $sth->fetchrow_arrayref()) {
	    if ($ref -> [7] eq '1') {
	        $href = {
    	    	    ID        => sprintf($ref -> [0]),
		    USERNAME  => sprintf($ref -> [1]),
		    FIRSTNAME => sprintf($ref -> [3]),
		    LASTNAME  => sprintf($ref -> [4]),
		    TYPE      => sprintf($ref -> [6]),
		    AKTIV => sprintf(" "),
		    FORM => $mgr->my_url
		};
	    } else {
		$href = {
    	    	    ID        => sprintf($ref -> [0]),
		    USERNAME  => sprintf($ref -> [1]),
		    FIRSTNAME => sprintf($ref -> [3]),
		    LASTNAME  => sprintf($ref -> [4]),
		    TYPE      => sprintf($ref -> [6]),
		    INAKTIV => sprintf(" "),
		    FORM => $mgr->my_url
		};
	    }
	    push @$loop_data, $href;
	}
	$mgr->{TmplData} {USERLIST_LOOP} = $loop_data;	

	$mgr->fill;
	
	1;
}

sub user_edit {

    my $self = shift;
    my $mgr	 = shift;
    my $id	 = shift;
	
    my $dbh = $mgr->connect;
    my $sth = $dbh->prepare( qq{ SELECT * FROM $mgr->{UserTable} WHERE id = $id });
 	
    unless ($sth->execute()) {
	warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{UserTable}, $dbh->{DbError});
        $mgr->fatal_error($message_config::MSG->{DbError});
    }
 	
    my $ref = $sth->fetchrow_arrayref();
  
    $mgr->{TmplData} {ID}        = $ref -> [0];
    $mgr->{TmplData} {USERNAME}  = $ref -> [1];
#   $mgr->{TmplData} {PASSWORD}  = $ref -> [2];
    $mgr->{TmplData} {FIRSTNAME} = $ref -> [3];
    $mgr->{TmplData} {LASTNAME}  = $ref -> [4];
    $mgr->{TmplData} {EMAIL}     = $ref -> [5];
    $mgr->{TmplData} {TYPE}      = $ref -> [6];
    $mgr->{TmplData} {DESC}      = $ref -> [8];
 
    $mgr->{Template} = $C_TMPL->{UserEditTmpl};
    $mgr->{TmplData} {FORM} = $mgr->my_url."&method=ok&user=$ref->[0]";
    $mgr->fill;		
    1;

}

sub user_add {

	my $self = shift;
	my $mgr  = shift;
	
	$mgr->{Template} = $C_TMPL->{UserAddTmpl};
	
	$mgr->fill;
	
	1;

}

sub user_inaktiv {

    my $self = shift;
    my $mgr  = shift;
    my $id   = shift;

    my $dbh = $mgr->connect;
    my $sth = $dbh->prepare( qq{ UPDATE $mgr->{UserTable} SET STATUS = '0' WHERE id = $id });
        
    unless ($sth->execute()) {
        warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{UserTable}, $dbh->{DbError});
        $mgr->fatal_error($message_config::MSG->{DbError});
    }
    
    $self->user_menu($mgr);
    
    1;
}

sub user_aktiv {

    my $self = shift;
    my $mgr  = shift;
    my $id   = shift;

    my $dbh = $mgr->connect;
    my $sth = $dbh->prepare( qq{ UPDATE $mgr->{UserTable} SET STATUS = '1' WHERE id = $id } );
        
    unless ($sth->execute()) {
        warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{UserTable}, $dbh->{DbError});
        $mgr->fatal_error($message_config::MSG->{DbError});
    }

    $self->user_menu($mgr);
    
    1;
}

sub user_ok {

    my $self = shift;
    my $mgr  = shift;
    my $id   = shift;
    
    my $dbh = $mgr->connect;

    my $username = $mgr->{CGI}->param('USERNAME');
    if ($username gt "") {
	my $sth = $dbh->prepare( qq{ UPDATE $mgr->{UserTable} SET USERNAME = $username WHERE id = $id } );
    
	unless ($sth->execute()) {
    	    warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{UserTable}, $dbh->{DbError});
    	    $mgr->fatal_error($message_config::MSG->{DbError});
	}
    }

    $self->user_menu($mgr);
    
    1;
    
}

1;
