
/* 1. �������� ���������� � ���� ������, ������� ������ � �����-���� �����, ������ � ����������� �� �� �������.*/
SELECT * FROM Dwarves
WHERE squad_id IS NOT NULL
JOIN Squads ON Squads.squad_id = Dwarves.squad_id

/*���������: 
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

	��������� WHERE ���� ������, ��� ��� JOIN �������� ��� ��������, ����� ����� ������� ���������� � ����� �������
*/
/*2. ����� ���� ������ � ���������� "miner", ������� �� ������� �� � ����� ������.*/
SELECT * FROM Dwarves
WHERE profession = 'miner' 
AND squad_id IS NULL
/*3. �������� ��� ������ � ��������� �����������, ������� ��������� � ������� "pending".*/
SELECT * FROM Tasks
WHERE priority = SELECT(MAX(priority) FROM Tasks)
AND status = 'pending'
/*4. ��� ������� �����, ������� ������� ���� �� ����� ���������, �������� ���������� ���������, �������� �� �������.*/
SELECT COUNT(item_id) FROM Items
JOIN Dwarves ON Items.owner_id = Dwarves.dwarf_id
GROUP BY dwarf_id

/*���������: 
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

	1. �� ����� ��������� �����
	2. �������������� �� ������������ �� ���
*/

/*5. �������� ������ ���� ������� � ���������� ������ � ������ ������. ����� �������� � ������ ������ ��� ������.*/
SELECT squad_id, COUNT(dwarf_id) FROM Squads
LEFT JOIN Dwarves ON Dwarves.squad_id = Squads.squad_id
GROUP BY squad_id

/*6. �������� ������ ��������� � ���������� ����������� ������������� ����� ("pending" � "in_progress") � ������ ���� ���������.*/
SELECT profession FROM Dwarves 
JOIN Tasks ON Dwarves.dwarf_id = Tasks.assigned_to
WHERE Tasks.status IN ('pending', 'in_progress') 

/*���������: 
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

	1. �� ������������ �� ����������
	2. �� ������ ���������� �� ��������
	3. � �������������� �� �������� ���������� ��������� � ������� �������������
*/

/*7. ��� ������� ���� ��������� ������ ������� ������� ������, ��������� ����� ����������.*/
SELECT Items.type, AVG(Dwarves.age)
FROM Items
JOIN Dwarves ON Items.owner_id = Dwarves.dwarf_id
GROUP BY Items.type

/*8. ����� ���� ������ ������ �������� �������� (�� ���� ������ � ����), ������� �� ������� �������� ����������. */
SELECT dwarf_id FROM Dwarves
WHERE age > (
	SELECT AVG(age) FROM Dwarves
)
JOIN Items ON Dwarves.dwarf_id != Items.owner_id

/*���������: 
	SELECT 
       D.name,
       D.age,
       D.profession
   FROM 
       Dwarves D
   WHERE 
       D.age > (SELECT AVG(age) FROM Dwarves)
       AND D.dwarf_id NOT IN (SELECT owner_id FROM Items);

	������� �� ������, ������� ����� �� �������, � ������ ����� JOIN ������ 
	������� � ��������� �������. �����������, ��� ������� � ������� 
	������� ����� �������� �������, ������ JOIN. 
	�������, �����, ��� ��� ������� �� ����� �������� ������� ��������, �.�.
	������ JOIN �� �������� ����������� �����������
*/