#!/usr/bin/perl -w

use lib "../../../Perl/perl_modules";
use CGI;
use DBI;
use HTML::Template;
use Session;
use wbp_config;
use fields (
	'Action',        # action paramaeter
	'CGI',           # cgi object
	'DataBase',      # database name
	'DbHandle',      # database handle
	'DbPassWord',    # database password
	'DbUser',        # database user
	'DefaultMode',   # the default action parameter 
	'ErrorTmpl',     # error template
	'LoginTmpl',     # login template
	'NewsTable',     # "news" table
	'MainTmpl',      # main template
	'MReceiveTable', # "message receive" table
	'MSendTable',    # "message send" table
	'MToUserTable',  # "message to user" table
	'MyUrl',         # url of this script
	'PhaTable',      # "phasen" table
	'PhaUserTable',  # "phasen benutzer" table
	'ProTable',      # "projekt" table
	'ProPhaTable',   # "projekte phasen" table
	'SessDir',       # session directory
	'SessFile',      # session file (for all sessiosn)
	'Session',       # session object
	'ScriptName',    # name of this script
	'Sid',           # current sid
	'Template',      # template file
	'TmplData',      # data for the template
	'TmplDir',       # directory for the templates
	'UserTable',     # "benutzer" table
	'UserType'       # type of the user
);
use strict;
use vars qw(%FIELDS $VERSION);

$VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/;

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
		CGI           => $in,
		DataBase      => $wbp_config::CONFIG->{DataBase},
		DbHandle      => undef,
		DbPassWord    => $wbp_config::CONFIG->{DbPassWord},
		DbUser        => $wbp_config::CONFIG->{DbUser},
		DefaultMode   => $wbp_config::CONFIG->{DefaultMode},
		ErrorTmpl     => $wbp_config::CONFIG->{ErrorTmpl},
		LoginTmpl     => $wbp_config::CONFIG->{LoginTmpl},
		NewsTable     => $wbp_config::CONFIG->{NewsTable},
		MainTmpl      => $wbp_config::CONFIG->{MainTmpl},
		MReceiveTable => $wbp_config::CONFIG->{MReceiveTable},
		MSendTable    => $wbp_config::CONFIG->{MSendTable},
		MToUserTable  => $wbp_config::CONFIG->{MToUserTable},
		MyUrl         => undef,
		PhaTable      => $wbp_config::CONFIG->{PhaTable},
		PhaUserTable  => $wbp_config::CONFIG->{PhaUserTable},
		ProTable      => $wbp_config::CONFIG->{ProTable},
		ProPhaTable   => $wbp_config::CONFIG->{ProPhaTable},
		SessDir       => $wbp_config::CONFIG->{SessDir},
		SessFile      => $wbp_config::CONFIG->{SessFile},
		Session       => undef,
		ScriptName    => $ENV{SCRIPT_NAME},
		Sid           => undef,
		Template      => undef,
		TmplData      => undef,
		TmplDir       => $wbp_config::CONFIG->{TmplDir},
		UserTable     => $wbp_config::CONFIG->{UserTable},
		UserType      => undef
	);
	
	$self->{Session} = Session->new(SessDir  => $self->{SessDir}, 
					SessFile => $self->{SessFile},
					ExpTime  => "3600");

	my ($check, $class, $param, $sid);

	$param          = $self->{CGI}->param('action') || $self->{DefaultMode};
	$sid            = $self->{CGI}->param('sid') || undef;
	$self->{Action} = $param;
	$self->{Sid}    = $sid;

	eval { $check = $self->{Session}->check_sid($sid); };
	if ($@) {
		warn "Trouble checking session id [$sid]";
		warn "[Error] $@";
		$self->fatal_error;
	}

	if ($check) {	
		if ($param eq ('message')) {
			require message; 
		} else {
			require login;
		}
	} else {
		$param          = $self->{DefaultMode};
		$self->{Action} = $self->{DefaultMode};
		$self->{Sid}    = undef;
		require login;
	}

	eval { $class = $param->instance(); };
	if ($@) {
		warn "Can't create class [$param]";
		warn "[Error] $@";
		$self->fatal_error();
	}

	if ($class->can("parameter")) {
		eval { $class->parameter($self); };
		if ($@) {
			warn "Can't execute method parameter in class [$param]";
			warn "[Error] $@";
			$self->fata_error;
		}
	} else {
		warn "No parameter method in class [$param]";
		warn "[Error] $@";
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
		warn "Template [$self->{Template}] not found or readable";
		$self->_template_error($self->{Template});
	}

	my $tmpl = HTML::Template->new(filename => $self->{Template},path => $self->{TmplDir});

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
	
	$self->{Template}      = $self->{ErrorTmpl}; 
	$self->{TmplData}{MSG} = $self->decode_all($msg) if $msg;
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
<html>
<body>
	<h1>Template [$tmpl] konnte nicht gelesen werden.</h1>
</body>
</html>
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
	) or die "Can't connect to database";
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
		$self->{MyUrl} = sprintf("%s?action=%s&sid=%s", $self->{ScriptName}, $self->{Action}, $self->{Sid});
	} else {
		$self->{MyUrl} = sprintf("%s?action=%s", $self->{ScriptName}, $self->{Action});
	}
	return $self->{MyUrl};
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
# hier noch was hin ...
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
# hier noch was hin ...
	return $value;
}

1;
