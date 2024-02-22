SELECT * FROM Employees
ORDER BY BirthDate DESC, Country

SELECT * FROM Employees
WHERE Region IS NOT NULL
ORDER BY BirthDate DESC, Country

SELECT "AVG" = AVG(UnitPrice), "MIN" = MIN(UnitPrice), "MAX" = MAX(UnitPrice) FROM [Order Details]

SELECT "DISTINCT City" = COUNT(DISTINCT City) FROM Customers


