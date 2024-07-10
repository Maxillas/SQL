
/*1. Найдите все отряды, у которых нет лидера.*/

SELECT squad_id FROM Squads
WHERE leader_id IS NULL

/*2. Получите список всех гномов старше 150 лет, у которых профессия "Warrior".*/

SELECT dwarf_id FROM Dwarves 
WHERE age > 150 AND profession = "Warrior"

/*3. Найдите гномов, у которых есть хотя бы один предмет типа "weapon".*/

SELECT dwarf_id FROM Dwarves
JOIN Items ON Dwarves.dwarf_id = Items.owner_id
GROUP BY dwarf_id

/*4. Получите количество задач для каждого гнома, сгруппировав их по статусу.*/

SELECT COUNT(task_id) FROM Tasks
JOIN Dwarves ON Tasks.assigned_to = Dwarves.dwarf_id 
GROUP BY status

/*5. Найдите все задачи, которые были назначены гномам из отряда с именем "Guardians".*/

SELECT task_id FROM Tasks
JOIN (SELECT dwarf_id FROM Dwarves
	JOIN Squads ON Dwarves.squad_id = Squads.squad_id
	WHERE name = "Guardians"
	) AS d
ON Tasks.assigned_to = d.dwarf_id

/*6. Выведите всех гномов и их ближайших родственников, указав тип родственных отношений. */

SELECT d1.dwarf_id as D, d2.related_to AS R, R.relationships FROM Relationships R
JOIN Relationships d1 ON R.dwarf_id = d1.dwarf_id
JOIN Relationships d2 ON R.related_to = d2.dwarf_id

