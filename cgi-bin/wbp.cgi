#!/usr/bin/perl -w

use CGI;
use DBI;
use HTML::Template;
use Session;
use wbp_config;
use fields (
	'Action',        # action paramaeter
	'CatTable',      # "categories" table
	'CGI',           # cgi object
	'CUserTable',    # "count user" table
	'DataBase',      # database name
	'DbHandle',      # database handle
	'DbPassWord',    # database password
	'DbUser',        # database user
	'DefaultMode',   # the default action parameter 
	'ErrorTmpl',     # error template
	'LoginTmpl',     # login template
	'NewsTable',     # "news" table
	'MReceiveTable', # "message receive" table
	'MSendTable',    # "message send" table
	'MToUserTable',  # "message to user" table
	'MyUrl',         # url of this script
	'PhaTable',      # "phases" table
	'ProTable',      # "project" table
	'ProUserTable',  # "project to user" table
	'SessDir',       # session directory
	'SessFile',      # session file (for all sessiosn)
	'Session',       # session object
	'ScriptName',    # name of this script
	'Sid',           # current sid
	'StartTmpl',     # start template
	'Template',      # template file
	'TmplData',      # data for the template
	'TmplDir',       # directory for the templates
	'UserFirstName', # first name of the user
	'UserId',        # id of the user
	'UserLastName',  # last name of the user
	'UserTable',     # "user" table
	'UserType'       # type of the user
);
use strict;
use vars qw(%FIELDS $VERSION);

$VERSION = sprintf "%d.%03d", q$Revision: 1.17 $ =~ /(\d+)\.(\d+)/;

&handler;

#====================================================================================================#
# SYNOPSIS: handler();
# PURPOSE:  handler for wbp.pm.
# RETURN:   Templatedata.
#====================================================================================================#
sub handler {

	my $in = CGI->new();
	my $self = __PACKAGE__->new(
		Action        => undef,
		CatTable      => $wbp_config::CONFIG->{CatTable},
		CGI           => $in,
		CUserTable    => $wbp_config::CONFIG->{CUserTable},
		DataBase      => $wbp_config::CONFIG->{DataBase},
		DbHandle      => undef,
		DbPassWord    => $wbp_config::CONFIG->{DbPassWord},
		DbUser        => $wbp_config::CONFIG->{DbUser},
		DefaultMode   => $wbp_config::CONFIG->{DefaultMode},
		ErrorTmpl     => $wbp_config::CONFIG->{ErrorTmpl},
		LoginTmpl     => $wbp_config::CONFIG->{LoginTmpl},
		NewsTable     => $wbp_config::CONFIG->{NewsTable},
		MReceiveTable => $wbp_config::CONFIG->{MReceiveTable},
		MSendTable    => $wbp_config::CONFIG->{MSendTable},
		MToUserTable  => $wbp_config::CONFIG->{MToUserTable},
		MyUrl         => undef,
		PhaTable      => $wbp_config::CONFIG->{PhaTable},
		ProTable      => $wbp_config::CONFIG->{ProTable},
		ProUserTable  => $wbp_config::CONFIG->{ProUserTable},
		SessDir       => $wbp_config::CONFIG->{SessDir},
		SessFile      => $wbp_config::CONFIG->{SessFile},
		Session       => undef,
		ScriptName    => $ENV{SCRIPT_NAME},
		Sid           => undef,
		StartTmpl     => $wbp_config::CONFIG->{StartTmpl},
		Template      => undef,
		TmplData      => undef,
		TmplDir       => $wbp_config::CONFIG->{TmplDir},
		UserFirstName => undef,
		UserId        => undef,
		UserLastName  => undef,
		UserTable     => $wbp_config::CONFIG->{UserTable},
		UserType      => undef
	);
	
	$self->{Session} = Session->new(SessDir  => $self->{SessDir}, 
					SessFile => $self->{SessFile},
					ExpTime  => "36000",
					Sid      => undef);

	$self->{Session}->check_sessions();

	my ($check, $class, $param, $sid);

	$param          = $self->{CGI}->param('action') || $self->{DefaultMode};
	$sid            = $self->{CGI}->param('sid') || undef;
	$self->{Action} = $param;
	$self->{Sid}    = $sid;

	$self->{Session}->set_sid($sid);

	eval { $check = $self->{Session}->check_sid(); };
	if ($@) {
		warn "Trouble checking session id [$sid].\n[Error]: $@";
		$self->fatal_error;
	}

	if ($check) {
		$self->{UserFirstName} = $self->{Session}->get("FIRSTNAME");
		$self->{UserLastName}  = $self->{Session}->get("LASTNAME");
		$self->{UserId}        = $self->{Session}->get("USERID");
		$self->{UserType}      = $self->{Session}->get("USERTYPE");
	
		if ($param eq ('project')) {
			require project;
		} elsif ($param eq ('message')) {
			require message;
		} elsif ($param eq ('news')) {
			require news;
		} elsif ($param eq ('user')) {
			require user;
		} elsif ($param eq ('categories')) {
			require categories; 
		} else {
			# So lange es noch keine Konfiguation gibt.
			$self->{Action} = "start";
			$param = "start";
			
			require start;
		}
	} else {
		$param          = $self->{DefaultMode};
		$self->{Action} = $self->{DefaultMode};
		$self->{Sid}    = undef;
		require start;
	}

	eval { $class = $param->instance(); };
	if ($@) {
		warn "Can't create class [$param].\n[Error]: $@";
		$self->fatal_error;
	}

	if ($class->can("parameter")) {
		eval { $class->parameter($self); };
		if ($@) {
			warn "Can't execute method parameter in class [$param].\n[Error]: $@";
			$self->fatal_error;
		}
	} else {
		warn "No parameter method in class [$param].\n[Error]: $@";
		$self->fatal_error;
	}

	$self->_output;
	exit;
}

