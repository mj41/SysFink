begin transaction;

SET FOREIGN_KEY_CHECKS=0;

-- delete old data

delete from user;
delete from machine;

-- insert new data

INSERT INTO user ( user_id, login, passwd, first_name, last_name, active, created )
VALUES (
    1, 'mj41', 'aaa', 'Michal', 'Jurosz', 1, CURRENT_DATE
);


INSERT INTO machine ( machine_id, hostname, `desc`, ip, disabled )
VALUES (
    1, 'tapir1.ro.vutbr.cz', NULL, '147.229.191.11', 0
);

commit;
