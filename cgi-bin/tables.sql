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

create table wbp_project (
	id           int(10) unsigned  not null auto_increment,
	name         varchar(255)      not null,
	desc_project text default '',
	cat_id       int(10) unsigned  not null,
	start_dt     datetime          not null,
	end_dt       datetime          not null,
	status	     enum('0','1','2') not null     default '0',
	mode         enum('0','1')     not null     default '0',
	ins_dt       datetime                       default '0', 
	ins_id       int(10) unsigned               default '0',
	upd_dt       datetime                       default '0',
	upd_id       int(10) unsigned               default '0',
	primary key (id)
);

create table wbp_user_project (
        id           int(10) unsigned  not null auto_increment,
        user_id      int(10) unsigned  not null,
        project_id   int(10) unsigned  not null,
	position     enum('0','1','2') not null default '0',
        primary key(id)
);

create table wbp_phase (
	id           int(10) unsigned  not null auto_increment,
	name         varchar(255)      not null,
        desc_phase   text default '',
	project_id   int(10) unsigned  not null,
	start_dt     datetime          not null,
        end_dt       datetime          not null,
	status       enum('0','1')     not null     default '0',
	ins_dt       datetime                       default '0',
        ins_id       int(10) unsigned               default '0',
        upd_dt       datetime                       default '0',
        upd_id       int(10) unsigned               default '0',
	primary key (id)
);

CREATE TABLE wbp_send (
        id INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        from_uid INT(10) UNSIGNED NOT NULL,
        parent_mid INT(10) UNSIGNED NOT NULL DEFAULT 0,
        date DATETIME NOT NULL,
        subject VARCHAR(255) NOT NULL,
        content TEXT NOT NULL
);
 
CREATE TABLE wbp_receive (
        id INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        mid INT(10) UNSIGNED NOT NULL,
        from_uid INT(10) UNSIGNED NOT NULL,
        to_uid INT(10) UNSIGNED NOT NULL,
        parent_mid INT(10) UNSIGNED NOT NULL DEFAULT 0,
        status    enum('0','1','2')     not null default '0',
        date DATETIME NOT NULL,
        subject VARCHAR(255) NOT NULL,
        content TEXT NOT NULL
);
 
CREATE TABLE wbp_to_user (
        id INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        mid INT(10) UNSIGNED NOT NULL,
        uid INT(10) UNSIGNED NOT NULL
);

CREATE TABLE wbp_category ( 
  id INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL,
  desc_category TEXT NOT NULL DEFAULT "",
  status ENUM('0','1') NOT NULL DEFAULT 1,
  ins_dt DATETIME NOT NULL,
  ins_id INT(10) UNSIGNED DEFAULT 0,
  upd_dt DATETIME NOT NULL DEFAULT 0,
  upd_id VARCHAR(8) NOT NULL DEFAULT ""
);

CREATE TABLE wbp_news ( 
  id INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  subject VARCHAR(100) NOT NULL,
  text TEXT NOT NULL DEFAULT "",
  start_dt DATETIME NOT NULL,
  project_id INT(10) UNSIGNED,
  status ENUM('0','1') NOT NULL DEFAULT 0,
  ins_dt DATETIME NOT NULL,
  ins_id INT(10) UNSIGNED DEFAULT 0,
  upd_dt DATETIME NOT NULL DEFAULT 0,
  upd_id VARCHAR(8) NOT NULL DEFAULT ""
);     
