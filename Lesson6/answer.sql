SELECT DiscountPercent = Discount * 100 FROM [Order Details]
 
SELECT * FROM [Order Details]
WHERE ProductID IN (
SELECT ProductID FROM Products
WHERE UnitsInStock > 40)

SELECT * FROM [Order Details]
WHERE ProductID IN (
SELECT ProductID FROM Products
WHERE UnitsInStock > 40)
AND OrderID IN (
SELECT OrderID FROM Orders
WHERE Freight >= 50
)