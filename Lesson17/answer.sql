
/* 1. �������� ���������� � ���� ������, ������� ������ � �����-���� �����, ������ � ����������� �� �� �������.*/
SELECT * FROM Dwarves
WHERE squad_id IS NOT NULL
JOIN Squads ON Squads.squad_id = Dwarves.squad_id
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
/*5. �������� ������ ���� ������� � ���������� ������ � ������ ������. ����� �������� � ������ ������ ��� ������.*/
SELECT squad_id, COUNT(dwarf_id) FROM Squads
LEFT JOIN Dwarves ON Dwarves.squad_id = Squads.squad_id
GROUP BY squad_id

/*6. �������� ������ ��������� � ���������� ����������� ������������� ����� ("pending" � "in_progress") � ������ ���� ���������.*/
SELECT profession FROM Dwarves 
JOIN Tasks ON Dwarves.dwarf_id = Tasks.assigned_to
WHERE Tasks.status IN ('pending', 'in_progress') 

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