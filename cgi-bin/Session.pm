package Session;

use Digest::MD5;
use fields (
	'ExpTime',
        'SessDir',
	'SessFile',
	'Sid'
);
use strict;
use vars qw(%FIELDS $VERSION);
 
$VERSION = sprintf "%d.%03d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/;

#====================================================================================================#
# SYNOPSIS: new($class, %par);
# PURPOSE:  Konstruktor der Klasse Session.pm.
# RETURN:   $self in den Namensraum von Session geblesst.
#====================================================================================================#
sub new {
        my ($class, %par) = @_;
        no strict "refs";
        my $self          = bless [\%{"$class\::FIELDS"}], $class;

	# Keys und Values initialisieren. 
        foreach (keys %par) {
                eval { $self->{$_} = $par{$_}; };
 
                if ($@) {
                        if ($@ =~ /No such array field/i) {
                                warn "Ignoring unknown key[$_]";
                        } else {
                                die $@;
                        }
                }
        }
        $self;
}

#====================================================================================================#
# SYNOPSIS: $self->start_session($self, %par);
# PURPOSE:  Anlegen einer Session und damit das schreiben in die Uebersichtsliste aller aktiven
#	    Sessions und dem schreiben einer neuen Sessiondatei.
# RETURN:   Die neue Sessionid.
#====================================================================================================#
sub start_session {
	my ($self, %par) = @_;

	# Sessionid generieren.
	my $sid      = $self->_create_sid();
	# Global zugreifbar machen.
	$self->{Sid} = $sid;
	# Die Zeit ausrechnen, wann die Session abgelaufen ist.
	my $time     = $self->_get_expires();

	my (%sessions, %sid);

	# Gesamt Sessiondatei schreiben.
	dbmopen %sessions, sprintf("%s/%s", $self->{SessDir}, $self->{SessFile}), 0644 
	or die "Can't create new session. Reason: $!"; 
		$sessions{$sid} = $time;
	dbmclose %sessions;
	# Eigentliche Sessiondatei schreiben.
	dbmopen %sid, sprintf("%s/%s", $self->{SessDir}, $sid), 0644 
	or die "Can't create new session. Reason: $!";
		foreach (keys %par) {
			$sid{$_} = $par{$_};
		}
	dbmclose %sid;
	# Sessionid zurueck geben.
	$sid;
}

#====================================================================================================#
# SYNOPSIS: $self->kill_session(|$sid); 
# PURPOSE:  Loescht eine Session komplett. Erst aus der Gesamt Sessiondatei und dann die Sessiondatei
#           selbst.
# RETURN:   true.
#====================================================================================================#
sub kill_session {
	my $self = shift;
	my $sid  = shift || undef;

	# Wurde eine Sessionid uebergeben?
	$sid = $self->{Sid} unless ($sid);

	my (%sessions, $dir_file, $pag_file);

	# Pfad zum loeschen zusammen bauen.
	$dir_file = sprintf("%s/%s.dir", $self->{SessDir}, $sid);
	$pag_file = sprintf("%s/%s.pag", $self->{SessDir}, $sid);

	# Session aus der Gesamt Session Datei loeschen.
	dbmopen %sessions, sprintf("%s/%s", $self->{SessDir}, $self->{SessFile}), 0644 
	or die "Can't open session file. Reason: $!";
		delete $sessions{$sid};
	dbmclose %sessions;

	# Eigentliche Sessiondateien loeschen.
	unlink $dir_file if (-e $dir_file);
	unlink $pag_file if (-e $pag_file);

	1;
}

#====================================================================================================#
# SYNOPSIS: $self->check_sid();
# PURPOSE:  Ueberprueft die zur Zeit gueltige Session auf Richtigkeit, also das Expiredate wird
#           ueberprueft.
# RETURN:   undef oder 1 bei Erfolg.
#====================================================================================================#
sub check_sid {
	my $self = shift;

	return undef unless ($self->{Sid});

	my %sessions;

	# Session ueberpruefen und vorher aus dem Gesamt Sessiondatei auslesen.
	dbmopen %sessions, sprintf("%s/%s", $self->{SessDir}, $self->{SessFile}), 0644
	or die "Can't open session file. Reason: $!";
		foreach (keys %sessions) {
			if ($_ eq $self->{Sid}) {
				dbmclose %sessions;
				return 1;
			}
		}
	dbmclose %sessions;

	undef;
}

