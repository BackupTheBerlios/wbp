package wbp_config;

use vars qw($VERSION);

$VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/;

$CONFIG = {
	DataBase      => "DBI:mysql:",  # DataBase, includes the host and port
	DbPassWord    => "",            # DataBase Password
	DbUser        => "",            # DataBase User
	DefaultMode   => "login",       # Default Action Parameter
	ErrorTmpl     => "error.tmpl",  # Error template
	LoginTmpl     => "login.tmpl",  # Login template
	MainTmpl      => "main.tmpl",   # Main template
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
	UserTable     => ""             # Tablename for "Benutzer"
};

1;
