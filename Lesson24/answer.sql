# До рефлексии
WITH 
attack_stats AS (
    SELECT
        COUNT(ca.attack_id) AS total_attacks,
        COUNT(DISTINCT ca.creature_id) AS unique_attackers,
        ROUND(100.0 * SUM(CASE WHEN ca.outcome = 'Defeated' THEN 1 ELSE 0 END) / COUNT(*), 2) AS defense_success_rate,
        AVG(ca.enemy_casualties) AS avg_enemy_casualties,
        AVG(ca.casualties) AS avg_dwarf_casualties,
        MIN(ca.date) AS first_attack_date,
        MAX(ca.date) AS last_attack_date
    FROM
        CREATURE_ATTACKS ca
    JOIN
        LOCATIONS l ON ca.location_id = l.location_id
    WHERE
        l.zone_id IN (SELECT zone_id FROM FORTRESS_RESOURCES WHERE fortress_id = :fortress_id)
),

active_threats AS (
    SELECT
        c.creature_id,
        c.type AS creature_type,
        c.threat_level,
        MAX(cs.date) AS last_sighting_date,
        MIN(ct.distance_to_fortress) AS territory_proximity,
        c.estimated_population AS estimated_numbers
    FROM
        CREATURES c
    JOIN
        CREATURE_SIGHTINGS cs ON c.creature_id = cs.creature_id
    LEFT JOIN
        CREATURE_TERRITORIES ct ON c.creature_id = ct.creature_id
    WHERE
        c.active = TRUE
        AND cs.date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY
        c.creature_id, c.type, c.threat_level, c.estimated_population
),

zone_vulnerability AS (
    SELECT
        l.zone_id,
        l.name AS zone_name,
        COUNT(ca.attack_id) AS attack_count,
        SUM(CASE WHEN ca.outcome = 'Breached' THEN 1 ELSE 0 END) AS breach_count,
        l.fortification_level,
        l.trap_density,
        l.wall_integrity,
        AVG(ca.military_response_time_minutes) AS avg_response_time,
        ARRAY_AGG(DISTINCT sm.squad_id) AS defending_squads
    FROM
        LOCATIONS l
    LEFT JOIN
        CREATURE_ATTACKS ca ON l.location_id = ca.location_id
    LEFT JOIN
        SQUAD_MEMBERS sm ON l.zone_id = sm.squad_id  -- Предполагаем связь между зонами и отрядами
    WHERE
        l.zone_id IN (SELECT zone_id FROM FORTRESS_RESOURCES WHERE fortress_id = :fortress_id)
    GROUP BY
        l.zone_id, l.name, l.fortification_level, l.trap_density, l.wall_integrity
),

defense_effectiveness AS (
    SELECT
        UNNEST(STRING_TO_ARRAY(ca.defense_structures_used, ',')) AS defense_type,
        COUNT(*) AS usage_count,
        ROUND(100.0 * SUM(CASE WHEN ca.outcome = 'Defeated' THEN 1 ELSE 0 END) / COUNT(*), 2) AS effectiveness_rate,
        AVG(ca.enemy_casualties) AS avg_enemy_casualties
    FROM
        CREATURE_ATTACKS ca
    WHERE
        ca.defense_structures_used IS NOT NULL
    GROUP BY
        defense_type
    HAVING
        COUNT(*) > 3
),

military_readiness AS (
    SELECT
        ms.squad_id,
        ms.name AS squad_name,
        COUNT(DISTINCT sm.dwarf_id) AS active_members,
        ROUND(AVG(ds.level), 1) AS avg_combat_skill,
        AVG(st.effectiveness) AS training_effectiveness,
        COUNT(DISTINCT sb.report_id) AS battles_fought
    FROM
        MILITARY_SQUADS ms
    JOIN
        SQUAD_MEMBERS sm ON ms.squad_id = sm.squad_id AND sm.exit_date IS NULL
    LEFT JOIN
        DWARF_SKILLS ds ON sm.dwarf_id = ds.dwarf_id AND ds.skill_id IN (
            SELECT skill_id FROM SKILLS WHERE category = 'Military'
        )
    LEFT JOIN
        SQUAD_TRAINING st ON ms.squad_id = st.squad_id
    LEFT JOIN
        SQUAD_BATTLES sb ON ms.squad_id = sb.squad_id
    WHERE
        ms.fortress_id = :fortress_id
    GROUP BY
        ms.squad_id, ms.name
),

