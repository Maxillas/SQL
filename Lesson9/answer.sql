/* #3 */

SELECT Products.ProductName, Products.UnitPrice
FROM Products, [Order Details]
WHERE Products.ProductID = [Order Details].ProductID AND
     [Order Details].UnitPrice < 20

SELECT Products.ProductName, Products.UnitPrice
FROM Products
JOIN [Order Details]
ON [Order Details].UnitPrice < 20 
AND Products.ProductID = [Order Details].ProductID

/* #2 */

SELECT Orders.Freight, Customers.CompanyName
FROM Orders INNER JOIN Customers
ON Orders.CustomerID = Customers.CustomerID
ORDER BY Freight;

SELECT Orders.Freight, Customers.CompanyName
FROM Orders FULL JOIN Customers
ON Orders.CustomerID = Customers.CustomerID
ORDER BY Freight;
/*Выборка получилась объемнее засчет значения Freight = NULL, которое в первом случае 
не выдавалось. NULL встречается только в первом поле (Freight)*/
*/
/* #3 */
SELECT Employees.FirstName, Employees.LastName, Orders.Freight
FROM Employees CROSS JOIN Orders
WHERE Employees.EmployeeID = Orders.EmployeeID

/* #4 */
SELECT Products.ProductName, [Order Details].UnitPrice
FROM Products CROSS JOIN [Order Details]
WHERE Products.ProductID = [Order Details].ProductID

SELECT Products.ProductName, [Order Details].UnitPrice
FROM Products INNER JOIN [Order Details]
ON Products.ProductID = [Order Details].ProductID

