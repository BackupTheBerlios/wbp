# drop table wbp_user;

create table wbp_user (
	id        int(10) unsigned      not null auto_increment,
	username  varchar(8)            not null,
	password  varchar(8)            not null,
	firstname varchar(30)           not null,
	lastname  varchar(30)           not null,
	email     varchar(100)          not null,
	type      enum('A','B','C','D') not null default 'D',
	status    enum('0','1','2')     not null default '0',
	desc_user text                           default '',
	ins_dt    datetime                       default '0',
	ins_id    int(10) unsigned               default '0',
	upd_dt    datetime                       default '0',
	upd_id    int(10) unsigned               default '0',
	primary key (id) 
);

insert into wbp_user (username, password, firstname, lastname, email, type, status, desc_user, ins_dt, ins_id) values
		     ('admin', 'test', 'Testie', 'Testtest', 'test@test.de', 'A', '1', 'den gibs nur einmal ...', 
		      '2001-03-14 12:15:20', '1');

insert into wbp_user (username, password, firstname, lastname, email, type, status, ins_dt, ins_id) values
                     ('testb', 'test', 'bla1', 'blabla1', 'bla1@bla1.de', 'B', '1', '2001-03-14 12:15:20', '1');

insert into wbp_user (username, password, firstname, lastname, email, type, status, ins_dt ,ins_id) values
                     ('testc', 'test', 'bla2', 'blabla2', 'bla2@bla2.de', 'C', '1', '2001-03-14 12:15:20', '1');

insert into wbp_user (username, password, firstname, lastname, email, type, status, ins_dt, ins_id) values
                     ('testc', 'test', 'bla3', 'blabla3', 'bla3@bla3.de', 'C', '1', '2001-03-14 12:15:20', '1');

insert into wbp_user (username, password, firstname, lastname, email, type, status, ins_dt, ins_id) values
                     ('testd', 'test', 'bla4', 'blabla4', 'bla4@bla4.de', 'D', '1', '2001-03-14 12:15:20', '1');
