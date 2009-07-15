begin transaction;

SET FOREIGN_KEY_CHECKS=0;


-- delete old data

delete from user;
delete from machine;

-- insert new data

commit;
