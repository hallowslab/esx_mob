USE `essentialmode`;

INSERT INTO `addon_account` (name, label, shared) VALUES
  ('society_mafia', 'Mafia', 1)
;

INSERT INTO `addon_inventory` (name, label , shared) VALUES
 ('society_mafia', 'Mafia', 1)
;

INSERT INTO `datastore` (name, label, shared) VALUES
	('society_mafia', 'Mafia', 1)
;

INSERT INTO `jobs` (name, label) VALUES
  ('mafia', "Mafia")
;

INSERT INTO `job_grades` (job_name, grade, name, label, salary, skin_male, skin_female) VALUES
  ('mafia',0,'associate','Associate',850,'{}','{}'),
  ('mafia',1,'soldier','Soldier',1500,'{}','{}'),
  ('mafia',2,'caporegime','Caporegime',3000,'{}','{}'),
  ('mafia',3,'underboss','Underboss',8500,'{}','{}'),
  ('mafia',4,'mobadvisor','Mob-Advisor',8500,'{}','{}'),
  ('mafia',5,'boss','Boss',0,'{}','{}')
;

/*   Update some default vehicle categories to appropriate mafia categories

UPDATE vehicles SET category = 'mafia_initiates' WHERE (`model` = 'btype' AND `model` = 'cognoscenti' AND `model` = 'hotknife');

UPDATE vehicles SET category = 'mafia_leaders' WHERE (`model` = 'btype2' AND `model` = 'btype3' AND `model` = 'cogcabrio' AND `model` = 'kuruma' AND `model` = 'sentinel3' AND `model` = 'windsor2' AND `model` = 'ztype');
*/

/* the required tables for vehicleshop
CREATE TABLE `vehicle_categories` (
	`name` varchar(60) NOT NULL,
	`label` varchar(60) NOT NULL,

	PRIMARY KEY (`name`)
);

INSERT INTO `vehicle_categories` (name, label) VALUES
	('compacts','Compacts'),
	('coupes','Coupes'),
	('sedans','Sedans'),
	('sports','Sports'),
	('sportsclassics','Sports Classics'),
	('super','Super'),
	('muscle','Muscle'),
	('offroad','Off Road'),
	('suvs','SUVs'),
	('vans','Vans'),
	('motorcycles','Motos')
;




*/


CREATE TABLE `mobdealer_vehicles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `vehicle` varchar(255) NOT NULL,
  `price` int(11) NOT NULL,
	`display` boolean NOT NULL,
  PRIMARY KEY (`id`)
);