security_evolution AS (
    SELECT
        EXTRACT(YEAR FROM ca.date) AS year,
        COUNT(*) AS total_attacks,
        SUM(ca.casualties) AS casualties,
        ROUND(100.0 * SUM(CASE WHEN ca.outcome = 'Defeated' THEN 1 ELSE 0 END) / COUNT(*), 2) AS defense_success_rate,
        LAG(COUNT(*)) OVER (ORDER BY EXTRACT(YEAR FROM ca.date)) AS prev_year_attacks,
        LAG(SUM(ca.casualties)) OVER (ORDER BY EXTRACT(YEAR FROM ca.date)) AS prev_year_casualties
    FROM
        CREATURE_ATTACKS ca
    JOIN
        LOCATIONS l ON ca.location_id = l.location_id
    WHERE
        l.zone_id IN (SELECT zone_id FROM FORTRESS_RESOURCES WHERE fortress_id = :fortress_id)
    GROUP BY
        EXTRACT(YEAR FROM ca.date)
)

SELECT
    as.total_attacks AS total_recorded_attacks,
    as.unique_attackers,
    as.defense_success_rate AS overall_defense_success_rate,
    JSON_BUILD_OBJECT(
        'threat_assessment', JSON_BUILD_OBJECT(
            'current_threat_level', CASE
                WHEN (SELECT MAX(threat_level) FROM active_threats) >= 4 THEN 'High'
                WHEN (SELECT MAX(threat_level) FROM active_threats) >= 2 THEN 'Moderate'
                ELSE 'Low'
            END,
            'active_threats', (
                SELECT JSON_AGG(JSON_BUILD_OBJECT(
                    'creature_type', at.creature_type,
                    'threat_level', at.threat_level,
                    'last_sighting_date', at.last_sighting_date,
                    'territory_proximity', at.territory_proximity,
                    'estimated_numbers', at.estimated_numbers,
                    'creature_ids', (
                        SELECT JSON_AGG(c.creature_id)
                        FROM CREATURES c
                        WHERE c.type = at.creature_type AND c.active = TRUE
                    )
                ))
                FROM active_threats at
                ORDER BY at.threat_level DESC, at.territory_proximity ASC
            )
        ),
        'vulnerability_analysis', (
            SELECT JSON_AGG(JSON_BUILD_OBJECT(
                'zone_id', zv.zone_id,
                'zone_name', zv.zone_name,
                'vulnerability_score', ROUND(
                    (zv.breach_count::FLOAT / NULLIF(zv.attack_count, 0)) * 
                    (1 - zv.fortification_level::FLOAT / 5) * 
                    (1 - zv.trap_density::FLOAT / 10), 2),
                'historical_breaches', zv.breach_count,
                'fortification_level', zv.fortification_level,
                'military_response_time', zv.avg_response_time,
                'defense_coverage', JSON_BUILD_OBJECT(
                    'structure_ids', (
                        SELECT ARRAY_AGG(l.location_id)
                        FROM LOCATIONS l
                        WHERE l.zone_id = zv.zone_id
                    ),
                    'squad_ids', zv.defending_squads
                )
            ))
            FROM zone_vulnerability zv
            ORDER BY zv.attack_count DESC
            LIMIT 5
        ),
        'defense_effectiveness', (
            SELECT JSON_AGG(JSON_BUILD_OBJECT(
                'defense_type', de.defense_type,
                'effectiveness_rate', de.effectiveness_rate,
                'avg_enemy_casualties', de.avg_enemy_casualties,
                'structure_ids', (
                    SELECT ARRAY_AGG(l.location_id)
                    FROM LOCATIONS l
                    WHERE l.name LIKE '%' || de.defense_type || '%'
                )
            ))
            FROM defense_effectiveness de
            ORDER BY de.effectiveness_rate DESC
        ),
        'military_readiness_assessment', (
            SELECT JSON_AGG(JSON_BUILD_OBJECT(
                'squad_id', mr.squad_id,
                'squad_name', mr.squad_name,
                'readiness_score', ROUND(
                    (mr.active_members::FLOAT / 10 * 0.3) +
                    (mr.avg_combat_skill / 20 * 0.4) +
                    (COALESCE(mr.training_effectiveness, 0) * 0.3), 2),
                'active_members', mr.active_members,
                'avg_combat_skill', mr.avg_combat_skill,
                'combat_effectiveness', mr.training_effectiveness,
                'response_coverage', (
                    SELECT JSON_AGG(JSON_BUILD_OBJECT(
                        'zone_id', l.zone_id,
                        'response_time', (
                            SELECT AVG(ca.military_response_time_minutes)
                            FROM CREATURE_ATTACKS ca
                            WHERE ca.location_id IN (
                                SELECT location_id FROM LOCATIONS WHERE zone_id = l.zone_id
                            )
                        )
                    ))
                    FROM LOCATIONS l
                    WHERE l.location_id IN (
                        SELECT location_id FROM SQUAD_OPERATIONS WHERE squad_id = mr.squad_id
                    )
                )
            ))
            FROM military_readiness mr
        ),
        'security_evolution', (
            SELECT JSON_AGG(JSON_BUILD_OBJECT(
                'year', se.year,
                'defense_success_rate', se.defense_success_rate,
                'total_attacks', se.total_attacks,
                'casualties', se.casualties,
                'year_over_year_improvement', CASE
                    WHEN se.prev_year_attacks IS NULL THEN NULL
                    ELSE ROUND(
                        (se.defense_success_rate - 
                        (100.0 * (se.total_attacks - se.prev_year_attacks) / 
                        NULLIF(se.casualties - se.prev_year_casualties, 0))), 2)
                    END
            ))
            FROM security_evolution se
            WHERE se.year IS NOT NULL
        )
    ) AS security_analysis
