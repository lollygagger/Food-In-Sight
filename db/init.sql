-- create base tables and insert some data
DROP DATABASE IF EXISTS foodInSight;
CREATE DATABASE foodInSight;
USE foodInSight;

CREATE TABLE users (
	userId	 SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	userName VARCHAR(25) NOT NULL,
	password TEXT
);

INSERT INTO users
VALUES 
	(1, 'vince', 'thisisanencryptedpassword'),
	(2, 'jacob', 'anotherpassword');

CREATE TABLE diets (
	dietId 	SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	name	VARCHAR(50) NOT NULL,
	description	TINYTEXT
);

INSERT INTO diets
VALUES
	(1, "peanut allergy", "cannot eat peanuts"),
	(2, "lactose intolerance", "dairy products may cause diarrhea, gas, and bloating"),
	(3, "high cholesterol", "should avoid fatty foods and foods high in sodium and added sugars");

CREATE TABLE userDiets (
	userId	SMALLINT UNSIGNED,
	dietId	SMALLINT UNSIGNED,
	PRIMARY KEY (userId, dietId),
	FOREIGN KEY (userId) REFERENCES users(userId) ON DELETE CASCADE,
	FOREIGN KEY (dietId) REFERENCES diets(dietId) ON DELETE CASCADE
);

INSERT INTO userDiets
VALUES
	(1, 2),
	(2, 1),
	(1, 3);