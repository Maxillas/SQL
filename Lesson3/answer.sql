SELECT * FROM Customers
WHERE ContactName LIKE '% C%'

SELECT * FROM Orders
WHERE (Freight BETWEEN 100 AND 200) AND ShipCountry IN ('USA', 'France')


SELECT * FROM EmployeeTerritories
WHERE TerritoryID BETWEEN 6897 AND 31000