FROM
    attack_stats as;

# Рефлексия
1. В эталонном решении более детализированные метрики, в частности таблицы defense_structures, weather_records, moon_phases
2. Более сложные расчеты эффективности защиты и учтены сезонные факторы и фазы луны
3. В эталонном решении присутствует корелляция атак с погодными условиями, учет качества оборудования и тренировок, по-другому считаются уязвимости
4. В эталонном решении больше результатов, в частности рекомендации по улучшению безопасности, инвестиции в оборону и ожидаемое улучшение от рекомендаций

# После рефлексии
WITH 
creature_attack_history AS (
    SELECT 
        ca.attack_id,
        ca.creature_id,
        c.type AS creature_type,
        c.threat_level,
        ca.date,
        ca.location_id,
        ca.outcome,
        ca.casualties AS fortress_casualties,
        ca.enemy_casualties,
        ca.defense_structures_used,
        ca.military_response_time_minutes,
        EXTRACT(YEAR FROM ca.date) AS year,
        EXTRACT(MONTH FROM ca.date) AS month,
        EXTRACT(DOW FROM ca.date) AS day_of_week,
        l.zone_type,
        l.depth,
        l.fortification_level
    FROM 
        CREATURE_ATTACKS ca
    JOIN 
        CREATURES c ON ca.creature_id = c.creature_id
    JOIN 
        LOCATIONS l ON ca.location_id = l.location_id
    WHERE
        l.zone_id IN (SELECT zone_id FROM FORTRESS_RESOURCES WHERE fortress_id = :fortress_id)
),

attack_stats AS (
    SELECT
        COUNT(*) AS total_attacks,
        COUNT(DISTINCT creature_id) AS unique_attackers,
        ROUND(100.0 * SUM(CASE WHEN outcome = 'Defeated' THEN 1 ELSE 0 END) / COUNT(*), 2) AS defense_success_rate,
        SUM(fortress_casualties) AS total_casualties,
        SUM(enemy_casualties) AS total_enemy_casualties,
        MIN(date) AS first_attack_date,
        MAX(date) AS last_attack_date
    FROM
        creature_attack_history
),

active_threats AS (
    SELECT
        c.creature_id,
        c.type AS creature_type,
        c.threat_level,
        MAX(cs.date) AS last_sighting_date,
        MIN(ct.distance_to_fortress) AS territory_proximity,
        c.estimated_population AS estimated_numbers,
        COUNT(cs.sighting_id) AS sightings_last_year
    FROM
        CREATURES c
    JOIN
        CREATURE_SIGHTINGS cs ON c.creature_id = cs.creature_id
    LEFT JOIN
        CREATURE_TERRITORIES ct ON c.creature_id = ct.creature_id
    WHERE
        c.active = TRUE
        AND cs.date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY
        c.creature_id, c.type, c.threat_level, c.estimated_population
),

