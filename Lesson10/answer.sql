SELECT * FROM Customers
LEFT JOIN Orders ON
Orders.CustomerID = Customers.CustomerID 
WHERE Orders.CustomerID is NULL

����������� �������� ���������� �������� � FK ������� Orders.

SELECT 'Customer' As Type, ContactName, City, Country
FROM Customers
UNION 
SELECT 'Supplier' As Type, ContactName, City, Country
FROM Customers