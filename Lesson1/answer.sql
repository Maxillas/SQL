Employee -> EmployeeTerritories <- Territories = Многие ко многим
Territories -> Region = Один ко многим
Employee -> Orders = Один ко многим
Orders -> Customer = Один ко многим
Orders -> Shippers = Один ко многим
Orders -> OrdersDetails <- Product = Многие ко многим
Product -> Supliers = Один ко многим
Product -> Categories = Один ко многим

Случаи многие ко многим относятся именно к этому типу поскольку в связке используется три таблицы, 
средняя (EmployeeTerritories и OrderDetails) является связующей и хранит пары EmployeeID - TerritoryID и OrderID - ProductID 

Рефлексия:
Не учел "направление" связи, хотя в голове это держал, но в задании явно не указал стрелочкой направления. На заметку.