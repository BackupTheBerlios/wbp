use strict;

my $database = "DBI:mysql:perl;host=localhost;port=3306";
my $password = "neues";
my $user     = "wurch";

sub get {
	return ($database, $password, $user);
}

1;
