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
 
$VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/;

sub new {
 
        my ($class, %par) = @_;
        no strict "refs";
        my $self          = bless [\%{"$class\::FIELDS"}], $class;
 
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

sub start_session {

	my ($self, %par) = @_;

	my $sid      = $self->_create_sid();
	$self->{Sid} = $sid;
	my $time     = $self->_get_expires();

	my (%sessions, %sid);

	dbmopen %sessions, sprintf("%s/%s", $self->{SessDir}, $self->{SessFile}), 0644 
	or die "Can't create new session. Reason: $!"; 
		$sessions{$sid} = $time;
	dbmclose %sessions;

	dbmopen %sid, sprintf("%s/%s", $self->{SessDir}, $sid), 0644 
	or die "Can't create new session. Reason: $!";
		foreach (keys %par) {
			$sid{$_} = $par{$_};
		}
	dbmclose %sid;

	$sid;
}

sub kill_session {

	my $self = shift;

	my (%sessions, $dir_file, $pag_file);

	$dir_file = sprintf("%s/%s.dir", $self->{SessDir}, $self->{Sid});
	$pag_file = sprintf("%s/%s.pag", $self->{SessDir}, $self->{Sid});

	dbmopen %sessions, sprintf("%s/%s", $self->{SessDir}, $self->{SessFile}), 0644 
	or die "Can't open session file. Reason: $!";
		delete $sessions{$self->{Sid}};
	dbmclose %sessions;

	unlink $dir_file if (-e $dir_file);
	unlink $pag_file if (-e $pag_file);

	1;
}

sub check_sid {

	my $self = shift;

	return undef unless ($self->{Sid});

	my %sessions;

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

sub set {

	my $self = shift;
	my %par  = @_;

	my %sid;

	dbmopen %sid, sprintf("%s/%s", $self->{SessDir}, $self->{Sid}), 0644 
	or die "Can't open session file. Reason: $!";
		foreach (keys %par) {
			$sid{$_} = $par{$_};
		}
	dbmclose %sid;

	1;	
}

sub get {

	my $self = shift;
	my $key  = shift;

	my (%sid, $value);

	dbmopen %sid, sprintf("%s/%s", $self->{SessDir}, $self->{Sid}), 0644 
	or die "Can't open session file. Reason: $!";
		$value = $sid{$key};
	dbmclose %sid;

	$value;
}

sub del {

	my $self = shift;
	my $key  = shift;

	my %sid;

	dbmopen %sid, sprintf("%s/%s", $self->{SessDir}, $self->{Sid}), 0644 
	or die "Can't open session file. Reason: $!";
		delete $sid{$key};
	dbmclose %sid;
	
	1;	
}

sub set_sid {

	my $self = shift;
	my $sid  = shift || undef;

	$self->{Sid} = $sid;

	1;
}

sub get_sid {

	my $self = shift;
	
	$self->{Sid} || undef;
}

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

sub _get_expires {

	my $self = shift;

	my $time = time();
	$time    = $self->{ExpTime} + $time;

	$time;
}

1;
