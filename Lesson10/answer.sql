SELECT * FROM Customers
LEFT JOIN Orders ON
Orders.CustomerID = Customers.CustomerID AND
Orders.CustomerID = NULL

SELECT 'Customer' As Type, ContactName, City, Country
FROM Customers
UNION 
SELECT 'Supplier' As Type, ContactName, City, Country
FROM Customers