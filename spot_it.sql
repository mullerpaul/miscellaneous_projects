drop table CARD_ICON purge;
drop table CARD purge;
drop table ICON purge;
drop table SIMULATION_PARAMETERS purge;
drop sequence CARD_SEQ;
drop sequence ICON_SEQ;
----------------------------
create table ICON
 (icon_id   number not null,
  ICON_TEXT varchar2(30))
/
alter table ICON add constraint ICON_PK primary key (icon_id)
/
----
create table CARD
 (CARD_ID    number                  not null,
  valid_flag varchar2(1) default 'N' not null )
/
alter table CARD add constraint CARD_PK primary key (CARD_ID)
/
----
create table CARD_ICON
 (CARD_ID number not null,
  ICON_ID number not null)
/
alter table card_icon add constraint card_icon_pk primary key (card_id, icon_id)
/
alter table card_icon add constraint card_icon_fk01 foreign key (card_id) references card (card_id)
/
alter table CARD_ICON add constraint CARD_ICON_FK02 foreign key (ICON_ID) references ICON (ICON_ID)
/
----
create sequence icon_seq
/
create sequence CARD_SEQ
/
-----
create table SIMULATION_PARAMETERS
(name varchar2(60), 
 value number)
/
insert into SIMULATION_PARAMETERS (name, value) values ('cards',5); 
insert into SIMULATION_PARAMETERS (name, value) values ('icons',10); 
insert into SIMULATION_PARAMETERS (name, value) values ('icons per card',4); 
 
----
insert into ICON (ICON_ID, ICON_TEXT) values (ICON_SEQ.NEXTVAL, 'Tree');
insert into ICON (ICON_ID, ICON_TEXT) values (ICON_SEQ.NEXTVAL, 'Dirt');
insert into ICON (ICON_ID, ICON_TEXT) values (ICON_SEQ.NEXTVAL, 'Bug');
insert into ICON (ICON_ID, ICON_TEXT) values (ICON_SEQ.NEXTVAL, 'Lake');
insert into ICON (ICON_ID, ICON_TEXT) values (ICON_SEQ.NEXTVAL, 'Horse');
insert into ICON (ICON_ID, ICON_TEXT) values (ICON_SEQ.NEXTVAL, 'Rock');
insert into ICON (ICON_ID, ICON_TEXT) values (ICON_SEQ.NEXTVAL, 'Mouse');
insert into ICON (ICON_ID, ICON_TEXT) values (ICON_SEQ.NEXTVAL, 'Bird');
insert into ICON (ICON_ID, ICON_TEXT) values (ICON_SEQ.NEXTVAL, 'Grass');
insert into ICON (ICON_ID, ICON_TEXT) values (ICON_SEQ.NEXTVAL, 'Cat');

commit;

select * from SIMULATION_PARAMETERS;
select * from ICON;






