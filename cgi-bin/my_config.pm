use strict;

# fill the xxx with your own configdata. 

my $database = "DBI:mysql:wbp_db";
my $password = "";
my $user     = "root";

sub get {
	return ($database, $password, $user);
}

1;
