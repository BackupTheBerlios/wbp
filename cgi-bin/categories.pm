package categories;

use Class::Singleton;
use base 'Class::Singleton';
use categories_config;
use vars qw($VERSION $C_MSG $C_TMPL);
use strict;

$VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/;

$C_MSG  = $categories_config::MSG;
$C_TMPL = $categories_config::TMPL;

sub parameter {

  my $self = shift;
  my $mgr  = shift;

  # UserType abfragen

  if (($mgr->{UserType} eq "A") || ($mgr->{UserType} eq "B")) {
    $self->categories_user_type_AB($mgr);
  } elsif (($mgr->{UserType} eq "C") || ($mgr->{UserType} eq "D")) {
    $self->categories_user_type_CD($mgr);
  }

  return 1;
};

sub categories_user_type_AB {

  my $self = shift;
  my $mgr  = shift;

  my $dbh = $mgr->connect;
  my $sth = $dbh->prepare(qq{SELECT id, name FROM $mgr->{CatTable}});

  unless ($sth->execute()) {
    warn sprintf("[Error]: Trouble selecting from [%]. Reason: [%s].",$mgr->{CatTable}, $dbh->errstr);
    $mgr->fatal_error($C_MSG->{db_error});
  };

  my @cats;
  while (my ($id, $name) = $sth->fetchrow_array()) {
    push (@cats, [$id, $name]);
  }
  $sth->finish;

  $mgr->{Template} = $C_TMPL->{CatMain}; # aktuelles Template festlegen

  my $link_show = $mgr->{ScriptName}."?action=news&sid=".$mgr->{Sid}."&method=show_cat";
  my $link_edit = $mgr->{ScriptName}."?action=news&sid=".$mgr->{Sid}."&method=edit_cat";
  my $link_del = $mgr->{ScriptName}."?action=news&sid=".$mgr->{Sid}."&method=del_cat";

  if (@cats) {
    my @tmp;
    for (my $i = 0; $i <= $#cats; $i++) {
      $tmp[$i]{CAT_NAME} = $mgr->decode_all($cats[$i][1]);
      $tmp[$i]{SHOW_LINK} = $mgr->decode_all(sprintf("%s&catid=%s", $link_show, $cats[$i][0]));
      $tmp[$i]{EDIT_LINK} = $mgr->decode_all(sprintf("%s&catid=%s", $link_edit, $cats[$i][0]));
      $tmp[$i]{DEL_LINK} = $mgr->decode_all(sprintf("%s&catid=%s", $link_del, $cats[$i][0]));
    }
    $mgr->{TmplData}{CATS_LOOP} = \@tmp;
  }

  $mgr->fill; # Füllt das Template und zeigt es an

  return 1;
};

sub categories_user_type_CD {

  my $self = shift;
  my $mgr  = shift;

  $mgr->{Template} = $C_TMPL->{Error}; # aktuelles Template festlegen
  $mgr->{TmplData}{MSG} = $C_MSG->{user_cd_error};
  $mgr->fill;

  return 1;
};

1;
