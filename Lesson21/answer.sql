# До рефлексии
WITH 
workshop_production AS (
  SELECT 
    w.workshop_id,
    w.name AS workshop_name,
    w.type AS workshop_type,
    COUNT(DISTINCT wc.dwarf_id) AS num_craftsdwarves,
    SUM(wp.quantity) AS total_quantity_produced,
    SUM(wp.quantity * p.value) AS total_production_value,
    COUNT(DISTINCT DATE(wp.production_date)) AS days_active
  FROM 
    WORKSHOPS w
    LEFT JOIN WORKSHOP_CRAFTSDWARVES wc ON w.workshop_id = wc.workshop_id
    LEFT JOIN WORKSHOP_PRODUCTS wp ON w.workshop_id = wp.workshop_id
    LEFT JOIN PRODUCTS p ON wp.product_id = p.product_id
  GROUP BY 
    w.workshop_id, w.name, w.type
),

workshop_materials AS (
  SELECT
    w.workshop_id,
    SUM(wm.quantity) AS total_materials_used
  FROM
    WORKSHOPS w
    LEFT JOIN WORKSHOP_MATERIALS wm ON w.workshop_id = wm.workshop_id AND wm.is_input = TRUE
  GROUP BY
    w.workshop_id
),

craftsdwarf_skills AS (
  SELECT
    w.workshop_id,
    AVG(ds.level) AS average_craftsdwarf_skill,
    CORR(ds.level, p.quality) AS skill_quality_correlation
  FROM
    WORKSHOPS w
    JOIN WORKSHOP_CRAFTSDWARVES wc ON w.workshop_id = wc.workshop_id
    JOIN DWARF_SKILLS ds ON wc.dwarf_id = ds.dwarf_id
    JOIN PRODUCTS p ON p.created_by = wc.dwarf_id
  WHERE
    ds.skill_id IN (SELECT skill_id FROM SKILLS WHERE category = 'Crafting')
  GROUP BY
    w.workshop_id
),

workshop_entities AS (
  SELECT
    w.workshop_id,
    JSON_OBJECT(
      'craftsdwarf_ids', array_agg(DISTINCT wc.dwarf_id),
      'product_ids', array_agg(DISTINCT wp.product_id),
      'material_ids', array_agg(DISTINCT wm.material_id),
      'project_ids', array_agg(DISTINCT pr.project_id)
    ) AS related_entities
  FROM
    WORKSHOPS w
    LEFT JOIN WORKSHOP_CRAFTSDWARVES wc ON w.workshop_id = wc.workshop_id
    LEFT JOIN WORKSHOP_PRODUCTS wp ON w.workshop_id = wp.workshop_id
    LEFT JOIN WORKSHOP_MATERIALS wm ON w.workshop_id = wm.workshop_id
    LEFT JOIN PROJECTS pr ON w.workshop_id = pr.workshop_id
  GROUP BY
    w.workshop_id
)