zone_vulnerability AS (
    SELECT
        l.zone_id,
        l.name AS zone_name,
        l.zone_type,
        l.depth,
        l.access_points,
        l.fortification_level,
        COUNT(DISTINCT cah.attack_id) AS total_attacks,
        SUM(CASE WHEN cah.outcome = 'Breached' THEN 1 ELSE 0 END) AS breaches,
        AVG(cah.fortress_casualties) AS avg_casualties_per_attack,
        COUNT(DISTINCT ds.structure_id) AS defense_structures,
        COUNT(DISTINCT sm.squad_id) AS patrolling_squads,
        AVG(cah.military_response_time_minutes) AS avg_response_time,
        l.wall_integrity,
        l.trap_density,
        l.choke_points,
        -- Расчет показателя уязвимости
        ROUND(
            (COALESCE(SUM(CASE WHEN cah.outcome = 'Breached' THEN 1 ELSE 0 END), 0)::FLOAT / 
             NULLIF(COUNT(DISTINCT cah.attack_id), 0) * 0.4) +
            ((5 - l.fortification_level) * 0.2) +
            (l.access_points * 0.1) +
            ((120 - COALESCE(AVG(cah.military_response_time_minutes), 120)) / 120 * 0.1) +
            ((3 - COALESCE(COUNT(DISTINCT ds.structure_id), 0)) * 0.1) +
            ((3 - COALESCE(COUNT(DISTINCT sm.squad_id), 0)) * 0.1)
        , 2) AS vulnerability_score
    FROM
        LOCATIONS l
    LEFT JOIN
        creature_attack_history cah ON l.location_id = cah.location_id
    LEFT JOIN
        DEFENSE_STRUCTURES ds ON l.location_id = ds.location_id
    LEFT JOIN
        SQUAD_MOVEMENT sm ON l.zone_id = sm.patrol_zone_id
    WHERE
        l.zone_id IN (SELECT zone_id FROM FORTRESS_RESOURCES WHERE fortress_id = :fortress_id)
    GROUP BY
        l.zone_id, l.name, l.zone_type, l.depth, l.access_points,
        l.fortification_level, l.wall_integrity, l.trap_density, l.choke_points
),

defense_effectiveness AS (
    SELECT
        ds.type AS defense_type,
        COUNT(DISTINCT cah.attack_id) AS attacks_defended,
        SUM(CASE WHEN cah.outcome = 'Defeated' THEN 1 ELSE 0 END) AS successful_defenses,
        ROUND(100.0 * SUM(CASE WHEN cah.outcome = 'Defeated' THEN 1 ELSE 0 END) / 
              NULLIF(COUNT(DISTINCT cah.attack_id), 0), 2) AS effectiveness_rate,
        AVG(cah.enemy_casualties) AS avg_enemy_casualties,
        COUNT(DISTINCT ds.structure_id) AS structure_count,
        AVG(ds.quality) AS avg_quality,
        AVG(ds.effectiveness_rating) AS avg_effectiveness,
        ARRAY_AGG(DISTINCT ds.structure_id) AS structure_ids
    FROM
        DEFENSE_STRUCTURES ds
    LEFT JOIN
        creature_attack_history cah ON ds.structure_id = ANY(STRING_TO_ARRAY(cah.defense_structures_used, ',')::int[])
    WHERE
        ds.location_id IN (SELECT location_id FROM LOCATIONS 
                          WHERE zone_id IN (SELECT zone_id FROM FORTRESS_RESOURCES 
                                          WHERE fortress_id = :fortress_id))
    GROUP BY
        ds.type
),

