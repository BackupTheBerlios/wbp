package wbp_config;

use vars qw($VERSION);

$VERSION = sprintf "%d.%03d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/;

$CONFIG = {
	# Normal:
	DataBase      => "DBI:mysql:",   # DataBase, includes the host and port
	DbPassWord    => "",             # DataBase Password
	DbUser        => "",             # DataBase User
	DefaultMode   => "start",        # Default Action Parameter
	SessDir       => "./sessions",   # Session directoy
	SessFile      => "sessions",     # Session file for all sessions
	TmplDir       => "./templates",  # Template directory
	
	# Tables:
	CatTable      => "wbp_category",     # Tablename for "Categories"
	CUserTable    => "wbp_count_user",   # Tablename for "Count Users"
	MReceiveTable => "wbp_receive",      # Tablename for "Message Receive"
        MSendTable    => "wbp_send",         # Tablename for "Message Send"
        MToUserTable  => "wbp_to_user",      # Tablename for "Message to User"
	NewsTable     => "wbp_news",         # Tablename for "News"
        PhaTable      => "wbp_phase",        # Tablename for "Phases"
        ProTable      => "wbp_project",      # Tablename for "Projects"
	ProUserTable  => "wbp_user_project", # Tablename for "Projects to User"
	UserTable     => "wbp_user",         # Tablename for "User"

	# Templates:
	ErrorTmpl     => "error.tmpl",   # Error template
	LoginTmpl     => "login.tmpl",   # Login template
	StartTmpl     => "start.tmpl"    # Start template
};

$MSG = {
	Unknownerror => "Es ist ein unbekannter Fehler aufgetreten."
};

require my_config;

($CONFIG->{DataBase}, $CONFIG->{DbPassWord}, $CONFIG->{DbUser}) = get();

1;