SELECT
  wp.workshop_id,
  wp.workshop_name,
  wp.workshop_type,
  wp.num_craftsdwarves,
  wp.total_quantity_produced,
  wp.total_production_value,
  
  ROUND(wp.total_quantity_produced::numeric / NULLIF(wp.days_active, 0), 2) AS daily_production_rate,
  ROUND(wp.total_production_value::numeric / NULLIF(wm.total_materials_used, 0), 2) AS value_per_material_unit,
  ROUND(wp.days_active::numeric / (EXTRACT(EPOCH FROM (NOW() - MIN(wp.production_date)) / 86400) * 100, 2) AS workshop_utilization_percent,
  
  ROUND(wp.total_quantity_produced::numeric / NULLIF(wm.total_materials_used, 0), 2) AS material_conversion_ratio,
  
  cs.average_craftsdwarf_skill,
  cs.skill_quality_correlation,
  we.related_entities

FROM
  workshop_production wp
  JOIN workshop_materials wm ON wp.workshop_id = wm.workshop_id
  JOIN craftsdwarf_skills cs ON wp.workshop_id = cs.workshop_id
  JOIN workshop_entities we ON wp.workshop_id = we.workshop_id

ORDER BY
  wp.workshop_id;

Рефлексия:
Главная мысль - крайне тяжело даются такого рода запросы и БД в целом
Для лучшего результата пришлось рисовать отдельно таблицу и все связи между ними
Крайне удобно оказалось выделение в CTE, получается нечто похожее на ООП
с приципом единственной ответственности, что легче позволяет искать ошибки
и меньше путаться в результатах.

1. В эталонном решении более четкое разделение логики на CTE.
Для улучшения нужно разделить структуру на:
- базовую статистику мастерской
- расчеты по ремесленникам
- эффективность материалов
- качество продукции

2. Неверно рассчитываю дни активности

3. Не везде где нужно использовал NULLIF 

4. В эталонном решении спользуется JSON_OBJECT с вложенными подзапросами, что
более читаемо, необхоидмо изменить.

6. Неверная сортировка результатов 

Финальный запрос после рефлексии:

WITH 
workshop_activity AS (
    SELECT 
        w.workshop_id,
        w.name AS workshop_name,
        w.type AS workshop_type,
        COUNT(DISTINCT wc.dwarf_id) AS num_craftsdwarves,
        SUM(wp.quantity) AS total_quantity_produced,
        SUM(p.value * wp.quantity) AS total_production_value,
        COUNT(DISTINCT DATE(wp.production_date)) AS active_days,
        EXTRACT(DAY FROM (MAX(wp.production_date) - MIN(wc.assignment_date))) AS total_days_existed,
        MIN(wc.assignment_date) AS first_activity_date,
        MAX(wp.production_date) AS last_activity_date
    FROM 
        workshops w
    LEFT JOIN 
        workshop_craftsdwarves wc ON w.workshop_id = wc.workshop_id
    LEFT JOIN 
        workshop_products wp ON w.workshop_id = wp.workshop_id
    LEFT JOIN 
        products p ON wp.product_id = p.product_id
    GROUP BY 
        w.workshop_id, w.name, w.type
),

material_efficiency AS (
    SELECT 
        w.workshop_id,
        SUM(CASE WHEN wm.is_input THEN wm.quantity ELSE 0 END) AS materials_consumed,
        SUM(CASE WHEN NOT wm.is_input THEN wm.quantity ELSE 0 END) AS materials_produced,
        COUNT(DISTINCT CASE WHEN wm.is_input THEN wm.material_id END) AS unique_inputs,
        COUNT(DISTINCT CASE WHEN NOT wm.is_input THEN wm.material_id END) AS unique_outputs
    FROM 
        workshops w
    LEFT JOIN 
        workshop_materials wm ON w.workshop_id = wm.workshop_id
    GROUP BY 
        w.workshop_id
),

craftsdwarf_metrics AS (
    SELECT 
        wc.workshop_id,
        AVG(ds.level) AS avg_skill_level,
        CORR(ds.level, p.quality) AS skill_quality_corr,
        MAX(ds.level) AS max_skill_level,
        MIN(ds.level) AS min_skill_level
    FROM 
        workshop_craftsdwarves wc
    JOIN 
        dwarf_skills ds ON wc.dwarf_id = ds.dwarf_id
    JOIN 
        skills s ON ds.skill_id = s.skill_id
    LEFT JOIN 
        products p ON p.created_by = wc.dwarf_id
    WHERE 
        s.category = 'Crafting'
    GROUP BY 
        wc.workshop_id
)

SELECT 
    wa.workshop_id,
    wa.workshop_name,
    wa.workshop_type,
    wa.num_craftsdwarves,
    wa.total_quantity_produced,
    wa.total_production_value,
    
    ROUND(wa.total_quantity_produced::DECIMAL / NULLIF(wa.active_days, 0), 2) AS daily_production_rate,
    ROUND(wa.total_production_value::DECIMAL / NULLIF(me.materials_consumed, 0), 2) AS value_per_material_unit,
    ROUND((wa.active_days::DECIMAL / NULLIF(wa.total_days_existed, 0)) * 100, 2) AS workshop_utilization_percent,
    
    ROUND(me.materials_produced::DECIMAL / NULLIF(me.materials_consumed, 0), 2) AS material_conversion_ratio,
    ROUND(cm.avg_skill_level, 2) AS average_craftsdwarf_skill,
    cm.skill_quality_corr AS skill_quality_correlation,
    
    (
        SELECT JSON_OBJECT(
            'craftsdwarf_ids', array_agg(DISTINCT wc.dwarf_id),
            'product_ids', array_agg(DISTINCT wp.product_id),
            'material_ids', array_agg(DISTINCT wm.material_id),
            'project_ids', array_agg(DISTINCT p.project_id)
        )
        FROM 
            workshop_craftsdwarves wc
            LEFT JOIN workshop_products wp ON wc.workshop_id = wp.workshop_id
            LEFT JOIN workshop_materials wm ON wc.workshop_id = wm.workshop_id
            LEFT JOIN projects p ON wc.workshop_id = p.workshop_id
        WHERE 
            wc.workshop_id = wa.workshop_id
    ) AS related_entities
    
FROM
    workshop_activity wa
    JOIN material_efficiency me ON wa.workshop_id = me.workshop_id
    JOIN craftsdwarf_metrics cm ON wa.workshop_id = cm.workshop_id
    
ORDER BY
    (wa.total_production_value::DECIMAL / NULLIF(me.materials_consumed, 0)) * 
    (wa.active_days::DECIMAL / NULLIF(wa.total_days_existed, 0)) DESC;