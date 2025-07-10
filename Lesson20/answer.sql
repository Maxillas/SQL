Рефлексия:
1. Название локации взял не из того поля
2. Не учел что discovered_sites должны быть в обратном порядке
3. Неверно указал условия для успешных экспедиций
4. Подход с глобальными json object оказался неверным, в эталонных решениях другой способ выдачи

# Task 
SELECT 
    JSON_OBJECT(
        'expedition_id', e.expedition_id,
        'destination', l.name,
        'status', e.status,
        'survival_rate', ROUND((COUNT(CASE WHEN m.survived = TRUE THEN 1 END) / COUNT(m.dwarf_id)) * 100, 2),
        'artifacts_value', COALESCE(SUM(a.value), 0),
        'discovered_sites', COUNT(s.site_id),
        'encounter_success_rate', ROUND(
            (COUNT(CASE WHEN c.outcome = 'Victory' THEN 1 END) / COUNT(c.creature_id)) * 100, 2
        ),
        'skill_improvement', ROUND(AVG(ds.level_after - ds.level_before), 0),
        'expedition_duration', DATEDIFF(e.return_date, e.departure_date),
        'overall_success_score', ROUND(
            (
                ((COUNT(CASE WHEN m.survived = TRUE THEN 1 END) / COUNT(m.dwarf_id)) * 0.2) +
                ((COUNT(CASE WHEN c.outcome = 'Victory' THEN 1 END) / COUNT(c.creature_id)) * 0.15) +
                (LOG(COALESCE(SUM(a.value), 1)) / 10) * 0.25 +
                (COUNT(s.site_id) / 10) * 0.1 +
                (ROUND(AVG(ds.level_after - ds.level_before), 0) / 20) * 0.1 +
                (DATEDIFF(e.return_date, e.departure_date) / 100) * -0.05
            ), 2
        ),
        'related_entities', JSON_OBJECT(
            'member_ids', JSON_ARRAYAGG(DISTINCT m.dwarf_id),
            'artifact_ids', JSON_ARRAYAGG(DISTINCT a.artifact_id),
            'site_ids', JSON_ARRAYAGG(DISTINCT s.site_id)
        )
    ) AS json_result
FROM EXPEDITIONS e
LEFT JOIN LOCATIONS l ON e.destination = l.location_id
LEFT JOIN EXPEDITION_MEMBERS m ON e.expedition_id = m.expedition_id
LEFT JOIN EXPEDITION_ARTIFACTS a ON e.expedition_id = a.expedition_id
LEFT JOIN EXPEDITION_SITES s ON e.expedition_id = s.expedition_id
LEFT JOIN EXPEDITION_CREATURES c ON e.expedition_id = c.expedition_id
LEFT JOIN DWARF_SKILLS ds ON m.dwarf_id = ds.dwarf_id
GROUP BY e.expedition_id, e.destination, e.status, e.departure_date, e.return_date;