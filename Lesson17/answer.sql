
/* 1. Получить информацию о всех гномах, которые входят в какой-либо отряд, вместе с информацией об их отрядах.*/
SELECT * FROM Dwarves
WHERE squad_id IS NOT NULL
JOIN Squads ON Squads.squad_id = Dwarves.squad_id
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
/*5. Получить список всех отрядов и количество гномов в каждом отряде. Также включите в выдачу отряды без гномов.*/
SELECT squad_id, COUNT(dwarf_id) FROM Squads
LEFT JOIN Dwarves ON Dwarves.squad_id = Squads.squad_id
GROUP BY squad_id

/*6. Получить список профессий с наибольшим количеством незавершённых задач ("pending" и "in_progress") у гномов этих профессий.*/
SELECT profession FROM Dwarves 
JOIN Tasks ON Dwarves.dwarf_id = Tasks.assigned_to
WHERE Tasks.status IN ('pending', 'in_progress') 

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