# До рефлексии
WITH 
squad_battle_stats AS (
    SELECT 
        s.squad_id,
        s.name AS squad_name,
        s.formation_type,
        d.name AS leader_name,
        COUNT(sb.report_id) AS total_battles,
        SUM(CASE WHEN sb.outcome = 'Victory' THEN 1 ELSE 0 END) AS victories,
        SUM(sb.casualties) AS total_casualties,
        SUM(sb.enemy_casualties) AS total_enemy_casualties,
        AVG(sb.military_response_time_minutes) AS avg_response_time
    FROM 
        military_squads s
    LEFT JOIN 
        squad_battles sb ON s.squad_id = sb.squad_id
    LEFT JOIN 
        dwarves d ON s.leader_id = d.dwarf_id
    GROUP BY 
        s.squad_id, s.name, s.formation_type, d.name
),

squad_member_stats AS (
    SELECT 
        sm.squad_id,
        COUNT(DISTINCT sm.dwarf_id) AS current_members,
        COUNT(DISTINCT CASE WHEN sm.exit_date IS NULL THEN sm.dwarf_id END) AS active_members,
        COUNT(DISTINCT sm.dwarf_id) AS total_members_ever,
        COUNT(DISTINCT CASE WHEN sm.exit_reason = 'KIA' THEN sm.dwarf_id END) AS killed_in_action
    FROM 
        squad_members sm
    GROUP BY 
        sm.squad_id
),

squad_equipment_stats AS (
    SELECT 
        se.squad_id,
        AVG(e.quality) AS avg_equipment_quality,
        COUNT(DISTINCT se.equipment_id) AS unique_equipment_count
    FROM 
        squad_equipment se
    JOIN 
        equipment e ON se.equipment_id = e.equipment_id
    GROUP BY 
        se.squad_id
),

squad_training_stats AS (
    SELECT 
        st.squad_id,
        COUNT(*) AS total_training_sessions,
        AVG(st.effectiveness) AS avg_training_effectiveness,
        AVG(st.duration_hours) AS avg_training_duration
    FROM 
        squad_training st
    GROUP BY 
        st.squad_id
),

squad_skill_progress AS (
    SELECT 
        sm.squad_id,
        AVG(ds.level) AS avg_combat_skill_level,
        AVG(ds.experience) AS avg_combat_skill_experience,
        COUNT(DISTINCT ds.dwarf_id) AS dwarves_with_combat_skills
    FROM 
        squad_members sm
    JOIN 
        dwarf_skills ds ON sm.dwarf_id = ds.dwarf_id
    JOIN 
        skills s ON ds.skill_id = s.skill_id
    WHERE 
        s.category = 'Combat' 
        AND sm.exit_date IS NULL
    GROUP BY 
        sm.squad_id
),

expedition_survival AS (
    SELECT 
        sm.squad_id,
        COUNT(DISTINCT em.dwarf_id) AS expedition_members,
        COUNT(DISTINCT CASE WHEN em.survived = TRUE THEN em.dwarf_id END) AS survived_expeditions
    FROM 
        squad_members sm
    JOIN 
        expedition_members em ON sm.dwarf_id = em.dwarf_id
    WHERE 
        sm.exit_date IS NULL
    GROUP BY 
        sm.squad_id
)

SELECT 
    sbs.squad_id,
    sbs.squad_name,
    sbs.formation_type,
    sbs.leader_name,
    sbs.total_battles,
    sbs.victories,
    ROUND((sbs.victories::DECIMAL / NULLIF(sbs.total_battles, 0)) * 100, 2) AS victory_percentage,
    ROUND((sms.killed_in_action::DECIMAL / NULLIF(sms.total_members_ever, 0)) * 100, 2) AS casualty_rate,
    ROUND((sbs.total_enemy_casualties::DECIMAL / NULLIF(sbs.total_casualties, 0)), 2) AS casualty_exchange_ratio,
    sms.active_members AS current_members,
    sms.total_members_ever,
    ROUND(((sms.total_members_ever - sms.killed_in_action)::DECIMAL / NULLIF(sms.total_members_ever, 0)) * 100, 2) AS retention_rate,
    ROUND(seq.avg_equipment_quality, 2) AS avg_equipment_quality,
    sts.total_training_sessions,
    ROUND(sts.avg_training_effectiveness, 2) AS avg_training_effectiveness,
    ROUND((sts.avg_training_effectiveness * (sbs.victories::DECIMAL / NULLIF(sbs.total_battles, 0))), 2) AS training_battle_correlation,
    ROUND(ssp.avg_combat_skill_level, 2) AS avg_combat_skill_improvement,
    ROUND(
        (COALESCE((sbs.victories::DECIMAL / NULLIF(sbs.total_battles, 0)), 0) * 0.3) +
        (COALESCE((1 - (sms.killed_in_action::DECIMAL / NULLIF(sms.total_members_ever, 0))), 0) * 0.2) +
        (COALESCE(seq.avg_equipment_quality / 5.0, 0) * 0.15) +
        (COALESCE(sts.avg_training_effectiveness, 0) * 0.15) +
        (COALESCE(ssp.avg_combat_skill_level / 10.0, 0) * 0.1) +
        (COALESCE((es.survived_expeditions::DECIMAL / NULLIF(es.expedition_members, 0)), 0) * 0.1),
    3
    ) AS overall_effectiveness_score,
    JSON_OBJECT(
        'member_ids', (SELECT array_agg(DISTINCT sm.dwarf_id) FROM squad_members sm WHERE sm.squad_id = sbs.squad_id AND sm.exit_date IS NULL),
        'equipment_ids', (SELECT array_agg(DISTINCT se.equipment_id) FROM squad_equipment se WHERE se.squad_id = sbs.squad_id),
        'battle_report_ids', (SELECT array_agg(DISTINCT sb.report_id) FROM squad_battles sb WHERE sb.squad_id = sbs.squad_id),
        'training_ids', (SELECT array_agg(DISTINCT st.schedule_id) FROM squad_training st WHERE st.squad_id = sbs.squad_id)
    ) AS related_entities
FROM 
    squad_battle_stats sbs
JOIN 
    squad_member_stats sms ON sbs.squad_id = sms.squad_id
JOIN 
    squad_equipment_stats seq ON sbs.squad_id = seq.squad_id
JOIN 
    squad_training_stats sts ON sbs.squad_id = sts.squad_id
JOIN 
    squad_skill_progress ssp ON sbs.squad_id = ssp.squad_id
LEFT JOIN 
    expedition_survival es ON sbs.squad_id = es.squad_id
ORDER BY 
    overall_effectiveness_score DESC;