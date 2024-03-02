SELECT t1.CustomerID, t2.CustomerID, t2.Region
FROM Customers t1, Customers t2
WHERE t1.CustomerID != t2.CustomerID AND (t2.Region is NULL)

SELECT * FROM Orders
WHERE CustomerID = ANY 
(SELECT CustomerID 
 FROM Customers 
 WHERE Region IS NOT NULL)

SELECT * FROM Orders
WHERE Freight > ALL 
(SELECT UnitPrice 
 FROM Products)