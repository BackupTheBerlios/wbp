use strict;

# fill the xxx with your own configdata. 

my $database = "DBI:mysql:xxx;host=xxx;port=xxx";
my $password = "xxx";
my $user     = "xxx";

sub get {
	return ($database, $password, $user);
}

1;