#====================================================================================================#
# SYNOPSIS: $CLASS->new();
# PURPOSE:  Konstruktor for wbp.pm.
# RETURN:   $self blessed into the namespace from wbp. 
#====================================================================================================#
sub new {

	my ($class, %par) = @_;
	no strict "refs";
	my $self          = bless [\%{"$class\::FIELDS"}], $class;

	while (my($k, $v) = each %par) {
		eval { $self->{$k} = $v; };

		if ($@) {
			if ($@ =~ /No such array field/i) {
				warn "Ignoring unknown key[$k]";
			} else {
				die $@;
			}
		}
	}

	$self;	
}

#====================================================================================================#
# SYNOPSIS: $instance->_output();
# PURPOSE:  Prints the templatedata out.
# RETURN:   Templatedata.
#====================================================================================================#
sub _output {

	my $self = shift;
	
	print "Content-type: text/html\n\n";

	unless (-r "$self->{TmplDir}/$self->{Template}") {
		warn "[Error]: Template [$self->{Template}] not found or readable";
		$self->_template_error($self->{Template});
	}

	my $tmpl = HTML::Template->new(filename => $self->{Template}, path => $self->{TmplDir});
	
	$self->{TmplData}{ACTION} = $self->{Action};
	$self->{TmplData}{SID}    = $self->{Sid};
	$tmpl->param(%{$self->{TmplData}});
	
	print $tmpl->output;
}

#====================================================================================================#
# SYNOPSIS: $instance->fatal_error();
# PURPOSE:  Initialisize the {Template} variable with an error template and prints it out. 
# RETURN:   none.
#====================================================================================================#
sub fatal_error {

	my $self = shift;
	my $msg  = shift;
	
	$self->{Template} = $self->{ErrorTmpl}; 
	delete $self->{TmplData};
	
	if (defined $msg) {
		$self->{TmplData}{MSG} = $self->decode_all($msg);
	} else {
		$self->{TmplData}{MSG} = $self->decode_all("Es ist ein unbekannter Fehler aufgetreten.");
	}

	warn "[Time]: ".$self->now();

	$self->_output;
	exit;
}

#====================================================================================================#
# SYNOPSIS: $instance->_template_error();
# PURPOSE:  Generates an error template. This one is only for Templaterrors.
# RETURN:   none.
#====================================================================================================#
sub _template_error {
	
	my $self = shift;
	my $tmpl = shift;

	print <<EOT;
<html><body>
	<h1>Template [$tmpl] konnte nicht gelesen werden.</h1>
</body></html>
EOT

	exit;
}

#====================================================================================================#
# SYNOPSIS: $instance->_connect();
# PURPOSE:  Connect to the database.
# RETURN:   true.
#====================================================================================================#
sub connect {

	my $self = shift;

	$self->{DbHandle} ||= DBI->connect(
		$self->{DataBase},
		$self->{DbUser},
		$self->{DbPassWord},
		{RaiseError => 1}
	) or die "Can't connect to databse.";
}

#====================================================================================================#
# SYNOPSIS: $instance->my_url();
# PURPOSE:  Generates the url of this script and write it to {MyUrl}variable.
# RETURN:   $instance->{MyUrl}.
#====================================================================================================#
sub my_url {

	my $self = shift;

	return $self->{MyUrl} if $self->{MyUrl};
	if ($self->{Sid}) {
		$self->{MyUrl} = sprintf("%s?action=%s&sid=%s", 
					$self->{ScriptName}, 
					$self->{Action}, 
					$self->{Sid});
	} else {
		$self->{MyUrl} = sprintf("%s?action=%s", 
					$self->{ScriptName}, 
					$self->{Action});
	}
	
	return $self->{MyUrl};
}

