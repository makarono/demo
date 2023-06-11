CREATE SCHEMA IF NOT EXISTS `count`;
CREATE TABLE IF NOT EXISTS `count`.`count` ( id INT AUTO_INCREMENT PRIMARY KEY, count_value INT );
SELECT count(1) as cnt from `count`.`count`;