#====================================================================================================#
# SYNOPSIS: $self->set(%par);
# PURPOSE:  Setzen von Sessionwerten in die Aktuelle Session.
# RETURN:   true.
#====================================================================================================#
sub set {
	my $self = shift;
	my %par  = @_;

	my %sid;

	# Schreiben der Sessionwerte in die Sessiondatei.
	dbmopen %sid, sprintf("%s/%s", $self->{SessDir}, $self->{Sid}), 0644 
	or die "Can't open session file. Reason: $!";
		foreach (keys %par) {
			next unless ($par{$_});
			$sid{$_} = $par{$_};
		}
	dbmclose %sid;

	1;	
}

#====================================================================================================#
# SYNOPSIS: $self->get($key);
# PURPOSE:  Auslesen eines Values zu einer bestimmten Session und dem dazu gehoerigen Schluessel.
# RETURN:   Der Wert, der zu dem uebergebenen Schluessel passt.
#====================================================================================================#
sub get {
	my $self = shift;
	my $key  = shift;

	my (%sid, $value);

	# Auslesen aus der Sessiondatei.
	dbmopen %sid, sprintf("%s/%s", $self->{SessDir}, $self->{Sid}), 0644 
	or die "Can't open session file. Reason: $!";
		$value = $sid{$key};
	dbmclose %sid;

	$value;
}

#====================================================================================================#
# SYNOPSIS: $self->del($key);
# PURPOSE:  Loeschen eines Wertes aus der aktiven Session durch den uebergebenen Schluessel.
# RETURN:   true;
#====================================================================================================#
sub del {
	my $self = shift;
	my $key  = shift;

	my %sid;

	# Loeschen des Wertes aus der Sessiondatei.
	dbmopen %sid, sprintf("%s/%s", $self->{SessDir}, $self->{Sid}), 0644 
	or die "Can't open session file. Reason: $!";
		delete $sid{$key};
	dbmclose %sid;
	
	1;	
}

#====================================================================================================#
# SYNOPSIS: $self->set_sid(|$sid);
# PURPOSE:  Eine neue Sessionid setzen oder die alte wenn vorhanden loeschen.
# RETURN:   true.
#====================================================================================================#
sub set_sid {
	my $self = shift;
	my $sid  = shift || undef;

	$self->{Sid} = $sid;

	1;
}

#====================================================================================================#
# SYNOPSIS: $self->get_sid();
# PURPOSE:  Die zur Zeit aktuelle Sessionid zurueck geben oder undef.
# RETURN:   siehe PURPOSE.
#====================================================================================================#
sub get_sid {
	my $self = shift;
	
	$self->{Sid} || undef;
}

#====================================================================================================#
# SYNOPSIS: $self->check_sessions(); 
# PURPOSE:  Ueberprueft alle zur Zeit aktiven Sessions und loescht gegebenen falls die abgelaufenen
#	    Sessions.
# RETURN:   true.
#====================================================================================================#
sub check_sessions {
	my $self = shift;

	my $time = time();
	my (%sessions, @old_sessions);

	dbmopen %sessions, sprintf("%s/%s", $self->{SessDir}, $self->{SessFile}), 0644 
	or die "Can't open session file. Reason: $!";
		foreach (keys %sessions) {
			if ($sessions{$_} < $time) {
				push (@old_sessions, $_);
				delete $sessions{$_};	
			}
		}
	dbmclose %sessions;

	foreach (@old_sessions) {
		$self->kill_session($_);
	}

	1;
}

#====================================================================================================#
# SYNOPSIS: $self->_create_sid();
# PURPOSE:  Hilfsfunktion, die eine neue Sessionid per Zufall generiert.
# RETURN:   $sid.
#====================================================================================================#
sub _create_sid {
	my $self = shift;

	my $ctx  = Digest::MD5->new();
	my $data = "";

	for (my $i = 0; $i < 20; $i++) {
		$data .= join '', ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64, rand 64, rand 64];
	}

	$ctx->add($data);
	my $sid = $ctx->hexdigest;

	$sid;
}

#====================================================================================================#
# SYNOPSIS: $self->_get_expires();
# PURPOSE:  Errechnet von der jetzigen zeit einen neuen Sessionzeit aus, also wie lange die Session
#	    aktiv sein soll. Es wird dabei der vorgegebenen Wert beachtet, der gesetzt wurde fuer die
#	    Dauer einer Session.
# RETURN:   $time.
#====================================================================================================#
sub _get_expires {
	my $self = shift;

	my $time = time();
	$time    = $self->{ExpTime} + $time;

	$time;
}

1;
