use strict;
# Kleines Modul, welches sicherstellt, das jeder seine eigenen Passwoerter etc. benutzt
# fuer die jeweilige Datenbank, wo er gerade arbeitet.

# fill the xxx with your own configdata. 
my $database = "DBI:mysql:wbp";
my $password = "";
my $user     = "wbp";

sub get {
	return ($database, $password, $user);
}

1;
