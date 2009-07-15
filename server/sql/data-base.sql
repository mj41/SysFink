begin transaction;

SET FOREIGN_KEY_CHECKS=0;

-- delete data inserted below
delete from user;
delete from machine;

SET FOREIGN_KEY_CHECKS=1;

commit;
