USE MyDataBase

CREATE TABLE RegionTrue ( 
    RegionID int PRIMARY KEY NOT NULL, 
    RegionDescription nchar(50) NOT NULL)

CREATE TABLE TerritoriesTrue (
	TerritoryID int PRIMARY KEY NOT NULL, 
	TerritoryDescription nchar(50) NOT NULL,
	RegionID int NOT NULL,
	FOREIGN KEY (RegionID) REFERENCES RegionTrue(RegionID)
)

INSERT INTO RegionTrue (RegionDescription)
VALUES ('Kazan')

INSERT INTO TerritoriesTrue (TerritoryID, TerritoryDescription, RegionID)
VALUES (1, 'Alabuga', 1);


