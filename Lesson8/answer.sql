SELECT t1.CustomerID, t2.CustomerID, t2.Region
FROM Customers t1, Customers t2
WHERE t1.CustomerID != t2.CustomerID AND (t2.Region is NULL) AND t1.Region is NULL

Не было сравнения региона из таблицы 1, добавил, но не уверен что это нужно, 
значения ведь одинаковые...

SELECT * FROM Orders
WHERE CustomerID = ANY 
(SELECT CustomerID 
 FROM Customers 
 WHERE Region IS NOT NULL)

По сути все совпадает, но отличие в том, что у меня в запросе выбирается вся таблица, 
считаю это более корректным, т.к. в задании нужно вывести список заказов, в моем понимании -
это список со всеми параметрами.

SELECT * FROM Orders
WHERE Freight > ALL 
(SELECT UnitPrice 
 FROM Products)

Аналогично предыдущей задаче