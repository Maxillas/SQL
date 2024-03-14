UPDATE [Order Details]
SET Discount = 0.2
WHERE Quantity > 50

UPDATE [northwind].[dbo].[Contacts] /*Work only that, "Contact" without full path does not work*/
SET City = 'Piter', Country = 'Russia'
WHERE City = 'Berlin' OR Country = 'Germany'

INSERT INTO Shippers(CompanyName, Phone)
VALUES ('Gazprom', '800-535-35-35'), 
	   ('Lukoil', '800-111-35-35')

DELETE FROM Shippers
WHERE ShipperID > 3

Критерий удаления - значение ID больше 3