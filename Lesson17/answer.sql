
/* 1. Получить информацию о всех гномах, которые входят в какой-либо отряд, вместе с информацией об их отрядах.*/
SELECT * FROM Dwarves
WHERE squad_id IS NOT NULL
JOIN Squads ON Squads.squad_id = Dwarves.squad_id

/*Рефлексия: 
SELECT 
       D.name AS DwarfName,
       D.profession AS Profession,
       S.name AS SquadName,
       S.mission AS Mission
   FROM 
       Dwarves D
   JOIN 
       Squads S
   ON 
       D.squad_id = S.squad_id;

	Указывать WHERE было лишним, так как JOIN выполнит эту операцию, также забыл указать информацию о самих отрядах
*/
/*2. Найти всех гномов с профессией "miner", которые не состоят ни в одном отряде.*/
SELECT * FROM Dwarves
WHERE profession = 'miner' 
AND squad_id IS NULL
/*3. Получить все задачи с наивысшим приоритетом, которые находятся в статусе "pending".*/
SELECT * FROM Tasks
WHERE priority = SELECT(MAX(priority) FROM Tasks)
AND status = 'pending'
/*4. Для каждого гнома, который владеет хотя бы одним предметом, получить количество предметов, которыми он владеет.*/
SELECT COUNT(item_id) FROM Items
JOIN Dwarves ON Items.owner_id = Dwarves.dwarf_id
GROUP BY dwarf_id

/*Рефлексия: 
SELECT 
       D.name AS DwarfName,
       D.profession AS Profession,
       COUNT(I.item_id) AS ItemCount
   FROM 
       Dwarves D
   JOIN 
       Items I
   ON 
       D.dwarf_id = I.owner_id
   GROUP BY 
       D.dwarf_id, D.name, D.profession;

	1. Не вывел параметры гнома
	2. Соответственно не сгруппировал по ним
*/

/*5. Получить список всех отрядов и количество гномов в каждом отряде. Также включите в выдачу отряды без гномов.*/
SELECT squad_id, COUNT(dwarf_id) FROM Squads
LEFT JOIN Dwarves ON Dwarves.squad_id = Squads.squad_id
GROUP BY squad_id

/*6. Получить список профессий с наибольшим количеством незавершённых задач ("pending" и "in_progress") у гномов этих профессий.*/
SELECT profession FROM Dwarves 
JOIN Tasks ON Dwarves.dwarf_id = Tasks.assigned_to
WHERE Tasks.status IN ('pending', 'in_progress') 

/*Рефлексия: 
   SELECT 
       D.profession,
       COUNT(T.task_id) AS UnfinishedTasksCount
   FROM 
       Dwarves D
   JOIN 
       Tasks T
   ON 
       D.dwarf_id = T.assigned_to
   WHERE 
       T.status IN ('pending', 'in_progress')
   GROUP BY 
       D.profession
   ORDER BY 
       UnfinishedTasksCount DESC;

	1. Не сгруппировал по профессиям
	2. Не указал сортировку по убыванию
	3. И соответственно не посчитал количество профессий в статусе невыполненных
*/

/*7. Для каждого типа предметов узнать средний возраст гномов, владеющих этими предметами.*/
SELECT Items.type, AVG(Dwarves.age)
FROM Items
JOIN Dwarves ON Items.owner_id = Dwarves.dwarf_id
GROUP BY Items.type

/*8. Найти всех гномов старше среднего возраста (по всем гномам в базе), которые не владеют никакими предметами. */
SELECT dwarf_id FROM Dwarves
WHERE age > (
	SELECT AVG(age) FROM Dwarves
)
JOIN Items ON Dwarves.dwarf_id != Items.owner_id

/*Рефлексия: 
	SELECT 
       D.name,
       D.age,
       D.profession
   FROM 
       Dwarves D
   WHERE 
       D.age > (SELECT AVG(age) FROM Dwarves)
       AND D.dwarf_id NOT IN (SELECT owner_id FROM Items);

	Выборку из гномов, которые ничем не владеют, я сделал через JOIN против 
	СЕЛЕКТА в эталонном решении. Предполагаю, что выборка с помощью 
	СЕЛЕКТА будет работать быстрее, нежели JOIN. 
	Подумав, понял, что мое решение не будет выдавать никаких значений, т.к.
	делать JOIN по признаку неравенства некорректно
*/