#====================================================================================================#
# SYNOPSIS: $instance->now();
# PURPOSE:  Reads and formats the localtime into mysql datetime format.
# RETURN:   datetime.
#====================================================================================================#
sub now {
 
        sprintf("%04d-%02d-%02d %02d:%02d:%02d",
                sub {($_[0]+1900, $_[1]+1),@_[2..5]}->((localtime)[5,4,3,2,1,0]));
}

#====================================================================================================#
# SYNOPSIS: $instance->format_date();
# PURPOSE:  Formats an datetime from mysql style into normal style.
# RETURN:   normal datetime.
#====================================================================================================# 
sub format_date {
	
	my $self = shift;
	my $date = shift;

	return undef unless ($date);

	return (substr($date, 8, 2).".".substr($date, 5, 2).".".substr($date, 0, 4));
}

#====================================================================================================#
# SYNOPSIS: $instance->fill();
# PURPOSE:  Fills out the normal header and footer.
# RETURN:   true.
#====================================================================================================#
sub fill {

	my $self = shift;
	my $msg  = shift || undef;
	
	$self->{TmplData}{FIRSTNAME} = $self->decode_all($self->{UserFirstName});
	$self->{TmplData}{LASTNAME}  = $self->decode_all($self->{UserLastName});
	$self->{TmplData}{LOGOUT}    = sprintf($self->{ScriptName}."?action=%s&sid=%s&method=logout",
						$self->{DefaultMode}, $self->{Sid});
	$self->{TmplData}{MSG}       = $self->decode_all($msg) if $msg;

	my $link = $self->{ScriptName}."?action=%s&sid=".$self->{Sid};
 
        if (($self->{UserType} eq "A") || ($self->{UserType} eq "B")) {
                $self->{TmplData}{NAV_PROJECT}  = sprintf($link, "project");
                $self->{TmplData}{NAV_USER}     = sprintf($link, "user");
                $self->{TmplData}{NAV_CATEGORY} = sprintf($link, "categories");
                $self->{TmplData}{NAV_CONFIG}   = sprintf($link, "config");
		$self->{TmplData}{NAV_MESSAGE}  = sprintf($link, "message");
	        $self->{TmplData}{NAV_NEWS}     = sprintf($link, "news");
        } elsif ($self->{UserType} eq "C") {
                $self->{TmplData}{NAV_PROJECT} = sprintf($link, "project");
                $self->{TmplData}{NAV_USER}    = sprintf($link, "user");
		$self->{TmplData}{NAV_MESSAGE} = sprintf($link, "message");
        	$self->{TmplData}{NAV_NEWS}    = sprintf($link, "news");
        } elsif ($self->{UserType} eq "D") {
		$self->{TmplData}{NAV_MESSAGE} = sprintf($link, "message");
        	$self->{TmplData}{NAV_NEWS}    = sprintf($link, "news");	
	} 

	1;
}

#====================================================================================================#
# SYNOPSIS: $instance->decode_all();
# PURPOSE:  Decodes non HTMLconformed chars into good ones. 
# RETURN:   $value.
#====================================================================================================#
sub decode_all {

	my $self  = shift;
	my $value = shift;

	return unless (defined $value);

	$value =~ s/&/&amp;/g;
	$value =~ s/\"/&quot;/g;
	$value =~ s/</&lt;/g;
	$value =~ s/>/&gt;/g;
	$value =~ s/ä/&auml;/g;
	$value =~ s/Ä/&Auml;/g;
	$value =~ s/ö/&ouml;/g;
	$value =~ s/Ö/&Ouml;/g;
	$value =~ s/ü/&uuml;/g;
	$value =~ s/Ü/&Uuml;/g;
	$value =~ s/ß/&szlig;/g;
	$value =~ s/\n\r/<br>/g;
	$value =~ s/\n/<br>/g;
	$value =~ s/\r/<br>/g; 

	return $value;
}

#====================================================================================================#
# SYNOPSIS: $instance->decod_some(); 
# PURPOSE:  Decodes only the " < and > into HTMLconformed chars. 
# RETURN:   $value.
#====================================================================================================#
sub decode_some {

	my $self  = shift;
	my $value = shift;

	return unless (defined $value);
	
	$value =~ s/\"/&quot;/g;
	$value =~ s/</&lt;/g;
	$value =~ s/>/&gt;/g;

	return $value;
}

#====================================================================================================#
# SYNOPSIS: $instance->DESTROY();
# PURPOSE:  "Clears the ground here", disconnect and so one ...
# RETURN:   true.
#====================================================================================================#
sub DESTROY {

	my $self = shift;

	$self->{DbHandle}->disconnect if $self->{DbHandle};
}

1;
