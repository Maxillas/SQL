SELECT Products.ProductName, Categories.CategoryName
FROM Products, Categories
WHERE Product.CategoryID = Categories.CategoryID

SELECT Products.ProductName, Products.UnitPrice
FROM Products, [Order Details]
WHERE Products.ProductID = [Order Details].ProductID AND
     [Order Details].UnitPrice < 20

SELECT Products.ProductName, Products.UnitPrice, Categories.CategoryName
FROM Products, [Order Details], Categories
WHERE Products.ProductID = [Order Details].ProductID AND 
      Products.CategoryID= [Order Details].CategoryID
     [Order Details].UnitPrice < 20

Рефлексия:
1. Не учел в первом задании, что нужно Приравнять поле categoryID, было неочевидно. 
А ведь без этого поля нет соответствия между товаром и категорией, просто хаотичное наполнение
2. Аналогично не учел соответствия между полями ProductID. Но по поводы цены из задания явно не понятно, какую из цен нужно выбирать.
В задании указано, что надо вывести цену товара и по логике она находится в таблице Products, а не Order Details.
Именно поэтому я и выбрал эту таблицу.
3. Аналогично не указал соответствие между полями с ID. На будущее - запомнил.