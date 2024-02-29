SELECT Products.ProductName, Categories.CategoryName
FROM Products, Categories

SELECT Products.ProductName, Products.UnitPrice
FROM Products, [Order Details]
WHERE [Order Details].UnitPrice < 20

SELECT Products.ProductName, Products.UnitPrice, Categories.CategoryName
FROM Products, [Order Details], Categories
WHERE [Order Details].UnitPrice < 20