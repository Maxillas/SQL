SELECT ContactType, COUNT(ContactType) FROM Contacts
GROUP BY ContactType

SELECT CategoryID, AVG(UnitPrice) AS AVG_UNIT_PRICE FROM Products 
GROUP BY CategoryID
ORDER BY AVG_UNIT_PRICE

/*Рефлексия: 
1. В первом задании не понял смысла слова "агрегация" и сделал просто группировку по полю contactType. Добавил Счетчик
2. Во втором задании не вывел категорию (CategoyID), это больше для наглядности запроса должно быть
Также не сделал сортировку по возрастанию*/