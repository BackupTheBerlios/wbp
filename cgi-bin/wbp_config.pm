package wbp_config;

use vars qw($VERSION);

$VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/;

$CONFIG = {
	# Normal:
	DataBase      => "DBI:mysql:",  # DataBase, includes the host and port
	DbPassWord    => "",            # DataBase Password
	DbUser        => "",            # DataBase User
	DefaultMode   => "start",       # Default Action Parameter
	MReceiveTable => "",            # Tablename for "Message Receive"
	MSendTable    => "",            # Tablename for "Message Send"
	MToUserTable  => "",            # Tablename for "Message to User"
	NewsTable     => "",            # Tablename for "News"
	PhaUserTable  => "",            # Tablename for "Phasen Benutzer"
	PhaTable      => "",            # Tablename for "Phasen"
	ProTable      => "",            # Tablename for "Projekte"
	ProPhaTable   => "",            # Tablename for "Projekte Phasen"
	SessDir       => "./sessions",  # Session directoy
	SessFile      => "sessions",    # Session file for all sessions
	TmplDir       => "./templates", # Template directory
	UserTable     => "",            # Tablename for "Benutzer"

	# Templates:
	ErrorTmpl     => "error.tmpl",  # Error template
	LoginTmpl     => "login.tmpl",  # Login template
	StartTmpl     => "start.tmpl"   # Start template
};

1;