military_readiness AS (
    SELECT
        ms.squad_id,
        ms.name AS squad_name,
        ms.formation_type,
        COUNT(DISTINCT sm.dwarf_id) AS active_members,
        ROUND(AVG(ds.level), 1) AS avg_combat_skill,
        ROUND(AVG(eq.quality), 1) AS avg_equipment_quality,
        COUNT(DISTINCT sb.report_id) AS battles_participated,
        SUM(CASE WHEN cah.outcome IN ('Defeated', 'Partial Breach') THEN 1 ELSE 0 END) AS successful_defenses,
        AVG(st.effectiveness) AS training_effectiveness,
        EXTRACT(DAY FROM (CURRENT_DATE - MAX(st.date))) AS days_since_training,
        ARRAY_AGG(DISTINCT l.zone_id) AS covered_zones,
        ROUND(
            (COUNT(DISTINCT sm.dwarf_id)::FLOAT / 10 * 0.2) +
            (AVG(ds.level) / 20 * 0.3) +
            (AVG(eq.quality) / 5 * 0.2) +
            (COALESCE(SUM(CASE WHEN cah.outcome IN ('Defeated', 'Partial Breach') THEN 1 ELSE 0 END)::FLOAT / 
             NULLIF(COUNT(DISTINCT sb.report_id), 0), 0) * 0.2) +
            (CASE 
                WHEN EXTRACT(DAY FROM (CURRENT_DATE - MAX(st.date))) < 7 THEN 1.0
                WHEN EXTRACT(DAY FROM (CURRENT_DATE - MAX(st.date))) < 14 THEN 0.8
                WHEN EXTRACT(DAY FROM (CURRENT_DATE - MAX(st.date))) < 30 THEN 0.6
                ELSE 0.3
            END * 0.1)
        , 2) AS readiness_score
    FROM
        MILITARY_SQUADS ms
    JOIN
        SQUAD_MEMBERS sm ON ms.squad_id = sm.squad_id AND sm.exit_date IS NULL
    LEFT JOIN
        DWARF_SKILLS ds ON sm.dwarf_id = ds.dwarf_id AND ds.skill_id IN (
            SELECT skill_id FROM SKILLS WHERE category = 'Military')
    LEFT JOIN
        DWARF_EQUIPMENT de ON sm.dwarf_id = de.dwarf_id
    LEFT JOIN
        EQUIPMENT eq ON de.equipment_id = eq.equipment_id
    LEFT JOIN
        SQUAD_BATTLES sb ON ms.squad_id = sb.squad_id
    LEFT JOIN
        creature_attack_history cah ON sb.report_id = cah.attack_id
    LEFT JOIN
        SQUAD_TRAINING st ON ms.squad_id = st.squad_id
    LEFT JOIN
        SQUAD_MOVEMENT smv ON ms.squad_id = smv.squad_id
    LEFT JOIN
        LOCATIONS l ON smv.patrol_zone_id = l.zone_id
    WHERE
        ms.fortress_id = :fortress_id
    GROUP BY
        ms.squad_id, ms.name, ms.formation_type
),

security_evolution AS (
    SELECT
        cah.year,
        COUNT(DISTINCT cah.attack_id) AS total_attacks,
        ROUND(100.0 * SUM(CASE WHEN cah.outcome = 'Defeated' THEN 1 ELSE 0 END) / 
              NULLIF(COUNT(DISTINCT cah.attack_id), 0), 2) AS defense_success_rate,
        SUM(cah.fortress_casualties) AS casualties,
        COUNT(DISTINCT ds.structure_id) AS defense_structures_built,
        SUM(ds.quality * ds.effectiveness_rating) / 
              NULLIF(COUNT(DISTINCT ds.structure_id), 0) AS avg_defense_quality,
        SUM(p.resource_cost) AS defense_investment,
        LAG(ROUND(100.0 * SUM(CASE WHEN cah.outcome = 'Defeated' THEN 1 ELSE 0 END) / 
              NULLIF(COUNT(DISTINCT cah.attack_id), 0), 2)) 
              OVER (ORDER BY cah.year) AS prev_year_success
    FROM
        creature_attack_history cah
    LEFT JOIN
        DEFENSE_STRUCTURES ds ON EXTRACT(YEAR FROM ds.construction_date) = cah.year
    LEFT JOIN
        PROJECTS p ON EXTRACT(YEAR FROM p.completion_date) = cah.year AND p.type = 'Defense'
    GROUP BY
        cah.year
    ORDER BY
        cah.year
)

