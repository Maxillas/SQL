
/*1. ������� ��� ������, � ������� ��� ������.*/

SELECT squad_id FROM Squads
WHERE leader_id IS NULL

/*2. �������� ������ ���� ������ ������ 150 ���, � ������� ��������� "Warrior".*/

SELECT dwarf_id FROM Dwarves 
WHERE age > 150 AND profession = "Warrior"

/*3. ������� ������, � ������� ���� ���� �� ���� ������� ���� "weapon".*/

SELECT dwarf_id FROM Dwarves
JOIN Items ON Dwarves.dwarf_id = Items.owner_id
GROUP BY dwarf_id

/*4. �������� ���������� ����� ��� ������� �����, ������������ �� �� �������.*/

SELECT COUNT(task_id) FROM Tasks
JOIN Dwarves ON Tasks.assigned_to = Dwarves.dwarf_id 
GROUP BY status

/*5. ������� ��� ������, ������� ���� ��������� ������ �� ������ � ������ "Guardians".*/

SELECT task_id FROM Tasks
JOIN (SELECT dwarf_id FROM Dwarves
	JOIN Squads ON Dwarves.squad_id = Squads.squad_id
	WHERE name = "Guardians"
	) AS d
ON Tasks.assigned_to = d.dwarf_id

/*6. �������� ���� ������ � �� ��������� �������������, ������ ��� ����������� ���������. */

SELECT d1.dwarf_id as D, d2.related_to AS R, R.relationships FROM Relationships R
JOIN Relationships d1 ON R.dwarf_id = d1.dwarf_id
JOIN Relationships d2 ON R.related_to = d2.dwarf_id

