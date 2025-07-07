# Task 2
SELECT 
    d.dwarf_id,
    d.name,
    d.age,
    d.profession,
    JSON_OBJECT(
        'skill_ids', (
            SELECT JSON_ARRAYAGG(ds.skill_id)
            FROM dwarf_skills ds
            JOIN dwarves d ON ds.dwarf_id = d.dwarf_id
            JOIN skills s ON s.skill_id = d.skill_id
        ),
        'assignment_ids', (
            SELECT JSON_ARRAYAGG(da.assigned_id)
            FROM dwarf_assignments da
            JOIN dwarves d ON da.dwarf_id = d.dwarf_id
        ),
        'squad_ids', (
            SELECT JSON_ARRAYAGG(msq.squad_id)
            FROM military_squads msq
            JOIN squad_members sqm ON msq.squad_id = sqm.squad_id
            JOIN dwarves d ON sqm.dwarf_id = d.dwarf_id
        ),
        'equipment_ids', (
            SELECT JSON_ARRAYAGG(e.equipment_id)
            FROM equipment e
            JOIN dwarf_equipment de ON e.equipment_id = de.equipment_id
            JOIN dwarves d ON de.dwarf_id = d.dwarf_id
        )
    ) AS related_entities
FROM 
    dwarves d;


# Task 3
SELECT 
    w.workshop_id,
    w.name,
    w.type,
    w.quality,
    JSON_OBJECT(
        'craftsdwarf_ids', (
            SELECT JSON_ARRAYAGG(d.dwarf_id)
            FROM dwarves d
            JOIN workshop_craftsdwarves wc ON wc.dwarf_id = d.dwarf_id
            JOIN workshops w ON w.workshop_id = wc.workshop_id
        ),
        'project_ids', (
            SELECT JSON_ARRAYAGG(p.project_id)
            FROM project p
            JOIN workshops w ON w.workshop_id = p.workshop_id
        ),
        'input_material_ids', (
            SELECT JSON_ARRAYAGG(wm.material_id)
            FROM workshop_materials wm
            JOIN workshops w ON w.workshop_id = wm.workshop_id
        ),
        'output_product_ids', (
            SELECT JSON_ARRAYAGG(wp.product_id)
            FROM workshop_products wp
            JOIN workshops w ON w.workshop_id = wp.workshop_id
        )
    ) AS related_entities
FROM 
    workshops w;

SELECT 
    ms.squad_id,
    ms.name,
    ms.formation_type,
    ms.leader_id,
    JSON_OBJECT(
        'member_ids', (
            SELECT JSON_ARRAYAGG(sm.dwarf_id)
            FROM squad_members sm
            JOIN military_squads ms ON ms.squad_id = sm.squad_id
        ),
        'equipment_ids', (
            SELECT JSON_ARRAYAGG(se.equipment_id)
            FROM squad_equipment se
            JOIN military_squads ms ON ms.squad_id = se.squad_id
        ),
        'operation_ids', (
            SELECT JSON_ARRAYAGG(so.operation_ids)
            FROM squad_operations so
            JOIN military_squads ms ON ms.squad_id = so.squad_id
        ),
        'training_schedule_ids', (
            SELECT JSON_ARRAYAGG(st.schedule_id)
            FROM squad_training st
            JOIN military_squads ms ON ms.squad_id = st.squad_id
        )
        'battle_report_ids', (
            SELECT JSON_ARRAYAGG(sb.report_id)
            FROM squad_battles sb
            JOIN military_squads ms ON ms.squad_id = sb.squad_id
        )
    ) AS related_entities
FROM 
    military_squads ms;