SELECT
    as.total_attacks AS total_recorded_attacks,
    as.unique_attackers,
    as.defense_success_rate AS overall_defense_success_rate,
    JSON_BUILD_OBJECT(
        'threat_assessment', JSON_BUILD_OBJECT(
            'current_threat_level', CASE
                WHEN (SELECT COUNT(*) FROM creature_attack_history 
                      WHERE date > CURRENT_DATE - INTERVAL '30 days') > 10 THEN 'Critical'
                WHEN (SELECT COUNT(*) FROM creature_attack_history 
                      WHERE date > CURRENT_DATE - INTERVAL '30 days') > 5 THEN 'High'
                WHEN (SELECT COUNT(*) FROM creature_attack_history 
                      WHERE date > CURRENT_DATE - INTERVAL '30 days') > 2 THEN 'Moderate'
                ELSE 'Low'
            END,
            'active_threats', (
                SELECT JSON_AGG(JSON_BUILD_OBJECT(
                    'creature_type', at.creature_type,
                    'threat_level', at.threat_level,
                    'last_sighting_date', at.last_sighting_date,
                    'territory_proximity', at.territory_proximity,
                    'estimated_numbers', at.estimated_numbers,
                    'creature_ids', (
                        SELECT JSON_AGG(c.creature_id)
                        FROM CREATURES c
                        WHERE c.type = at.creature_type AND c.active = TRUE
                    )
                ))
                FROM active_threats at
                ORDER BY at.threat_level DESC, at.territory_proximity ASC
            )
        ),
        'vulnerability_analysis', (
            SELECT JSON_AGG(JSON_BUILD_OBJECT(
                'zone_id', zv.zone_id,
                'zone_name', zv.zone_name,
                'vulnerability_score', zv.vulnerability_score,
                'historical_breaches', zv.breaches,
                'fortification_level', zv.fortification_level,
                'access_points', zv.access_points,
                'military_response_time', zv.avg_response_time,
                'defense_coverage', JSON_BUILD_OBJECT(
                    'structure_ids', (
                        SELECT JSON_AGG(ds.structure_id)
                        FROM DEFENSE_STRUCTURES ds
                        WHERE ds.location_id IN (
                            SELECT location_id FROM LOCATIONS WHERE zone_id = zv.zone_id)
                    ),
                    'squad_ids', (
                        SELECT JSON_AGG(DISTINCT sm.squad_id)
                        FROM SQUAD_MOVEMENT sm
                        WHERE sm.patrol_zone_id = zv.zone_id
                    )
                )
            ))
            FROM zone_vulnerability zv
            ORDER BY zv.vulnerability_score DESC
            LIMIT 5
        ),
        'defense_effectiveness', (
            SELECT JSON_AGG(JSON_BUILD_OBJECT(
                'defense_type', de.defense_type,
                'effectiveness_rate', de.effectiveness_rate,
                'avg_enemy_casualties', de.avg_enemy_casualties,
                'structure_count', de.structure_count,
                'avg_quality', de.avg_quality,
                'structure_ids', de.structure_ids
            ))
            FROM defense_effectiveness de
            ORDER BY de.effectiveness_rate DESC
        ),
        'military_readiness_assessment', (
            SELECT JSON_AGG(JSON_BUILD_OBJECT(
                'squad_id', mr.squad_id,
                'squad_name', mr.squad_name,
                'readiness_score', mr.readiness_score,
                'active_members', mr.active_members,
                'avg_combat_skill', mr.avg_combat_skill,
                'avg_equipment_quality', mr.avg_equipment_quality,
                'training_effectiveness', mr.training_effectiveness,
                'covered_zones', mr.covered_zones
            ))
            FROM military_readiness mr
            ORDER BY mr.readiness_score DESC
        ),
        'security_evolution', (
            SELECT JSON_AGG(JSON_BUILD_OBJECT(
                'year', se.year,
                'defense_success_rate', se.defense_success_rate,
                'total_attacks', se.total_attacks,
                'casualties', se.casualties,
                'defense_structures_built', se.defense_structures_built,
                'avg_defense_quality', se.avg_defense_quality,
                'defense_investment', se.defense_investment,
                'year_over_year_improvement', 
                    CASE WHEN se.prev_year_success IS NULL THEN NULL
                         ELSE se.defense_success_rate - se.prev_year_success END
            ))
            FROM security_evolution se
        )
    ) AS security_analysis
FROM
    attack_stats as;